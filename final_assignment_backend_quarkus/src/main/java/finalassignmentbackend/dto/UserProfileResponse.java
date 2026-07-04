package finalassignmentbackend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
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
