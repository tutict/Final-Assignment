import finalassignmentbackend.config.login.jwt.TokenProvider;

import java.util.Set;

public class GenerateTestToken {
    public static void main(String[] args) {
        // 创建 TokenProvider 实例
        TokenProvider tokenProvider = new TokenProvider();
        tokenProvider.init(); // 初始化以生成密钥

        // 为用户 "testuser" 生成一个包含角色 "user" 或 "admin" 的测试 token
        String testToken = tokenProvider.createToken("testuser", "admin");

        // 打印生成的测试 Token
        System.out.println("Generated Test Token: " + testToken);
    }
}
