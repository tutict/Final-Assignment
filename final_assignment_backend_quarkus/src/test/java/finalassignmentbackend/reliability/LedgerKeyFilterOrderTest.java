package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertTrue;

import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import org.junit.jupiter.api.Test;

class LedgerKeyFilterOrderTest {

    @Test
    void missingKeyIsCheckedAfterAuthentication() {
        Priority priority = LedgerKeyFilter.class.getAnnotation(Priority.class);
        assertTrue(priority.value() > Priorities.AUTHENTICATION);
    }
}