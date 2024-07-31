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

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    private final TokenProvider tokenProvider;

    @Resource
    private AuthenticationManager authenticationManager;

    @Autowired
    public AuthController(TokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestParam String username, @RequestParam String password) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(username, password)
            );

            Collection<? extends GrantedAuthority> authorities = authentication.getAuthorities();
            String token = tokenProvider.createToken(username, authorities);

            return ResponseEntity.ok().body("Bearer " + token);
        } catch (AuthenticationException e) {
            Supplier<String> messageSupplier = () -> "Authentication failed for user: " + username;

            logger.warn(null, messageSupplier);
            return ResponseEntity.status(401).body("Unauthorized");

        }
    }

}
