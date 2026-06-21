package com.tutict.finalassignmentcloud.traffic.config;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.util.Locale;
import java.util.Set;

@Configuration
public class DatabaseCredentialGuard {

    private final String ds0Username;
    private final String ds0Password;
    private final String ds1Username;
    private final String ds1Password;

    public DatabaseCredentialGuard(
            @Value("${spring.shardingsphere.datasource.ds0.username}") String ds0Username,
            @Value("${spring.shardingsphere.datasource.ds0.password}") String ds0Password,
            @Value("${spring.shardingsphere.datasource.ds1.username}") String ds1Username,
            @Value("${spring.shardingsphere.datasource.ds1.password}") String ds1Password) {
        this.ds0Username = ds0Username;
        this.ds0Password = ds0Password;
        this.ds1Username = ds1Username;
        this.ds1Password = ds1Password;
    }

    @PostConstruct
    public void validate() {
        validateUsername("ds0", ds0Username);
        validatePassword("ds0", ds0Password);
        validateUsername("ds1", ds1Username);
        validatePassword("ds1", ds1Password);
    }

    private void validateUsername(String datasource, String username) {
        if (isBlank(username)) {
            throw new IllegalStateException(datasource + " database username must be provided");
        }
        if ("root".equalsIgnoreCase(username.trim())) {
            throw new IllegalStateException(datasource + " must not use the MySQL root account");
        }
    }

    private void validatePassword(String datasource, String password) {
        if (isBlank(password)) {
            throw new IllegalStateException(datasource + " database password must be provided");
        }
        String normalized = password.trim().toLowerCase(Locale.ROOT);
        if (Set.of("root", "password", "changeme", "change-me", "default").contains(normalized)) {
            throw new IllegalStateException(datasource + " database password must not use a default value");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
