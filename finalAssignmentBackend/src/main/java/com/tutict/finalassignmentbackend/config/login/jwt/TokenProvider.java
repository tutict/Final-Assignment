package com.tutict.finalassignmentbackend.config.login.jwt;

import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;

import javax.crypto.SecretKey;
import java.util.Base64;
import java.util.Date;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class TokenProvider {

    private static final Logger LOG = Logger.getLogger(TokenProvider.class.getName());

    @Value("${jwt.secret.key}")
    private String base64Secret;

    private SecretKey secretKey;

    @PostConstruct
    public void init() {
        // Decode base64 secret key into byte array
        byte[] keyBytes = Base64.getDecoder().decode(base64Secret);
        // Use the Keys utility class to create the SecretKey for HMACSHA256
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);

        LOG.info("TokenProvider initialized with HS256 secret key");
    }


    /**
     * Creates a JWT token with the provided username and roles.
     *
     * @param username the username (subject)
     * @param roles    the roles
     * @return the generated JWT token
     */
    public String createToken(String username, String roles) {
        long now = System.currentTimeMillis();
        Date expirationDate = new Date(now + 86400000L); // 24 hours expiration

        // Create JWT
        return Jwts.builder()
                .subject(username)
                .claim("roles", roles) // Adding roles as a claim
                .issuedAt(new Date(now))
                .expiration(expirationDate)
                .signWith(secretKey) // Using SecretKey for signing
                .compact();
    }

    /**
     * Validates the provided JWT token.
     *
     * @param token the JWT token
     * @return true if the token is valid, false otherwise
     */
    public boolean validateToken(String token) {
        try {
            // Parse and validate the token
            Jwts.parser()
                    .verifyWith(secretKey) // Set the signing key explicitly
                    .build()
                    .parseSignedClaims(token); // Throws exception if the token is invalid

            LOG.log(Level.INFO, "Token validated successfully: " + token);
            return true;
        } catch (JwtException e) {
            LOG.log(Level.WARNING, "Invalid token: " + e.getMessage(), e);
            return false;
        }
    }
}