package finalassignmentbackend.controller;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import jakarta.annotation.security.PermitAll;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import lombok.Getter;
import lombok.Setter;

import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/auth")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuthController {

    @Inject
    TokenProvider tokenProvider;

    private static final Logger logger = Logger.getLogger(String.valueOf(AuthController.class));

    @POST
    @Path("/login")
    @PermitAll
    public Response login(LoginRequest loginRequest) {
        logger.info(String.format("Attempting to authenticate user: %s", loginRequest.getUsername()));
        try {
            // 使用自己实现的认证逻辑
            boolean isAuthenticated = authenticateUser(loginRequest.getUsername(), loginRequest.getPassword());

            if (isAuthenticated) {
                // 获取用户角色，可以是从数据库或其他数据源获取
                Set<String> roles = getUserRoles(loginRequest.getUsername());

                // 创建JWT Token
                String token = tokenProvider.createToken(loginRequest.getUsername(), roles);

                logger.info(String.format("User authenticated successfully: %s", loginRequest.getUsername()));
                return Response.ok(Map.of("token", token)).build();
            } else {
                logger.severe(String.format("Authentication failed for user: %s", loginRequest.getUsername()));
                return Response.status(Response.Status.UNAUTHORIZED).build();
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, String.format("Authentication failed for user: %s", loginRequest.getUsername()), e);
            return Response.status(Response.Status.UNAUTHORIZED).build();
        }
    }

    // 自定义的认证逻辑，替代Spring的AuthenticationManager
    private boolean authenticateUser(String username, String password) {
        // 这里你可以实现自定义的用户认证逻辑，例如查找数据库、比对密码等
        // 例如：
        return "user".equals(username) && "password".equals(password);
    }

    // 获取用户的角色，模拟从数据库或其他数据源中获取角色
    private Set<String> getUserRoles(String username) {
        // 这里可以根据实际需求，从数据库或其他数据源中查找用户的角色
        // 例如，假设所有用户都是 ROLE_USER
        return Set.of("USER");
    }

    @Setter
    @Getter
    public static class LoginRequest {
        private String username;
        private String password;

    }
}
