package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import finalassignmentbackend.config.login.jwt.JwtAuthenticationFilter;
import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.entity.SysUser;
import finalassignmentbackend.service.admin.SysUserService;
import finalassignmentbackend.service.auth.AuthWsService;
import finalassignmentbackend.service.auth.RefreshTokenService;
import finalassignmentbackend.service.auth.TokenBlacklistService;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.lang.reflect.Field;
import java.lang.reflect.Proxy;
import java.net.URI;
import org.junit.jupiter.api.Test;

class LoggedOutPaymentTest {

    @Test
    void loggedOutTokenCannotPostPayment() throws Exception {
        TokenBlacklistService blacklist = new TokenBlacklistService();
        AuthWsService auth = new AuthWsService();
        set(auth, "sysUserService", new SysUserService() {
            @Override
            public SysUser findByUsername(String username) {
                SysUser user = new SysUser();
                user.setUserId(6L);
                user.setUsername(username);
                return user;
            }
        });
        set(auth, "refreshTokenService", new RefreshTokenService() {
            @Override
            public void revokeUserTokens(Long userId) {
            }
        });
        set(auth, "tokenProvider", new TokenProvider() {
            @Override
            public long getExpirationMs(String token) {
                return 60_000L;
            }
        });
        set(auth, "tokenBlacklistService", blacklist);

        RuntimeException redisDown = assertThrows(RuntimeException.class,
                () -> auth.logout("ce", "Bearer old-token"));
        assertTrue(redisDown instanceof NullPointerException);

        Response denied = payment("Bearer old-token", blacklist);
        assertEquals(401, denied.getStatus());
        assertTrue(String.valueOf(denied.getEntity()).contains("Token has expired"));

        Response shed = payment("Bearer still-valid", blacklist);
        assertEquals(503, shed.getStatus());
        assertEquals("1", shed.getHeaderString("Retry-After"));
    }

    private static Response payment(String authorization, TokenBlacklistService blacklist) throws Exception {
        JwtAuthenticationFilter filter = new JwtAuthenticationFilter();
        set(filter, "tokenBlacklistService", blacklist);
        Response[] aborted = new Response[1];
        UriInfo uriInfo = (UriInfo) Proxy.newProxyInstance(UriInfo.class.getClassLoader(), new Class<?>[] {UriInfo.class},
                (proxy, method, args) -> switch (method.getName()) {
                    case "getPath" -> "api/payments";
                    case "getRequestUri" -> URI.create("http://127.0.0.1/api/payments");
                    case "toString" -> "api/payments";
                    case "hashCode" -> System.identityHashCode(proxy);
                    case "equals" -> proxy == args[0];
                    default -> throw new UnsupportedOperationException(method.getName());
                });
        ContainerRequestContext request = (ContainerRequestContext) Proxy.newProxyInstance(
                ContainerRequestContext.class.getClassLoader(),
                new Class<?>[] {ContainerRequestContext.class},
                (proxy, method, args) -> switch (method.getName()) {
                    case "getMethod" -> "POST";
                    case "getUriInfo" -> uriInfo;
                    case "getHeaderString" -> HttpHeaders.AUTHORIZATION.equals(args[0]) ? authorization : null;
                    case "abortWith" -> {
                        aborted[0] = (Response) args[0];
                        yield null;
                    }
                    case "toString" -> "payment";
                    case "hashCode" -> System.identityHashCode(proxy);
                    case "equals" -> proxy == args[0];
                    default -> throw new UnsupportedOperationException(method.getName());
                });
        filter.filter(request);
        return aborted[0];
    }

    private static void set(Object target, String name, Object value) throws Exception {
        Field field = target.getClass().getDeclaredField(name);
        field.setAccessible(true);
        field.set(target, value);
    }
}