package com.tutict.finalassignmentcloud.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class UserProfileResponse {

    private Long authUserId;
    private String username;
    private String displayName;
    private String email;
    private String phoneNumber;
    private List<String> roles;
    private Long driverId;
    private String driverName;
}
