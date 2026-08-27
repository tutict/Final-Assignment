package finalassignmentbackend.config.security.pqc;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.Config;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.ArrayList;
import java.util.List;

/**
 * 组装 {@link MlDsaKeyRing} 签名方密钥环（Quarkus CDI 版）。
 *
 * <p>优先级：{@code jwt.ml-dsa.keys} 版本化密钥列表 &gt; 遗留单钥
 * （{@code jwt.ml-dsa.private-key/public-key}）&gt; 运行时生成的临时密钥。
 *
 * <p>对齐 Spring config/security/pqc/MlDsaKeyRingConfig（Spring 用 @Bean）。
 * 这里通过 SmallRye {@link Config} 读取索引属性 {@code jwt.ml-dsa.keys.N.kid|public-key|private-key}，
 * 翻译成框架无关的 {@link MlDsaKeyRingProperties} 后调用共享的 {@link MlDsaKeyRing#from}。
 */
@ApplicationScoped
public class MlDsaKeyRingConfig {

    @Inject
    Config config;

    @ConfigProperty(name = "jwt.ml-dsa.private-key", defaultValue = "")
    String legacyPrivateKeyPem;

    @ConfigProperty(name = "jwt.ml-dsa.public-key", defaultValue = "")
    String legacyPublicKeyPem;

    @Produces
    @ApplicationScoped
    MlDsaKeyRing mlDsaKeyRing() {
        MlDsaKeyRingProperties props = loadProperties();
        return MlDsaKeyRing.from(props, legacyPrivateKeyPem, legacyPublicKeyPem);
    }

    private MlDsaKeyRingProperties loadProperties() {
        MlDsaKeyRingProperties props = new MlDsaKeyRingProperties();
        props.setActiveKid(config.getOptionalValue("jwt.ml-dsa.active-kid", String.class).orElse(null));
        props.setRotationEnabled(config.getOptionalValue("jwt.ml-dsa.rotation.enabled", Boolean.class).orElse(false));
        props.setRetentionMinutes(config.getOptionalValue("jwt.ml-dsa.rotation.retention-minutes", Long.class).orElse(1440L));

        // 索引属性 jwt.ml-dsa.keys.N.{kid,public-key,private-key}，从 0 开始连续读取
        List<MlDsaKeyProperties> keys = new ArrayList<>();
        int i = 0;
        while (true) {
            String kid = config.getOptionalValue("jwt.ml-dsa.keys." + i + ".kid", String.class).orElse(null);
            if (kid == null || kid.isBlank()) {
                break;
            }
            MlDsaKeyProperties key = new MlDsaKeyProperties();
            key.setKid(kid);
            key.setPublicKey(config.getOptionalValue("jwt.ml-dsa.keys." + i + ".public-key", String.class).orElse(""));
            key.setPrivateKey(config.getOptionalValue("jwt.ml-dsa.keys." + i + ".private-key", String.class).orElse(""));
            keys.add(key);
            i++;
            if (i > 64) { // 安全上限，避免配置错误导致死循环
                break;
            }
        }
        props.setKeys(keys);
        return props;
    }
}
