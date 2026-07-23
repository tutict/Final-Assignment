package com.tutict.finalassignmentbackend.appeal;

import com.tutict.finalassignmentbackend.controller.business.AppealManagementController;
import com.tutict.finalassignmentbackend.dto.request.AppealCreateRequest;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.dto.response.AppealResponse;
import com.tutict.finalassignmentbackend.dto.response.UserProfileResponse;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.service.appeal.AppealRecordService;
import com.tutict.finalassignmentbackend.service.appeal.AppealReviewService;
import com.tutict.finalassignmentbackend.service.auth.AuthWsService;
import com.tutict.finalassignmentbackend.service.business.BusinessRecordViewService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AppealCreationIdempotencyContractTest {

    @Test
    void sameAuthenticatedLogicalOperationCreatesOnceThenReturnsSuccessful208() {
        AuthWsService authService = mock(AuthWsService.class);
        AppealRecordService appealService = mock(AppealRecordService.class);
        AppealManagementController controller = new AppealManagementController(
                authService,
                appealService,
                mock(AppealReviewService.class),
                mock(BusinessRecordViewService.class)
        );
        Authentication authentication = new UsernamePasswordAuthenticationToken(
                "contract-user",
                "unused",
                List.of(new SimpleGrantedAuthority("ROLE_USER"))
        );
        UserProfileResponse profile = UserProfileResponse.builder()
                .authUserId(77L)
                .username("contract-user")
                .driverId(41L)
                .build();
        when(authService.getCurrentUserProfile("contract-user")).thenReturn(profile);
        when(appealService.tryStartIdempotentCreate(
                eq("K1"),
                any(AppealRecord.class),
                eq(77L)
        )).thenReturn(true, false);
        when(appealService.createAppeal(any(AppealRecord.class))).thenAnswer(invocation -> {
            AppealRecord saved = invocation.getArgument(0);
            saved.setAppealId(501L);
            return saved;
        });

        ResponseEntity<ApiResponse<AppealResponse>> first = controller.createAppeal(
                request(),
                "K1",
                authentication
        );
        ResponseEntity<ApiResponse<AppealResponse>> duplicate = controller.createAppeal(
                request(),
                "K1",
                authentication
        );

        assertThat(first.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(first.getBody()).isNotNull();
        assertThat(first.getBody().isSuccess()).isTrue();
        assertThat(first.getBody().getData().getAppealId()).isEqualTo(501L);
        assertThat(duplicate.getStatusCode()).isEqualTo(HttpStatus.ALREADY_REPORTED);
        assertThat(duplicate.getBody()).isNotNull();
        assertThat(duplicate.getBody().isSuccess()).isTrue();
        assertThat(duplicate.getBody().getData()).isNull();
        verify(appealService, times(1)).createAppeal(any(AppealRecord.class));
        verify(appealService, times(1)).markHistorySuccess("K1", 501L);

        ArgumentCaptor<AppealRecord> appeal = ArgumentCaptor.forClass(AppealRecord.class);
        verify(appealService, times(2)).tryStartIdempotentCreate(eq("K1"), appeal.capture(), eq(77L));
        assertThat(appeal.getAllValues()).allSatisfy(value -> {
            assertThat(value.getCreatedBy()).isEqualTo("contract-user");
            assertThat(value.getUpdatedBy()).isEqualTo("contract-user");
            assertThat(value.getDriverId()).isEqualTo(41L);
        });
    }

    private static AppealCreateRequest request() {
        AppealCreateRequest request = new AppealCreateRequest();
        request.setOffenseId(91L);
        request.setAppellantName("Contract User");
        request.setIdCard("110101199001011234");
        request.setContact("13800138000");
        request.setAppealReason("The recorded offense does not match the observed event.");
        request.setAppealTime(LocalDateTime.of(2026, 7, 23, 9, 0));
        return request;
    }
}
