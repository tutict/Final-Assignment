package com.tutict.finalassignmentbackend.service.auth;

import com.tutict.finalassignmentbackend.config.security.pqc.MlDsaKeyRing;
import com.tutict.finalassignmentbackend.config.security.pqc.MlDsaKeyRingProperties;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.openssl.jcajce.JcaPEMWriter;
import org.bouncycastle.util.io.pem.PemObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.StringWriter;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PublicKey;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * ML-DSA 在线密钥轮换（与 cloud 端语义一致）。
 *
 * <p>{@link #rotate()} 生成新 ML-DSA-65 密钥对，以时间戳 kid 注入 {@link MlDsaKeyRing} 并切换为活跃签名密钥；
 * 旧密钥保留在环中继续参与校验（"新旧密钥双验"），超过 retention 窗口后清理。
 * 新公钥通过 {@link MlDsaKeyRotationResult#publicKeyPem()} 返回，供运维同步到各校验方配置。
 */
@Service
public class MlDsaKeyRotationService {

    private static final Logger LOG = Logger.getLogger(MlDsaKeyRotationService.class.getName());
    private static final String BC = BouncyCastleProvider.PROVIDER_NAME;
    private static final DateTimeFormatter KID_TIMESTAMP =
            DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss").withZone(ZoneId.systemDefault());

    private final MlDsaKeyRing keyRing;
    private final MlDsaKeyRingProperties properties;

    @Value("${jwt.ml-dsa.rotation.enabled:false}")
    private boolean rotationEnabled;

    @Value("${jwt.ml-dsa.rotation.retention-minutes:1440}")
    private long retentionMinutes;

    public MlDsaKeyRotationService(MlDsaKeyRing keyRing, MlDsaKeyRingProperties properties) {
        this.keyRing = keyRing;
        this.properties = properties;
    }

    // 读取 jwt.ml-dsa.rotation.interval-minutes（默认 10080 分钟 = 7 天）。历史上这里读的是
    // interval-ms，但 application.yml 只定义 interval-minutes、properties 也无对应字段，
    // 导致 ML_DSA_ROTATION_INTERVAL_MINUTES 被静默忽略。改为读 minutes 换算为毫秒。
    @Scheduled(fixedDelayString = "#{T(java.lang.Math).max(${jwt.ml-dsa.rotation.interval-minutes:10080}, 1) * 60 * 1000}")
    public void scheduledRotate() {
        if (!rotationEnabled) {
            return;
        }
        try {
            MlDsaKeyRotationResult result = rotate();
            LOG.info(() -> "Scheduled ML-DSA key rotation completed: kid=" + result.kid());
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Scheduled ML-DSA key rotation failed", ex);
        }
    }

    /**
     * 立即执行一次轮换：生成新密钥对、切换活跃签名密钥、清理超期旧密钥。
     */
    public synchronized MlDsaKeyRotationResult rotate() {
        try {
            KeyPairGenerator kpg = KeyPairGenerator.getInstance(MlDsaKeyRing.ML_DSA_ALGORITHM, BC);
            KeyPair kp = kpg.generateKeyPair();
            String kid = "ml-dsa-" + KID_TIMESTAMP.format(Instant.now());

            keyRing.activate(kid, kp.getPrivate(), kp.getPublic());
            keyRing.retireOlderThan(Duration.ofMinutes(Math.max(retentionMinutes, 1)));

            String publicKeyPem = toPem(kp.getPublic());
            LOG.info(() -> "ML-DSA key rotated to kid=" + kid
                    + " (ring size=" + keyRing.size() + "). Distribute the new public key to verifiers.");
            return new MlDsaKeyRotationResult(kid, publicKeyPem);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to rotate ML-DSA key", ex);
        }
    }

    public boolean isRotationEnabled() {
        return rotationEnabled;
    }

    private static String toPem(PublicKey publicKey) throws Exception {
        StringWriter sw = new StringWriter();
        try (JcaPEMWriter writer = new JcaPEMWriter(sw)) {
            writer.writeObject(new PemObject("PUBLIC KEY", publicKey.getEncoded()));
        }
        return sw.toString();
    }

    /**
     * 一次轮换的结果：新 kid 与需要分发给校验方的新公钥 PEM。
     */
    public record MlDsaKeyRotationResult(String kid, String publicKeyPem) {
    }
}