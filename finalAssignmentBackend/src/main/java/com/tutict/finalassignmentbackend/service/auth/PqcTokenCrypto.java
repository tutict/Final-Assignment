package com.tutict.finalassignmentbackend.service.auth;

import com.tutict.finalassignmentbackend.config.security.pqc.PqcProviderInitializer;
import jakarta.annotation.PostConstruct;
import java.io.StringReader;
import java.nio.ByteBuffer;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.KEM;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import org.bouncycastle.asn1.pkcs.PrivateKeyInfo;
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo;
import org.bouncycastle.cert.X509CertificateHolder;
import org.bouncycastle.openssl.PEMParser;
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * 用 ML-KEM-768（FIPS 203）封装的 AES-256-GCM 信封对 refresh token 做静态加密。
 *
 * <p>存储格式（base64）：[4 字节大端 kemCt 长度][kemCt][12 字节 nonce][GCM 密文+tag]。
 * 每次 encrypt 用新的随机 AES key，该 key 由 ML-KEM 公钥封装；只有持有 ML-KEM 私钥的服务端能解封。
 * 这构成"refresh token at rest 的后量子加密"演示。
 */
@Component
public class PqcTokenCrypto {

    private static final String BC = BouncyCastleProvider.PROVIDER_NAME;
    private static final String ML_KEM_KPG_ALGORITHM = "ML-KEM-768"; // KeyPairGenerator 用带变体的名
    private static final String ML_KEM_ALGORITHM = "ML-KEM";          // javax.crypto.KEM 用通用名，变体由密钥决定
    private static final String AES_GCM = "AES/GCM/NoPadding";
    private static final int GCM_TAG_BITS = 128;
    private static final int NONCE_BYTES = 12;
    private static final int KEM_SECRET_BYTES = 32; // ML-KEM-768 共享密钥固定 32 字节 -> AES-256

    private final SecureRandom random = new SecureRandom();

    @Value("${jwt.ml-kem.private-key:}")
    private String privateKeyPem;

    @Value("${jwt.ml-kem.public-key:}")
    private String publicKeyPem;

    private PrivateKey kemPrivateKey;
    private PublicKey kemPublicKey;
    private KEM kem;

    @PostConstruct
    public void init() {
        PqcProviderInitializer.ensureBouncyCastle();
        try {
            if (isPresent(privateKeyPem) && isPresent(publicKeyPem)) {
                this.kemPrivateKey = loadPrivateKey(privateKeyPem);
                this.kemPublicKey = loadPublicKey(publicKeyPem);
            } else {
                java.security.KeyPairGenerator kpg =
                        java.security.KeyPairGenerator.getInstance(ML_KEM_KPG_ALGORITHM, BC);
                java.security.KeyPair kp = kpg.generateKeyPair();
                this.kemPrivateKey = kp.getPrivate();
                this.kemPublicKey = kp.getPublic();
                java.util.logging.Logger.getLogger(getClass().getName())
                        .warning("No ML-KEM keys configured (jwt.ml-kem.private-key/public-key); "
                                + "generated ephemeral keypair. Refresh tokens will NOT survive a restart.");
            }
            this.kem = KEM.getInstance(ML_KEM_ALGORITHM, BC);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to initialize ML-KEM crypto", ex);
        }
    }

    public String encrypt(String plaintext) {
        try {
            KEM.Encapsulator encapsulator = kem.newEncapsulator(kemPublicKey);
            KEM.Encapsulated enc = encapsulator.encapsulate();
            byte[] kemCt = enc.encapsulation();
            SecretKey secret = enc.key();
            byte[] aesKeyBytes = secret.getEncoded();
            if (aesKeyBytes == null || aesKeyBytes.length != KEM_SECRET_BYTES) {
                throw new IllegalStateException("Unexpected ML-KEM secret length: "
                        + (aesKeyBytes == null ? "null" : aesKeyBytes.length));
            }
            SecretKeySpec aesKey = new SecretKeySpec(aesKeyBytes, "AES");

            byte[] nonce = new byte[NONCE_BYTES];
            random.nextBytes(nonce);
            Cipher cipher = Cipher.getInstance(AES_GCM);
            cipher.init(Cipher.ENCRYPT_MODE, aesKey, new GCMParameterSpec(GCM_TAG_BITS, nonce));
            byte[] gcmCt = cipher.doFinal(plaintext.getBytes(java.nio.charset.StandardCharsets.UTF_8));

            byte[] blob = ByteBuffer.allocate(4 + kemCt.length + NONCE_BYTES + gcmCt.length)
                    .putInt(kemCt.length)
                    .put(kemCt)
                    .put(nonce)
                    .put(gcmCt)
                    .array();
            return Base64.getEncoder().encodeToString(blob);
        } catch (Exception ex) {
            throw new IllegalStateException("ML-KEM encrypt failed", ex);
        }
    }

    public String decrypt(String blob) {
        try {
            byte[] data = Base64.getDecoder().decode(blob);
            ByteBuffer buf = ByteBuffer.wrap(data);
            int kemCtLen = buf.getInt();
            byte[] kemCt = new byte[kemCtLen];
            buf.get(kemCt);
            byte[] nonce = new byte[NONCE_BYTES];
            buf.get(nonce);
            byte[] gcmCt = new byte[buf.remaining()];
            buf.get(gcmCt);

            KEM.Decapsulator decapsulator = kem.newDecapsulator(kemPrivateKey);
            SecretKey secret = decapsulator.decapsulate(kemCt);
            SecretKeySpec aesKey = new SecretKeySpec(secret.getEncoded(), "AES");

            Cipher cipher = Cipher.getInstance(AES_GCM);
            cipher.init(Cipher.DECRYPT_MODE, aesKey, new GCMParameterSpec(GCM_TAG_BITS, nonce));
            byte[] plain = cipher.doFinal(gcmCt);
            return new String(plain, java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception ex) {
            throw new IllegalStateException("ML-KEM decrypt failed", ex);
        }
    }

    public boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null) {
            return a == null && b == null;
        }
        byte[] ba = a.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        byte[] bb = b.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        if (ba.length != bb.length) {
            return false;
        }
        int diff = 0;
        for (int i = 0; i < ba.length; i++) {
            diff |= ba[i] ^ bb[i];
        }
        return diff == 0;
    }

    private PrivateKey loadPrivateKey(String pem) throws Exception {
        try (PEMParser parser = new PEMParser(new StringReader(pem))) {
            Object obj = parser.readObject();
            if (obj instanceof PrivateKeyInfo pki) {
                return new JcaPEMKeyConverter().setProvider(BC).getPrivateKey(pki);
            }
            throw new IllegalArgumentException("PEM is not a PKCS#8 private key: " + obj);
        }
    }

    private PublicKey loadPublicKey(String pem) throws Exception {
        try (PEMParser parser = new PEMParser(new StringReader(pem))) {
            Object obj = parser.readObject();
            JcaPEMKeyConverter conv = new JcaPEMKeyConverter().setProvider(BC);
            if (obj instanceof SubjectPublicKeyInfo spki) {
                return conv.getPublicKey(spki);
            }
            if (obj instanceof X509CertificateHolder cert) {
                return conv.getPublicKey(cert.getSubjectPublicKeyInfo());
            }
            throw new IllegalArgumentException("PEM is not a public key: " + obj);
        }
    }

    private static boolean isPresent(String s) {
        return s != null && !s.isBlank();
    }
}
