// ML-DSA-65（FIPS 204）版本化密钥环，对齐 Spring/Quarkus 后端的
// config/security/pqc/MlDsaKeyRing 语义：按 kid 存储多把密钥，支持"新旧密钥双验"的在线轮换。
//
// 注意：Go 端使用 cloudflare/circl 的 ML-DSA-65 实现，密钥为 FIPS 204 原始打包字节
// （PublicKeySize / PrivateKeySize 固定长度），通过 base64 编码配置；
// 这与 Spring/BC 的 PKCS#8 PEM 格式不同，两端不直接互通密钥，
// 但各后端独立运行时具备对等的密钥环/轮换/kid 能力。
package auth

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/cloudflare/circl/sign/mldsa/mldsa65"
)

// ML-DSA-65 相关常量，对齐 Spring MlDsaKeyRing。
const (
	MlDsaAlgorithm = "ML-DSA-65"
	MlDsaJwtAlg    = "ML-DSA-65" // JWT header alg
	EphemeralKid   = "ml-dsa-ephemeral"
)

// MlDsaKeyEntry 密钥环中的一个版本条目。PrivateKey 可能为 nil（仅校验方）。
type MlDsaKeyEntry struct {
	Kid         string
	PrivateKey  *mldsa65.PrivateKey
	PublicKey   *mldsa65.PublicKey
	ActivatedAt time.Time
}

// MlDsaKeyRing 版本化 ML-DSA 密钥环。线程安全。
type MlDsaKeyRing struct {
	mu        sync.RWMutex
	entries   map[string]MlDsaKeyEntry
	activeKid string
}

// KeyConfig 单个版本化密钥的配置项（base64 编码的原始打包字节）。
type KeyConfig struct {
	Kid        string
	PublicKey  string // base64
	PrivateKey string // base64；校验方可空
}

// NewMlDsaKeyRing 从配置构建密钥环。
//   - keys 非空时优先使用版本化密钥环，activeKid 缺省则取最后一个含私钥的条目；
//   - 否则若 legacy 公/私钥均提供，使用单钥（kid="current"）；
//   - 否则生成临时密钥（重启后历史 token 失效）。
func NewMlDsaKeyRing(activeKid string, keys []KeyConfig, legacyPublicB64, legacyPrivateB64 string) (*MlDsaKeyRing, error) {
	ring := &MlDsaKeyRing{entries: map[string]MlDsaKeyEntry{}}

	if len(keys) > 0 {
		for _, k := range keys {
			if k.Kid == "" || k.PublicKey == "" {
				continue
			}
			pk, err := decodePublicKey(k.PublicKey)
			if err != nil {
				log.Printf("[WARN] Failed to load configured ML-DSA public key kid=%s: %v", k.Kid, err)
				continue
			}
			var sk *mldsa65.PrivateKey
			if k.PrivateKey != "" {
				if sk, err = decodePrivateKey(k.PrivateKey); err != nil {
					log.Printf("[WARN] Failed to load configured ML-DSA private key kid=%s: %v", k.Kid, err)
				}
			}
			ring.entries[k.Kid] = MlDsaKeyEntry{Kid: k.Kid, PrivateKey: sk, PublicKey: pk, ActivatedAt: time.Now()}
		}
		if activeKid != "" {
			if _, ok := ring.entries[activeKid]; ok {
				ring.activeKid = activeKid
			} else {
				ring.activeKid = ring.pickActiveKid()
			}
		} else {
			ring.activeKid = ring.pickActiveKid()
		}
		if ring.activeKid == "" {
			return nil, errors.New("ML-DSA key ring has no usable keys")
		}
		return ring, nil
	}

	if legacyPublicB64 != "" && legacyPrivateB64 != "" {
		pk, err := decodePublicKey(legacyPublicB64)
		if err != nil {
			return nil, fmt.Errorf("failed to decode legacy ML-DSA public key: %w", err)
		}
		sk, err := decodePrivateKey(legacyPrivateB64)
		if err != nil {
			return nil, fmt.Errorf("failed to decode legacy ML-DSA private key: %w", err)
		}
		ring.entries["current"] = MlDsaKeyEntry{Kid: "current", PrivateKey: sk, PublicKey: pk, ActivatedAt: time.Now()}
		ring.activeKid = "current"
		return ring, nil
	}

	// Ephemeral: tokens will NOT survive a restart.
	pk, sk, err := mldsa65.GenerateKey(rand.Reader)
	if err != nil {
		return nil, fmt.Errorf("failed to generate ephemeral ML-DSA keypair: %w", err)
	}
	ring.entries[EphemeralKid] = MlDsaKeyEntry{Kid: EphemeralKid, PrivateKey: sk, PublicKey: pk, ActivatedAt: time.Now()}
	ring.activeKid = EphemeralKid
	log.Println("[WARN] No ML-DSA keys configured; generated ephemeral keypair (kid=" + EphemeralKid +
		"). Tokens will NOT survive a restart.")
	return ring, nil
}

// ActiveKid 返回当前活跃签名密钥的 kid。
func (r *MlDsaKeyRing) ActiveKid() string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.activeKid
}

