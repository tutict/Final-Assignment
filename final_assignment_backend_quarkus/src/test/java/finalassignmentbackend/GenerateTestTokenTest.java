package finalassignmentbackend;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNotNull;

/**
 * 生成一个测试用 JWT（HS256 默认配置下）。
 *
 * <p>历史版本用 {@code new TokenProvider()} 手动构造，但 {@link TokenProvider} 现为 CDI bean
 * （{@code @Inject JWTParser} / {@code @Inject MlDsaKeyRing}），无法脱离容器实例化；
 * 改为 {@code @QuarkusTest} 通过注入获取实例。运行：{@code ./gradlew test --tests GenerateTestTokenTest}。
 *
 * <p><b>当前 {@code @Disabled} 的原因：</b>这是一个 {@code @QuarkusTest}，需要完整的应用上下文启动，
 * 而本模块依赖 DevServices（Redis / Kafka / MySQL 容器）以及 {@code RunDocker} 在
 * {@link jakarta.enterprise.event.Observes StartupEvent} 中通过 Testcontainers 拉起依赖。
 * 在没有可用的 Docker 守护进程的环境下（如无 Docker Desktop 的 CI/本地机器），应用上下文无法启动，
 * 测试会挂起直到超时。要运行本测试，请先启动 Docker，或提供下列外部配置：
 * <ul>
 *   <li>{@code quarkus.datasource.db.url} / {@code quarkus.datasource.username} / {@code quarkus.datasource.password}</li>
 *   <li>{@code quarkus.redis.hosts}</li>
 *   <li>{@code kafka.bootstrap.servers}</li>
 * </ul>
 * 并在测试 profile 中禁用 {@code RunDocker} 的容器自启行为。
 *
 * <p>移除 {@link Disabled} 注解即可在具备 Docker 的环境中运行。
 */
@QuarkusTest
@Disabled("需要 Docker/DevServices（Redis+Kafka+MySQL）启动应用上下文；无 Docker 环境下跳过。详见类注释。")
class GenerateTestTokenTest {

    @Inject
    TokenProvider tokenProvider;

    @Test
    void generateTestToken() {
        String testToken = tokenProvider.createToken("testuser", "admin");
        assertNotNull(testToken, "Token provider should mint a token");
        System.out.println("Generated Test Token: " + testToken);
    }
}
