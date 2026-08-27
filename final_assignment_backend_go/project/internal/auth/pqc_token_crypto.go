// Package auth 提供 ML-KEM-768（FIPS 203）信封加密，用于 refresh token 静态加密，
// 对齐 Spring/Quarkus 的 PqcTokenCrypto 语义。
//
// 存储格式（base64）：[4 字节大端 kemCt 长度][kemCt][12 字节 nonce][AES-256-GCM 密文+tag]。
// 每次 encrypt 用新的随机 AES key，该 key 由 ML-KEM 公钥封装；只有持有 ML-KEM 私钥的服务端能解封。
//
// 注意：Go 端用 cloudflare/circl 的 mlkem768 实现，密钥为 FIPS 203 原始打包字节（固定长度），
// 通过 base64 编码配置。这与 Spring/BC 的 PKCS#8 PEM 格式不同，两端不直接互通密钥，
// 但 refresh token 的加解密由各自后端独立完成，对等的加密能力成立。
package auth

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"encoding/binary"
	"errors"
	"fmt"
	"log"

	"github.com/cloudflare/circl/kem"
	"github.com/cloudflare/circl/kem/mlkem/mlkem768"
)

// PqcTokenCrypto 用 ML-KEM-768 信封对 refresh token 做静态加密。
type PqcTokenCrypto struct {
	scheme       kem.Scheme
	publicKey    kem.PublicKey
	privateKey   kem.PrivateKey
}

// NewPqcTokenCrypto 构造 PqcTokenCrypto。publicKeyB64/privateKeyB64 为 base64 编码的打包字节；
// 两者为空时生成临时密钥对（重启后历史 refresh token 失效）。
func NewPqcTokenCrypto(publicKeyB64, privateKeyB64 string) (*PqcTokenCrypto, error) {
	scheme := mlkem768.Scheme()
	c := &PqcTokenCrypto{scheme: scheme}

	if publicKeyB64 != "" && privateKeyB64 != "" {
		pkBytes, err := base64.StdEncoding.DecodeString(publicKeyB64)
		if err != nil {
			return nil, fmt.Errorf("decode ml-kem public key: %w", err)
		}
		pk, err := scheme.UnmarshalBinaryPublicKey(pkBytes)
		if err != nil {
			return nil, fmt.Errorf("unmarshal ml-kem public key: %w", err)
		}
		skBytes, err := base64.StdEncoding.DecodeString(privateKeyB64)
		if err != nil {
			return nil, fmt.Errorf("decode ml-kem private key: %w", err)
		}
		sk, err := scheme.UnmarshalBinaryPrivateKey(skBytes)
		if err != nil {
			return nil, fmt.Errorf("unmarshal ml-kem private key: %w", err)
		}
		c.publicKey = pk
		c.privateKey = sk
	} else {
		pk, sk, err := scheme.GenerateKeyPair()
		if err != nil {
			return nil, fmt.Errorf("generate ephemeral ml-kem keypair: %w", err)
		}
		c.publicKey = pk
		c.privateKey = sk
		log.Println("[WARN] No ML-KEM keys configured; generated ephemeral keypair. Refresh tokens will NOT survive a restart.")
	}
	return c, nil
}

// Encrypt 用 ML-KEM-768 信封加密明文，返回 base64 编码的 blob。
func (c *PqcTokenCrypto) Encrypt(plaintext string) (string, error) {
	ct, sharedKey, err := c.scheme.Encapsulate(c.publicKey)
	if err != nil {
		return "", fmt.Errorf("ml-kem encapsulate: %w", err)
	}
	if len(sharedKey) != mlkem768.SharedKeySize {
		return "", fmt.Errorf("unexpected ml-kem shared key length: %d", len(sharedKey))
	}

	nonce := make([]byte, 12)
	if _, err := rand.Read(nonce); err != nil {
		return "", fmt.Errorf("ml-kem nonce: %w", err)
	}

	block, err := aes.NewCipher(sharedKey)
	if err != nil {
		return "", fmt.Errorf("aes new cipher: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("aes gcm: %w", err)
	}
	gcmCt := gcm.Seal(nil, nonce, []byte(plaintext), nil)

	blob := make([]byte, 4+len(ct)+12+len(gcmCt))
	binary.BigEndian.PutUint32(blob[:4], uint32(len(ct)))
	copy(blob[4:4+len(ct)], ct)
	copy(blob[4+len(ct):4+len(ct)+12], nonce)
	copy(blob[4+len(ct)+12:], gcmCt)
	return base64.StdEncoding.EncodeToString(blob), nil
}

// Decrypt 解密 base64 编码的 blob，返回明文。
func (c *PqcTokenCrypto) Decrypt(blob string) (string, error) {
	data, err := base64.StdEncoding.DecodeString(blob)
	if err != nil {
		return "", fmt.Errorf("ml-kem base64 decode: %w", err)
	}
	if len(data) < 4 {
		return "", errors.New("ml-kem blob too short")
	}
	ctLen := binary.BigEndian.Uint32(data[:4])
	if int(ctLen) > len(data)-4-12 {
		return "", errors.New("ml-kem blob truncated")
	}
	ct := data[4 : 4+ctLen]
	nonce := data[4+ctLen : 4+ctLen+12]
	gcmCt := data[4+ctLen+12:]

	sharedKey, err := c.scheme.Decapsulate(c.privateKey, ct)
	if err != nil {
		return "", fmt.Errorf("ml-kem decapsulate: %w", err)
	}
	block, err := aes.NewCipher(sharedKey)
	if err != nil {
		return "", fmt.Errorf("aes new cipher: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("aes gcm: %w", err)
	}
	plain, err := gcm.Open(nil, nonce, gcmCt, nil)
	if err != nil {
		return "", fmt.Errorf("aes-gcm decrypt: %w", err)
	}
	return string(plain), nil
}

// ConstantTimeEquals 常量时间字符串比较。
func (c *PqcTokenCrypto) ConstantTimeEquals(a, b string) bool {
	if len(a) != len(b) {
		return false
	}
	var diff byte
	for i := 0; i < len(a); i++ {
		diff |= a[i] ^ b[i]
	}
	return diff == 0
}