// ActivePrivateKey 返回活跃私钥；不存在则 nil。
func (r *MlDsaKeyRing) ActivePrivateKey() *mldsa65.PrivateKey {
	r.mu.RLock()
	defer r.mu.RUnlock()
	e, ok := r.entries[r.activeKid]
	if !ok {
		return nil
	}
	return e.PrivateKey
}

// ActivePublicKey 返回活跃公钥；不存在则 nil。
func (r *MlDsaKeyRing) ActivePublicKey() *mldsa65.PublicKey {
	r.mu.RLock()
	defer r.mu.RUnlock()
	e, ok := r.entries[r.activeKid]
	if !ok {
		return nil
	}
	return e.PublicKey
}

// PublicKeyFor 按 kid 选择公钥。kid 为空或未知时回退到活跃公钥（对齐 Spring 语义）。
func (r *MlDsaKeyRing) PublicKeyFor(kid string) (*mldsa65.PublicKey, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if kid == "" {
		if e, ok := r.entries[r.activeKid]; ok {
			return e.PublicKey, nil
		}
		return nil, errors.New("no active ML-DSA verification key")
	}
	e, ok := r.entries[kid]
	if !ok {
		// 未知 kid 回退到活跃公钥，兼容轮换后旧 token 的边界场景
		if ae, ok := r.entries[r.activeKid]; ok {
			return ae.PublicKey, nil
		}
		return nil, fmt.Errorf("no verification key for ML-DSA kid=%s", kid)
	}
	return e.PublicKey, nil
}

// Activate 注入新密钥并切换为活跃签名密钥。旧密钥保留在环中继续供校验。
func (r *MlDsaKeyRing) Activate(kid string, sk *mldsa65.PrivateKey, pk *mldsa65.PublicKey) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.entries[kid] = MlDsaKeyEntry{Kid: kid, PrivateKey: sk, PublicKey: pk, ActivatedAt: time.Now()}
	r.activeKid = kid
	log.Printf("[INFO] ML-DSA active signing key switched to kid=%s, ring size=%d", kid, len(r.entries))
}

// RetireOlderThan 清理激活时间早于 retention 的非活跃旧密钥（双验窗口结束后的清理）。
func (r *MlDsaKeyRing) RetireOlderThan(retention time.Duration) {
	r.mu.Lock()
	defer r.mu.Unlock()
	cutoff := time.Now().Add(-retention)
	removed := 0
	for kid, e := range r.entries {
		if kid == r.activeKid {
			continue
		}
		if e.ActivatedAt.Before(cutoff) {
			delete(r.entries, kid)
			removed++
		}
	}
	if removed > 0 {
		log.Printf("[INFO] Retired %d expired ML-DSA verification key(s); active kid=%s", removed, r.activeKid)
	}
}

// Size 返回环中密钥数量。
func (r *MlDsaKeyRing) Size() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.entries)
}

// Rotate 生成新 ML-DSA-65 密钥对，以时间戳 kid 注入并切换为活跃签名密钥，
// 然后清理超过 retention 的旧密钥。返回新 kid 与需要分发给校验方的新公钥（base64）。
func (r *MlDsaKeyRing) Rotate(retention time.Duration) (kid string, publicKeyB64 string, err error) {
	pk, sk, err := mldsa65.GenerateKey(rand.Reader)
	if err != nil {
		return "", "", fmt.Errorf("failed to generate ML-DSA keypair: %w", err)
	}
	// 毫秒精度，避免同秒内多次轮换（定时 + 手动触发，或多副本同窗口）生成相同 kid
	// 并互相覆盖，导致前一次窗口内签发的 token 解析到错误公钥而验签失败。
	kid = "ml-dsa-" + time.Now().UTC().Format("20060102-150405.000")
	r.Activate(kid, sk, pk)
	r.RetireOlderThan(retention)
	publicKeyB64 = base64.StdEncoding.EncodeToString(pk.Bytes())
	log.Printf("[INFO] ML-DSA key rotated to kid=%s (ring size=%d). Distribute the new public key to verifiers.", kid, r.Size())
	return kid, publicKeyB64, nil
}

func (r *MlDsaKeyRing) pickActiveKid() string {
	withPrivate := ""
	first := ""
	for _, e := range r.entries {
		if first == "" {
			first = e.Kid
		}
		if e.PrivateKey != nil {
			withPrivate = e.Kid
		}
	}
	if withPrivate != "" {
		return withPrivate
	}
	return first
}

func decodePublicKey(b64 string) (*mldsa65.PublicKey, error) {
	raw, err := base64.StdEncoding.DecodeString(b64)
	if err != nil {
		return nil, fmt.Errorf("base64 decode public key: %w", err)
	}
	pk := &mldsa65.PublicKey{}
	if err := pk.UnmarshalBinary(raw); err != nil {
		return nil, fmt.Errorf("unmarshal public key: %w", err)
	}
	return pk, nil
}

func decodePrivateKey(b64 string) (*mldsa65.PrivateKey, error) {
	raw, err := base64.StdEncoding.DecodeString(b64)
	if err != nil {
		return nil, fmt.Errorf("base64 decode private key: %w", err)
	}
	sk := &mldsa65.PrivateKey{}
	if err := sk.UnmarshalBinary(raw); err != nil {
		return nil, fmt.Errorf("unmarshal private key: %w", err)
	}
	return sk, nil
}
