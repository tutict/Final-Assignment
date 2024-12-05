package finalassignmentbackend.controller;

import finalassignmentbackend.config.login.jwt.TokenProvider;
import finalassignmentbackend.entity.LoginLog;
import finalassignmentbackend.entity.RoleManagement;
import finalassignmentbackend.entity.UserManagement;
import finalassignmentbackend.service.LoginLogService;
import finalassignmentbackend.service.RoleManagementService;
import finalassignmentbackend.service.UserManagementService;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@Path("/eventbus/auth")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuthController {

    @Inject
    TokenProvider tokenProvider;

    @Inject
    LoginLogService loginLogService;

    @Inject
    UserManagementService userManagementService;

    @Inject
    RoleManagementService roleManagementService;


    private static final Logger logger = Logger.getLogger(String.valueOf(AuthController.class));

    @POST
    @Path("/login")
    @PermitAll
    public Response login(LoginRequest loginRequest) {
        logger.info(String.format("Attempting to authenticate user: %s", loginRequest.getUsername()));
        try {
            // Fetch user details
            UserManagement user = userManagementService.getUserByUsername(loginRequest.getUsername());

            if (user != null && authenticateUser(user, loginRequest.getPassword())) {
                // Fetch the user's role
                RoleManagement role = roleManagementService.getRoleByName(user.getUserType());

                if (role != null) {
                    // Add the user's role to a set for JWT token creation
                    String roles = role.getRoleName();

                    // Create JWT Token
                    String token = tokenProvider.createToken(loginRequest.getUsername(), roles);

                    logger.info(String.format("User authenticated successfully: %s", loginRequest.getUsername()));
                    return Response.ok(Map.of("token", token)).build();
                } else {
                    logger.severe(String.format("Role not found for user: %s", loginRequest.getUsername()));
                    recordFailedLogin(loginRequest.getUsername());
                    return Response.status(Response.Status.UNAUTHORIZED).build();
                }
            } else {
                logger.severe(String.format("Authentication failed for user: %s", loginRequest.getUsername()));
                recordFailedLogin(loginRequest.getUsername());
                return Response.status(Response.Status.UNAUTHORIZED).build();
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, String.format("Authentication failed for user: %s", loginRequest.getUsername()), e);
            recordFailedLogin(loginRequest.getUsername());
            return Response.status(Response.Status.UNAUTHORIZED).build();
        }
    }

    @POST
    @Path("/register")
    @PermitAll
    public Response registerUser(RegisterRequest registerRequest) {
        logger.info(String.format("Attempting to register user: %s", registerRequest.getUsername()));
        try {
            if (userManagementService.isUsernameExists(registerRequest.getUsername())) {
                logger.warning(String.format("Username already exists: %s", registerRequest.getUsername()));
                return Response.status(Response.Status.CONFLICT).build();
            }

            UserManagement newUser = new UserManagement();
            newUser.setUsername(registerRequest.getUsername());
            newUser.setPassword(registerRequest.getPassword());
            newUser.setUserType(registerRequest.isAdmin() ? "ADMIN" : "USER");

            userManagementService.createUser(newUser);

            logger.info(String.format("User registered successfully: %s", registerRequest.getUsername()));
            return Response.status(Response.Status.CREATED).build();
        } catch (Exception e) {
            logger.log(Level.SEVERE, String.format("Failed to register user: %s", registerRequest.getUsername()), e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GET
    @Path("/users")
    @RolesAllowed("ADMIN")
    public Response getAllUsers() {
        logger.info("Fetching all users");
        try {
            List<UserManagement> users = userManagementService.getAllUsers();
            return Response.ok(users).build();
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Failed to fetch all users", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    // 自定义的认证逻辑
    private boolean authenticateUser(UserManagement user, String password) {
        // 这里你可以实现自定义的用户认证逻辑，例如查找数据库、比对密码等
        return user.getPassword().equals(password);
    }

    // 记录登录失败日志
    private void recordFailedLogin(String username) {
        LoginLog loginLog = new LoginLog();
        loginLog.setUsername(username);
        loginLog.setLoginTime(LocalDateTime.now());
        loginLog.setLoginResult("FAILED");
        loginLogService.createLoginLog(loginLog);
    }

    @Setter
    @Getter
    public static class LoginRequest {
        private String username;
        private String password;
    }

    @Setter
    @Getter
    public static class RegisterRequest {
        private String username;
        private String password;
        private boolean admin;
    }
}
