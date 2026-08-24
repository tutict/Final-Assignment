package com.tutict.finalassignmentbackend.config.security.pqc;

import org.bouncycastle.asn1.pkcs.PrivateKeyInfo;
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo;
import org.bouncycastle.cert.X509CertificateHolder;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.openssl.PEMParser;
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter;

import java.io.StringReader;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 版本化 ML-DSA 密钥环（与 cloud 端一致）：按 {@code kid} 存储多把密钥，支持"新旧密钥双验"的在线轮换。
 *
 * <ul>
 *   <li>签名方使用 {@link #activeEntry()}（当前活跃密钥）签名，并在 JWT header 写入 kid；</li>
 *   <li>校验方通过 {@link #publicKeyFor(String)} 按 kid 选择公钥；token 无 kid 或 kid 未知时
 *       回退到 {@link #activePublicKey()}；</li>
 *   <li>{@link #activate(String, PrivateKey, PublicKey)} 在运行时生成新密钥并切换活跃密钥，
 *       旧密钥保留在环中供校验，直到 {@link #retireOlderThan(Duration)} 清理。</li>
 * </ul>
 */
public final class MlDsaKeyRing {

    private static final Logger LOG = Logger.getLogger(MlDsaKeyRing.class.getName());
    private static final String BC = BouncyCastleProvider.PROVIDER_NAME;
    public static final String ML_DSA_ALGORITHM = "ML-DSA-65";
    public static final String EPHEMERAL_KID = "ml-dsa-ephemeral";

    private final ConcurrentMap<String, MlDsaKeyEntry> entries = new ConcurrentHashMap<>();
    private volatile String activeKid;

    private MlDsaKeyRing() {
    }

    /** 从配置 + 遗留单钥回退构建密钥环。配置 keys 非空时优先；否则尝试单钥；再否则生成临时密钥。 */
    public static MlDsaKeyRing from(MlDsaKeyRingProperties props, String legacyPrivateKeyPem, String legacyPublicKeyPem) {
        PqcProviderInitializer.ensureBouncyCastle();
        MlDsaKeyRing ring = new MlDsaKeyRing();
        List<MlDsaKeyProperties> keys = props != null ? props.getKeys() : List.of();
        if (keys != null && !keys.isEmpty()) {
            for (MlDsaKeyProperties key : keys) {
                if (key == null || !isPresent(key.getKid()) || !isPresent(key.getPublicKey())) {
                    continue;
                }
                try {
                    PrivateKey privateKey = isPresent(key.getPrivateKey()) ? loadPrivateKey(key.getPrivateKey()) : null;
                    PublicKey publicKey = loadPublicKey(key.getPublicKey());
                    ring.add(key.getKid(), privateKey, publicKey);
                } catch (Exception ex) {
                    LOG.log(Level.WARNING, "Failed to load configured ML-DSA key kid=" + key.getKid(), ex);
                }
            }
            String preferred = props != null ? props.getActiveKid() : null;
            if (isPresent(preferred) && ring.entries.containsKey(preferred)) {
                ring.activeKid = preferred;
            } else {
                ring.activeKid = ring.pickActiveKid();
            }
            return ring;
        }
        if (isPresent(legacyPrivateKeyPem) && isPresent(legacyPublicKeyPem)) {
            try {
                ring.add("current", loadPrivateKey(legacyPrivateKeyPem), loadPublicKey(legacyPublicKeyPem));
                ring.activeKid = "current";
                return ring;
            } catch (Exception ex) {
                LOG.log(Level.WARNING, "Failed to load legacy ML-DSA keys, generating ephemeral pair", ex);
            }
        }
        // Ephemeral: tokens will NOT survive a restart.
        try {
            KeyPairGenerator kpg = KeyPairGenerator.getInstance(ML_DSA_ALGORITHM, BC);
            KeyPair kp = kpg.generateKeyPair();
            ring.add(EPHEMERAL_KID, kp.getPrivate(), kp.getPublic());
            ring.activeKid = EPHEMERAL_KID;
            LOG.warning("No ML-DSA keys configured; generated ephemeral keypair (kid=" + EPHEMERAL_KID
                    + "). Tokens will NOT survive a restart.");
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to generate ephemeral ML-DSA keypair", ex);
        }
        return ring;
    }

    public boolean containsKid(String kid) {
        return kid != null && entries.containsKey(kid);
    }

    public Optional<PublicKey> publicKeyFor(String kid) {
        if (!isPresent(kid)) {
            // 无 kid 的历史 token：回退到当前活跃公钥。
            return Optional.ofNullable(activePublicKey());
        }
        MlDsaKeyEntry entry = entries.get(kid);
        return entry == null ? Optional.empty() : Optional.ofNullable(entry.publicKey());
    }

    public PublicKey activePublicKey() {
        MlDsaKeyEntry active = entries.get(activeKid);
        return active != null ? active.publicKey() : null;
    }

    public PrivateKey activePrivateKey() {
        MlDsaKeyEntry active = entries.get(activeKid);
        return active != null ? active.privateKey() : null;
    }

    public String activeKid() {
        return activeKid;
    }

    public Set<String> kidSet() {
        return entries.keySet();
    }

    public int size() {
        return entries.size();
    }

    /**
     * 轮换：生成/注入新密钥并切换为活跃签名密钥。旧密钥保留在环中继续供校验。
     */
    public synchronized void activate(String kid, PrivateKey privateKey, PublicKey publicKey) {
        add(kid, privateKey, publicKey);
        this.activeKid = kid;
        LOG.info(() -> "ML-DSA active signing key switched to kid=" + kid
                + ", ring size=" + entries.size());
    }

    /** 移除非活跃且激活时间早于 retention 的旧密钥（双验窗口结束后的清理）。 */
    public synchronized void retireOlderThan(Duration retention) {
        Instant cutoff = Instant.now().minus(retention);
        int removed = 0;
        for (String kid : entries.keySet()) {
            if (kid.equals(activeKid)) {
                continue;
            }
            MlDsaKeyEntry entry = entries.get(kid);
            if (entry != null && entry.activatedAt().isBefore(cutoff)) {
                entries.remove(kid);
                removed++;
            }
        }
        if (removed > 0) {
            final int removedCount = removed;
            LOG.info(() -> "Retired " + removedCount + " expired ML-DSA verification key(s); active kid=" + activeKid);
        }
    }

    private void add(String kid, PrivateKey privateKey, PublicKey publicKey) {
        entries.put(kid, new MlDsaKeyEntry(kid, privateKey, publicKey, Instant.now()));
    }

    private String pickActiveKid() {
        String withPrivate = null;
        String first = null;
        for (MlDsaKeyEntry entry : entries.values()) {
            if (first == null) {
                first = entry.kid();
            }
            if (entry.privateKey() != null) {
                withPrivate = entry.kid();
            }
        }
        return withPrivate != null ? withPrivate : first;
    }

    private static PrivateKey loadPrivateKey(String pem) throws Exception {
        try (PEMParser parser = new PEMParser(new StringReader(pem))) {
            Object obj = parser.readObject();
            if (obj instanceof PrivateKeyInfo pki) {
                return new JcaPEMKeyConverter().setProvider(BC).getPrivateKey(pki);
            }
            throw new IllegalArgumentException("PEM is not a PKCS#8 private key: " + obj);
        }
    }

    private static PublicKey loadPublicKey(String pem) throws Exception {
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

    /**
     * 环中的一个版本条目。privateKey 可能为 null（仅校验方）。
     */
    public record MlDsaKeyEntry(String kid, PrivateKey privateKey, PublicKey publicKey, Instant activatedAt) {
    }
}