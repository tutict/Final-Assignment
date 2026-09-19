package com.tutict.finalassignmentcloud.traffic.contract;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CloudRoleGateTest {

    @Test
    void userListsAreScopedAndIdCardSearchStaysStaffOnly() throws IOException {
        String driver = read("DriverInformationController.java");
        String vehicle = read("VehicleInformationController.java");
        String fine = read("FineInformationController.java");
        assertTrue(driver.contains("@RolesAllowed({\"SUPER_ADMIN\", \"ADMIN\", \"TRAFFIC_POLICE\", \"USER\"})"));
        assertTrue(driver.contains("isRegularUser(authentication, ELEVATED_ROLES)"));
        assertTrue(vehicle.contains("ownedVehicles(authentication)"));
        assertTrue(vehicle.contains("visibleVehicles(authentication"));
        assertTrue(fine.contains("fineRecordService.findByDriverId"));
        assertFalse(vehicle.contains("@GetMapping(\"/search/owner\")\n    @RolesAllowed"),
                "id-card vehicle search must stay staff-only");
    }

    private static String read(String file) throws IOException {
        Path cwd = Path.of("").toAbsolutePath();
        Path direct = cwd.resolve("src/main/java/com/tutict/finalassignmentcloud/traffic/controller").resolve(file);
        if (Files.isRegularFile(direct)) {
            return Files.readString(direct, StandardCharsets.UTF_8);
        }
        return Files.readString(cwd.resolve("finalassignmentcloud-traffic/src/main/java/com/tutict/finalassignmentcloud/traffic/controller").resolve(file), StandardCharsets.UTF_8);
    }
}
