package com.tutict.finalassignmentbackend.config.login.JWT;

import jakarta.annotation.Resource;
import org.junit.platform.commons.logging.Logger;
import org.junit.platform.commons.logging.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collection;
import java.util.function.Supplier;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    public static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    private final TokenProvider tokenProvider;

    @Resource
    private AuthenticationManager authenticationManager;

    @Autowired
    public AuthController(TokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    /**
     * 处理用户登录请求的方法
     * 该方法尝试使用提供的用户名和密码对用户进行身份验证
     * 如果身份验证成功，它将生成一个包含用户权限信息的JWT令牌，并通过HTTP响应返回
     * 如果身份验证失败，它将记录警告信息，并返回401 Unauthorized响应
     *
     * @param username 用户名，用于身份验证
     * @param password 密码，用于身份验证
     * @return ResponseEntity对象，包含响应状态和身体内容
     */

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestParam String username, @RequestParam String password) {
        try {
            // 尝试使用提供的用户名和密码进行身份验证
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(username, password)
            );

            // 获取身份验证后的用户权限
            Collection<? extends GrantedAuthority> authorities = authentication.getAuthorities();
            // 根据用户名和权限生成JWT令牌
            String token = tokenProvider.createToken(username, authorities);

            // 返回包含JWT令牌的响应，指示登录成功
            return ResponseEntity.ok().body("Bearer " + token);
        } catch (AuthenticationException e) {
            // 如果发生身份验证异常，表示登录失败
            // 准备一条关于身份验证失败的消息
            Supplier<String> messageSupplier = () -> "Authentication failed for user: " + username;

            // 记录身份验证失败的警告信息
            logger.warn(null, messageSupplier);
            // 返回401 Unauthorized响应，表示登录失败
            return ResponseEntity.status(401).body("Unauthorized");

        }
    }

}
