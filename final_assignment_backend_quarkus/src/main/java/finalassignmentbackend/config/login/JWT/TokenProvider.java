package finalassignmentbackend.config.login.JWT;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.security.Key;
import java.util.Date;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

@ApplicationScoped
public class TokenProvider {

    private static final Logger LOG = Logger.getLogger(TokenProvider.class);

    // JWT token validity duration (24 hours)
    private static final long JWT_TOKEN_VALIDITY = 24 * 60 * 60 * 1000;

    // Secret key for JWT token
    @ConfigProperty(name = "jwt.secret-key")
    String secretKey;

    private Key key;

    @PostConstruct
    public void init() {
        try {
            this.key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(secretKey));
        } catch (Exception e) {
            LOG.error("Failed to initialize the secret key for JWT", e);
        }
    }

    // Generates a JWT token for a user
    public String createToken(String username, Collection<? extends GrantedAuthority> authorities) {
        long now = System.currentTimeMillis();
        Date validity = new Date(now + JWT_TOKEN_VALIDITY);

        return Jwts.builder()
                .setSubject(username)
                .setIssuedAt(new Date(now))
                .setExpiration(validity)
                .signWith(key, SignatureAlgorithm.HS512)
                .claim("authorities", extractAuthorities(authorities))
                .compact();
    }

    // Extracts the username from the token
    public String getUsernameFromToken(String token) {
        return getClaimFromToken(token, Claims::getSubject);
    }

    // Extracts authorities from the token
    public List getAuthoritiesFromToken(String token) {
        return getClaimFromToken(token, claims -> claims.get("authorities", List.class));
    }

    // Extracts a specific claim from the token
    private <T> T getClaimFromToken(String token, Function<Claims, T> claimsResolver) {
        return claimsResolver.apply(getAllClaimsFromToken(token));
    }

    // Gets all claims from the token
    private Claims getAllClaimsFromToken(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    // Validates if the token is still valid
    public boolean validateToken(String token) {
        String username = getUsernameFromToken(token);
        return (username != null && !isTokenExpired(token));
    }

    // Checks if the token has expired
    private boolean isTokenExpired(String token) {
        return getClaimFromToken(token, Claims::getExpiration).before(new Date());
    }

    // Creates an Authentication object from the token
    public Authentication getAuthentication(String token) {
        String username = getUsernameFromToken(token);
        List<String> authorityStrings = getAuthoritiesFromToken(token);

        List<GrantedAuthority> grantedAuthorities = authorityStrings.stream()
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toList());

        return new UsernamePasswordAuthenticationToken(username, null, grantedAuthorities);
    }

    // Converts a collection of GrantedAuthority to a list of Strings
    private List<String> extractAuthorities(Collection<? extends GrantedAuthority> authorities) {
        return authorities.stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());
    }
}
