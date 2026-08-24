package com.tutict.finalassignmentcloud.auth.config.pqc;

import com.tutict.finalassignmentcloud.config.security.pqc.MlDsaKeyRing;
import com.tutict.finalassignmentcloud.config.security.pqc.MlDsaKeyRingProperties;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 组装 {@link MlDsaKeyRing} 签名方密钥环。
 *
 * <p>优先级：{@code jwt.ml-dsa.keys} 版本化密钥列表 &gt; 遗留单钥
 * （{@code jwt.ml-dsa.private-key/public-key}）&gt; 运行时生成的临时密钥。
 */
@Configuration
@EnableConfigurationProperties(MlDsaKeyRingProperties.class)
public class MlDsaKeyRingConfig {

    @Bean
    public MlDsaKeyRing mlDsaKeyRing(MlDsaKeyRingProperties properties,
                                     @Value("${jwt.ml-dsa.private-key:}") String privateKeyPem,
                                     @Value("${jwt.ml-dsa.public-key:}") String publicKeyPem) {
        return MlDsaKeyRing.from(properties, privateKeyPem, publicKeyPem);
    }
}