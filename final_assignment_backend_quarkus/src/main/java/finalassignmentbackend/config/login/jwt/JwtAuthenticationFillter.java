package finalassignmentbackend.config.login.jwt;

import io.quarkus.security.identity.SecurityIdentity;
import io.quarkus.security.runtime.QuarkusPrincipal;
import io.quarkus.security.runtime.QuarkusSecurityIdentity;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.ext.Provider;

import java.io.IOException;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

// Quarkus JAX-RS过滤器类，用于处理JWT认证
@Provider
@Priority(jakarta.ws.rs.Priorities.AUTHENTICATION)
public class JwtAuthenticationFilter implements ContainerRequestFilter {

    // 日志记录器，用于记录JWT认证过程中的信息
    private static final Logger logger = Logger.getLogger(JwtAuthenticationFilter.class.getName());

    // 注入TokenProvider用于验证和解析JWT
    @Inject
    TokenProvider tokenProvider;

    // 过滤请求，处理JWT认证
    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
        String jwt = getJwtFromRequest(requestContext);
        logger.log(Level.INFO, "从请求中提取的JWT: {0}", jwt);

        if (jwt != null && tokenProvider.validateToken(jwt)) {
            String username = tokenProvider.getUsernameFromToken(jwt);
            List<String> roles = tokenProvider.extractRoles(jwt);
            logger.log(Level.INFO, "JWT验证通过。用户名: {0}, 角色: {1}", new Object[]{username, roles});

            // 创建Quarkus安全身份
            Set<String> authorities = roles.stream().collect(Collectors.toSet());
            SecurityIdentity identity = QuarkusSecurityIdentity.builder()
                    .setPrincipal(new QuarkusPrincipal(username))
                    .addRoles(authorities)
                    .build();

            // 将安全身份设置到请求上下文中
            requestContext.setSecurityContext(new SecurityContextImpl(identity));
            logger.log(Level.INFO, "为用户设置认证: {0}", username);
        } else {
            logger.log(Level.WARNING, "请求中的JWT无效或缺失: {0}", requestContext.getUriInfo().getRequestUri());
        }
    }

    // 从请求头中提取JWT
    private String getJwtFromRequest(ContainerRequestContext requestContext) {
        String bearerToken = requestContext.getHeaderString(HttpHeaders.AUTHORIZATION);
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }

    // 自定义SecurityContext实现，用于设置Quarkus安全身份
    private static class SecurityContextImpl implements jakarta.ws.rs.core.SecurityContext {
        private final SecurityIdentity identity;

        SecurityContextImpl(SecurityIdentity identity) {
            this.identity = identity;
        }

        @Override
        public java.security.Principal getUserPrincipal() {
            return identity.getPrincipal();
        }

        @Override
        public boolean isUserInRole(String role) {
            return identity.getRoles().contains(role);
        }

        @Override
        public boolean isSecure() {
            return false; // 根据实际需求配置，假设非HTTPS
        }

        @Override
        public String getAuthenticationScheme() {
            return "Bearer";
        }
    }
}