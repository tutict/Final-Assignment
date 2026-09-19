package com.tutict.finalassignmentcloud.audit.contract;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AuditRoleGateTest {

    @Test
    void auditControllersAreSuperAdminOnly() throws IOException {
        for (String file : new String[]{"LoginLogController.java", "OperationLogController.java", "SystemLogsController.java"}) {
            String src = read(file);
            assertTrue(src.contains("@RolesAllowed({\"SUPER_ADMIN\"})"), file);
            assertFalse(src.contains("@RolesAllowed({\"SUPER_ADMIN\", \"ADMIN\"})"), file);
        }
    }

    private static String read(String file) throws IOException {
        Path cwd = Path.of("").toAbsolutePath();
        Path direct = cwd.resolve("src/main/java/com/tutict/finalassignmentcloud/audit/controller").resolve(file);
        if (Files.isRegularFile(direct)) {
            return Files.readString(direct, StandardCharsets.UTF_8);
        }
        return Files.readString(cwd.resolve("finalassignmentcloud-audit/src/main/java/com/tutict/finalassignmentcloud/audit/controller").resolve(file), StandardCharsets.UTF_8);
    }
}
