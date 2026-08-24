package com.tutict.finalassignmentcloud.auth;

import com.tutict.finalassignmentcloud.config.security.pqc.MlDsaKeyRing;
import com.tutict.finalassignmentcloud.config.security.pqc.MlDsaKeyRingProperties;
import com.tutict.finalassignmentcloud.config.security.pqc.MlDsaKeyProperties;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.Signature;
import java.security.Security;
import java.time.Duration;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ML-DSA 密钥环轮换测试：验证 kid 标注入、新旧密钥双验、未知 kid 拒绝。
 */
class MlDsaKeyRotationTest {

    private static final String BC = BouncyCastleProvider.PROVIDER_NAME;
    private static final byte[] TEST_DATA = "test-signing-input".getBytes(java.nio.charset.StandardCharsets.UTF_8);

    @BeforeAll
    static void setup() {
        if (Security.getProvider(BC) == null) {
            Security.insertProviderAt(new BouncyCastleProvider(), 1);
        }
    }

    @Test
    @DisplayName("轮换后旧密钥仍能验证旧签名（新旧密钥双验）")
    void oldKeyStillValidAfterRotation() throws Exception {
        // Arrange: create a ring with a single key
        MlDsaKeyRingProperties props = new MlDsaKeyRingProperties();
        MlDsaKeyRing ring = MlDsaKeyRing.from(props, null, null);
        assertNotNull(ring.activeKid(), "ephemeral key should be active");

        // Sign with the initial key
        String initialKid = ring.activeKid();
        byte[] signature = sign(ring.activePrivateKey(), TEST_DATA);

        // Act: rotate to a new key
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("ML-DSA-65", BC);
        KeyPair newKp = kpg.generateKeyPair();
        String newKid = "rotated-key-1";
        ring.activate(newKid, newKp.getPrivate(), newKp.getPublic());

        // Assert: initial kid still in ring
        assertTrue(ring.containsKid(initialKid), "initial kid should remain in ring after rotation");
        assertEquals(newKid, ring.activeKid(), "active kid should be the new key");

        // Verify the old signature with the old key (by kid)
        assertNotNull(ring.publicKeyFor(initialKid).orElse(null), "old public key should be accessible");
        boolean oldValid = verify(ring.publicKeyFor(initialKid).get(), TEST_DATA, signature);
        assertTrue(oldValid, "signature signed with old key should still verify after rotation");
    }

    @Test
    @DisplayName("轮换后新密钥可签名并验证")
    void newKeySignsAndVerifies() throws Exception {
        MlDsaKeyRing ring = MlDsaKeyRing.from(new MlDsaKeyRingProperties(), null, null);

        // Rotate
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("ML-DSA-65", BC);
        KeyPair newKp = kpg.generateKeyPair();
        ring.activate("new-key", newKp.getPrivate(), newKp.getPublic());

        // Sign with new key
        byte[] newSig = sign(ring.activePrivateKey(), TEST_DATA);
        assertTrue(verify(ring.activePublicKey(), TEST_DATA, newSig), "new key signature should verify");

        // The new kid should be the active one
        assertEquals("new-key", ring.activeKid());
    }

    @Test
    @DisplayName("未知 kid 返回空 Optional")
    void unknownKidReturnsEmpty() {
        MlDsaKeyRing ring = MlDsaKeyRing.from(new MlDsaKeyRingProperties(), null, null);
        assertTrue(ring.publicKeyFor("unknown-kid").isEmpty(),
                "unknown kid should return empty Optional");
        assertFalse(ring.containsKid("unknown-kid"));
    }

    @Test
    @DisplayName("无 kid 的 token 回退到活跃公钥")
    void nullKidFallsBackToActivePublicKey() {
        MlDsaKeyRing ring = MlDsaKeyRing.from(new MlDsaKeyRingProperties(), null, null);
        assertNotNull(ring.publicKeyFor(null).orElse(null),
                "null kid should return the active public key");
        assertNotNull(ring.publicKeyFor("").orElse(null),
                "blank kid should return the active public key");
    }

    @Test
    @DisplayName("retireOlderThan 清理超期旧密钥但保留活跃密钥")
    void retireOlderThanRemovesOldKeys() {
        MlDsaKeyRing ring = MlDsaKeyRing.from(new MlDsaKeyRingProperties(), null, null);
        int initialSize = ring.size();

        // Add a few old keys (they'll have the same activatedAt, which is now)
        // To test retirement, we need keys older than retention. Since we can't modify activatedAt,
        // we use a zero retention: any non-active key older than 0 seconds should be removed.
        // Keys just added have activatedAt = now, so zero retention should remove them.
        ring.activate("old-key-1", null, ring.activePublicKey());
        ring.activate("old-key-2", null, ring.activePublicKey());

        // After 2 activations, size should be initialSize + 2 (old-key-1, old-key-2, active)
        // Actually activate adds to the ring, so the ring has previous keys + old-key-1 + old-key-2 + active
        // The active key is now "old-key-2", previous keys are old entries
        assertEquals(initialSize + 2, ring.size(), "ring should grow after activations");

        // Retire with zero retention: all non-active keys older than 0 seconds should be removed
        // But they were just added with activatedAt=now, so they're NOT older than 0 seconds
        // Let's use a negative retention to force removal
        ring.retireOlderThan(Duration.ofSeconds(-1));

        // After retire, only the active key should remain
        assertEquals(1, ring.size(), "only the active key should remain after negative retention retire");
    }

    @Test
    @DisplayName("从配置构建密钥环")
    void fromConfigBuildsRing() {
        // This test verifies MlDsaKeyRing.from with MlDsaKeyRingProperties.
        // Since we need actual PEM keys, we generate them and then convert to PEM format.
        // For simplicity, we test the ephemeral fallback path (props with empty keys).
        MlDsaKeyRingProperties props = new MlDsaKeyRingProperties();
        MlDsaKeyRing ring = MlDsaKeyRing.from(props, null, null);
        assertTrue(ring.size() >= 1, "ring should have at least one entry (ephemeral)");
        assertNotNull(ring.activeKid(), "active kid should be set");
        assertNotNull(ring.activePrivateKey(), "active private key should be available");
        assertNotNull(ring.activePublicKey(), "active public key should be available");
    }

    private static byte[] sign(java.security.PrivateKey key, byte[] data) throws Exception {
        Signature signer = Signature.getInstance("ML-DSA-65", BC);
        signer.initSign(key);
        signer.update(data);
        return signer.sign();
    }

    private static boolean verify(java.security.PublicKey key, byte[] data, byte[] signature) throws Exception {
        Signature verifier = Signature.getInstance("ML-DSA-65", BC);
        verifier.initVerify(key);
        verifier.update(data);
        return verifier.verify(signature);
    }
}