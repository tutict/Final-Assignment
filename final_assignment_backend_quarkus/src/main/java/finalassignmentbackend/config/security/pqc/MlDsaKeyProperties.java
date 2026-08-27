package finalassignmentbackend.config.security.pqc;

/**
 * 单个版本化 ML-DSA 密钥的配置绑定项。
 * private-key / public-key 均为 PEM（PKCS#8 / SPKI）文本；verifier 只需 public-key。
 * 对齐 Spring config/security/pqc/MlDsaKeyProperties（框架无关 POJO）。
 */
public class MlDsaKeyProperties {

    private String kid;
    private String privateKey;
    private String publicKey;

    public String getKid() {
        return kid;
    }

    public void setKid(String kid) {
        this.kid = kid;
    }

    public String getPrivateKey() {
        return privateKey;
    }

    public void setPrivateKey(String privateKey) {
        this.privateKey = privateKey;
    }

    public String getPublicKey() {
        return publicKey;
    }

    public void setPublicKey(String publicKey) {
        this.publicKey = publicKey;
    }
}
