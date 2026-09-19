package finalassignmentbackend.contract;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RoleGateAnnotationTest {

    private static final Pattern CLASS_ROLES = Pattern.compile(
            "@RolesAllowed\\(\\{([^}]+)\\}\\)\\s*public class ([A-Za-z0-9_]+)");

    @Test
    void writeControllersDoNotGrantUserAtClassLevel() throws IOException {
        String src = readController("DriverInformationController.java")
                + readController("VehicleInformationController.java")
                + readController("FineInformationController.java")
                + readController("OffenseInformationController.java")
                + readController("DeductionInformationController.java")
                + readController("PaymentRecordController.java")
                + readController("WorkflowController.java")
                + readController("TrafficViolationController.java");
        Matcher matcher = CLASS_ROLES.matcher(src);
        boolean found = false;
        while (matcher.find()) {
            found = true;
            String roles = matcher.group(1);
            String cls = matcher.group(2);
            assertFalse(roles.contains("\"USER\""), cls + " class-level still allows USER: " + roles);
        }
        assertTrue(found, "expected class-level RolesAllowed on business controllers");
    }

    @Test
    void auditAndRagAdminAreSuperAdminOnly() throws IOException {
        assertClassRoles("LoginLogController.java", "\"SUPER_ADMIN\"");
        assertClassRoles("OperationLogController.java", "\"SUPER_ADMIN\"");
        assertClassRoles("SystemLogsController.java", "\"SUPER_ADMIN\"");
        String rag = Files.readString(controllerRoot().resolve("rag").resolve("RagManagementController.java"), StandardCharsets.UTF_8);
        assertTrue(rag.contains("@RolesAllowed({\"SUPER_ADMIN\"})"));
        assertFalse(rag.contains("@RolesAllowed({\"SUPER_ADMIN\", \"ADMIN\"})"));
    }

    @Test
    void userCanStillReadOwnDriverAndFineLists() throws IOException {
        String driver = readController("DriverInformationController.java");
        String fine = readController("FineInformationController.java");
        assertTrue(driver.contains("@RolesAllowed({\"SUPER_ADMIN\", \"ADMIN\", \"TRAFFIC_POLICE\", \"USER\"})"));
        assertTrue(fine.contains("scopedOrEmpty"));
        assertTrue(driver.contains("canAccessDriver"));
    }

    @Test
    void vehicleAutocompleteAllowsUserAndScopesResults() throws IOException {
        String vehicle = readController("VehicleInformationController.java");
        assertTrue(vehicle.contains("@Path(\"/autocomplete/plates\")"));
        assertTrue(vehicle.contains("VehicleSuggestionFilter.plates"));
        assertTrue(vehicle.contains("VehicleSuggestionFilter.types"));
        assertTrue(vehicle.contains("ownedVehicles("));
        assertTrue(vehicle.contains("@Path(\"/search/general\")"));
        assertTrue(vehicle.contains("visibleVehicles("));
        assertTrue(vehicle.contains("ownsVehicle("));
        assertTrue(vehicle.contains("@Path(\"/search/license\")"));
    }

    private static void assertClassRoles(String file, String expected) throws IOException {
        String src = readController(file);
        Matcher matcher = CLASS_ROLES.matcher(src);
        assertTrue(matcher.find(), "missing class RolesAllowed in " + file);
        String roles = matcher.group(1).replace(" ", "");
        assertTrue(roles.contains(expected.replace(" ", "")), file + " roles=" + roles);
        assertFalse(roles.contains("\"ADMIN\"") && expected.equals("\"SUPER_ADMIN\""), file + " should not include ADMIN");
    }

    private static String readController(String file) throws IOException {
        return Files.readString(controllerRoot().resolve(file), StandardCharsets.UTF_8);
    }

    private static Path controllerRoot() {
        Path cwd = Path.of("").toAbsolutePath();
        Path direct = cwd.resolve("src/main/java/finalassignmentbackend/controller");
        if (Files.isDirectory(direct)) {
            return direct;
        }
        return cwd.resolve("final_assignment_backend_quarkus/src/main/java/finalassignmentbackend/controller");
    }
}