package auth

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/cloudflare/circl/sign/mldsa/mldsa65"
	"github.com/golang-jwt/jwt/v5"
)

// ParseMLDSAToken 解析并校验一个 ML-DSA-65 JWT。
// signingInput = base64url(header) "." base64url(payload) "." base64url(signature)，
// 签名输入为 header.payload 的 ASCII 字节（与 Spring/Quarkus 端手写 JWT 一致）。
func ParseMLDSAToken(tokenString string, ring *MlDsaKeyRing) (jwt.MapClaims, error) {
	parts := strings.Split(tokenString, ".")
	if len(parts) != 3 {
		return nil, errors.New("ML-DSA token must have 3 parts")
	}

	headerBytes, err := base64URLDecode(parts[0])
	if err != nil {
		return nil, fmt.Errorf("decode header: %w", err)
	}
	var header map[string]any
	if err := json.Unmarshal(headerBytes, &header); err != nil {
		return nil, fmt.Errorf("parse header: %w", err)
	}
	alg, _ := header["alg"].(string)
	if alg != MlDsaJwtAlg {
		return nil, fmt.Errorf("invalid ML-DSA token algorithm: expected %s but got %s", MlDsaJwtAlg, alg)
	}
	kid, _ := header["kid"].(string)

	pk, err := ring.PublicKeyFor(kid)
	if err != nil {
		return nil, fmt.Errorf("verification key: %w", err)
	}

	signingInput := parts[0] + "." + parts[1]
	signature, err := base64URLDecode(parts[2])
	if err != nil {
		return nil, fmt.Errorf("decode signature: %w", err)
	}
	if !mldsa65.Verify(pk, []byte(signingInput), nil, signature) {
		return nil, errors.New("invalid ML-DSA signature")
	}

	payloadBytes, err := base64URLDecode(parts[1])
	if err != nil {
		return nil, fmt.Errorf("decode payload: %w", err)
	}
	var claims jwt.MapClaims
	if err := json.Unmarshal(payloadBytes, &claims); err != nil {
		return nil, fmt.Errorf("parse payload: %w", err)
	}

	// 校验过期时间
	exp, ok := claims["exp"]
	if !ok {
		return nil, errors.New("ML-DSA token missing exp claim")
	}
	expF, ok := toFloat64(exp)
	if !ok {
		return nil, errors.New("ML-DSA token exp claim is not a number")
	}
	now := nowUnix()
	if float64(now) > expF {
		return nil, errors.New("ML-DSA token has expired")
	}

	// 校验 sub
	sub, _ := claims["sub"].(string)
	if strings.TrimSpace(sub) == "" {
		return nil, errors.New("ML-DSA token missing or empty sub claim")
	}

	// 校验 iat（不能显著在未来）
	if iat, ok := claims["iat"]; ok {
		if iatF, ok := toFloat64(iat); ok && iatF > float64(now)+300 {
			return nil, errors.New("ML-DSA token has iat in the future")
		}
	}

	return claims, nil
}

// BuildMLDSAToken 用活跃私钥手写签发一个 ML-DSA-65 JWT。
func BuildMLDSAToken(claims jwt.MapClaims, ring *MlDsaKeyRing) (string, error) {
	sk := ring.ActivePrivateKey()
	if sk == nil {
		return "", errors.New("ML-DSA build: no active private key available")
	}
	header := map[string]any{
		"alg": MlDsaJwtAlg,
		"typ": "JWT",
		"kid": ring.ActiveKid(),
	}
	headerJSON, err := json.Marshal(header)
	if err != nil {
		return "", fmt.Errorf("marshal header: %w", err)
	}
	payloadJSON, err := json.Marshal(claims)
	if err != nil {
		return "", fmt.Errorf("marshal payload: %w", err)
	}

	signingInput := base64URLEncode(headerJSON) + "." + base64URLEncode(payloadJSON)
	var sig [mldsa65.SignatureSize]byte
	if err := mldsa65.SignTo(sk, []byte(signingInput), nil, false, sig[:]); err != nil {
		return "", fmt.Errorf("ML-DSA sign: %w", err)
	}
	return signingInput + "." + base64URLEncode(sig[:]), nil
}

// base64URLDecode 解码 base64url（自动补齐 padding）。
func base64URLDecode(s string) ([]byte, error) {
	if pad := len(s) % 4; pad != 0 {
		s += strings.Repeat("=", 4-pad)
	}
	return base64.URLEncoding.DecodeString(s)
}

// base64URLEncode 无填充 base64url 编码。
func base64URLEncode(b []byte) string {
	return base64.URLEncoding.WithPadding(base64.NoPadding).EncodeToString(b)
}
