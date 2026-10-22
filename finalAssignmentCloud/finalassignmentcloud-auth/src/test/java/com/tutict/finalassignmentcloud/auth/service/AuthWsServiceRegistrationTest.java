package com.tutict.finalassignmentcloud.auth.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tutict.finalassignmentcloud.auth.client.AuditLogClient;
import com.tutict.finalassignmentcloud.auth.client.DriverClient;
import com.tutict.finalassignmentcloud.auth.client.RoleClient;
import com.tutict.finalassignmentcloud.auth.client.UserClient;
import com.tutict.finalassignmentcloud.auth.config.login.jwt.TokenProvider;
import com.tutict.finalassignmentcloud.auth.exception.UsernameAlreadyExistsException;
import com.tutict.finalassignmentcloud.auth.reliability.RegistrationIdempotencyService;
import com.tutict.finalassignmentcloud.dto.internal.InternalUserProfile;
import com.tutict.finalassignmentcloud.dto.internal.InternalUserView;
import com.tutict.finalassignmentcloud.entity.SysRole;
import com.tutict.finalassignmentcloud.reliability.IdempotencyConflictException;
import com.tutict.finalassignmentcloud.reliability.IdempotencyReplayException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

class AuthWsServiceRegistrationTest {

    private UserClient userClient;
    private RoleClient roleClient;
    private RegistrationIdempotencyService registrationIdempotency;
    private AuthWsService service;

    @BeforeEach
    void setUp() {
        userClient = mock(UserClient.class);
        roleClient = mock(RoleClient.class);
        registrationIdempotency = mock(RegistrationIdempotencyService.class);
        PasswordEncoder passwordEncoder = mock(PasswordEncoder.class);
        when(passwordEncoder.encode(anyString())).thenReturn("encoded-hash");
        service = new AuthWsService(mock(TokenProvider.class),
                mock(AuditLogClient.class),
                userClient,
                roleClient,
                mock(DriverClient.class),
                passwordEncoder,
                mock(RefreshTokenService.class),
                mock(TokenBlacklistService.class),
                registrationIdempotency);
    }

    @Test
    void replayedRequestReturnsTheOriginalResultWithoutCreatingTheUser() {
        doThrow(new IdempotencyReplayException("already processed"))
                .when(registrationIdempotency).reserve(anyString(), anyString(), anyString());

        assertEquals("CREATED", service.registerUser(request("alice", "s3cret", "key-1")));
        verify(userClient, never()).createUser(any());
    }

    @Test
    void existingUsernameIsRejectedWithADedicatedError() {
        when(userClient.getAuthenticationView("alice")).thenReturn(authenticationView("alice"));

        assertThrows(UsernameAlreadyExistsException.class,
                () -> service.registerUser(request("alice", "s3cret", "key-1")));
    }

    @Test
    void conflictingIdempotencyKeyIsNotSwallowed() {
        doThrow(new IdempotencyConflictException("reused with another payload"))
                .when(registrationIdempotency).reserve(anyString(), anyString(), anyString());

        assertThrows(IdempotencyConflictException.class,
                () -> service.registerUser(request("alice", "s3cret", "key-1")));
    }

    @Test
    void successfulRegistrationMarksTheLedgerAsSucceeded() {
        stubSuccessfulCreation();

        assertEquals("CREATED", service.registerUser(request("alice", "s3cret", "key-1")));
        verify(registrationIdempotency).markSuccess("key-1", 7L);
    }

    @Test
    void registrationWithoutIdempotencyKeySkipsTheLedger() {
        stubSuccessfulCreation();

        assertEquals("CREATED", service.registerUser(request("alice", "s3cret", null)));
        verify(registrationIdempotency, never()).reserve(anyString(), anyString(), anyString());
    }

    private void stubSuccessfulCreation() {
        when(userClient.getAuthenticationView("alice")).thenReturn(null);
        when(userClient.createUser(any())).thenReturn(profile(7L, "alice"));
        SysRole role = new SysRole();
        role.setRoleId(3);
        role.setRoleCode("USER");
        when(roleClient.create(any())).thenReturn(role);
    }

    private static AuthWsService.RegisterRequest request(String username, String password, String idempotencyKey) {
        AuthWsService.RegisterRequest request = new AuthWsService.RegisterRequest();
        request.setUsername(username);
        request.setPassword(password);
        request.setRole("USER");
        request.setIdempotencyKey(idempotencyKey);
        return request;
    }

    private static InternalUserProfile profile(Long userId, String username) {
        InternalUserProfile profile = new InternalUserProfile();
        profile.setUserId(userId);
        profile.setUsername(username);
        return profile;
    }

    private static InternalUserView authenticationView(String username) {
        InternalUserView view = new InternalUserView();
        view.setUsername(username);
        return view;
    }
}
