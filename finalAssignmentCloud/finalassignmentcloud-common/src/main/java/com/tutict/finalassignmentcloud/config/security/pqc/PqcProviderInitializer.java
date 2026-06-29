package com.tutict.finalassignmentcloud.config.security.pqc;

import org.bouncycastle.jce.provider.BouncyCastleProvider;

import java.security.Security;

/**
 * 幂等地注册 Bouncy Castle provider，供 ML-DSA 等后量子算法使用。
 * JDK 25 自带的 SunEC 不提供 ML-DSA，必须依赖 BC。
 * 该类位于 common 模块，供各微服务的 ServiceTokenProvider 在构造时调用。
 */
public final class PqcProviderInitializer {

    private PqcProviderInitializer() {
    }

    public static void ensureBouncyCastle() {
        if (Security.getProvider(BouncyCastleProvider.PROVIDER_NAME) == null) {
            Security.insertProviderAt(new BouncyCastleProvider(), 1);
        }
    }
}
