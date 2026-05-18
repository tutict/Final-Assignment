package com.tutict.finalassignmentbackend.controller.view;

import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.dto.response.OffenseDetailResponse;
import com.tutict.finalassignmentbackend.service.OffenseDetailService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.security.RolesAllowed;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/view/offenses")
@Tag(name = "Offense Details View", description = "Offense details view APIs")
@SecurityRequirement(name = "bearerAuth")
@RolesAllowed({"SUPER_ADMIN", "ADMIN", "TRAFFIC_POLICE", "APPEAL_REVIEWER", "FINANCE"})
public class OffenseDetailsController {

    private final OffenseDetailService offenseDetailService;

    public OffenseDetailsController(OffenseDetailService offenseDetailService) {
        this.offenseDetailService = offenseDetailService;
    }

    @GetMapping("/{offenseId}")
    @Operation(summary = "Get offense details")
    public ResponseEntity<ApiResponse<OffenseDetailResponse>> getDetails(@PathVariable Long offenseId) {
        return ResponseEntity.ok(ApiResponse.ok(offenseDetailService.getOffenseDetail(offenseId)));
    }
}
