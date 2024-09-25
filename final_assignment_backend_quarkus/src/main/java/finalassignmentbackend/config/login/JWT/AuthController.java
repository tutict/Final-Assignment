package finalassignmentbackend.config.login.JWT;

import finalassignmentbackend.service.UserManagementService;
import io.quarkus.security.AuthenticationFailedException;
import io.quarkus.security.UnauthorizedException;
import jakarta.inject.Inject;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;


// 定义认证控制器类，处理与用户认证相关的API请求
@Path("/api/auth")
public class AuthController {

    // 初始化日志记录器，用于记录应用运行时的日志
    private static final Logger LOGGER = Logger.getLogger(AuthController.class);

    // 注入Token提供者，用于生成用户认证Token
    @Inject
    TokenProvider tokenProvider;

    // 注入用户管理服务，用于处理用户认证及相关操作
    @Inject
    UserManagementService userManagementService;

    // 定义处理登录请求的方法，通过表单提交用户名和密码
    @POST
    @Path("/login")
    public Response login(@FormParam("username") String username, @FormParam("password") String password) {
        try {
            // 验证用户凭据是否正确
            boolean isAuthenticated = authenticate(username, password);

            // 如果用户未通过验证，抛出UnauthorizedException异常
            if (!isAuthenticated) {
                throw new UnauthorizedException();
            }

            // 检查用户名是否存在于用户管理系统中
            boolean authorities = userManagementService.isUsernameExists(username);

            // 为用户生成Token
            String token = tokenProvider.createToken(username, String.valueOf(authorities));

            // 返回包含Token的响应，表示登录成功
            return Response.ok().entity("Bearer " + token).build();
        } catch (UnauthorizedException | AuthenticationFailedException e) {
            // 记录认证失败的日志信息
            LOGGER.warnf("Authentication failed for user: %s", username);

            // 返回未授权的响应，表示登录失败
            return Response.status(Response.Status.UNAUTHORIZED).entity("Unauthorized").build();
        }
    }

    // 私有方法，用于验证用户凭据
    private boolean authenticate(String username, String password) {

        // 调用用户管理服务的认证方法，验证用户凭据是否正确
        return userManagementService.authenticate(username, password);
    }
}
