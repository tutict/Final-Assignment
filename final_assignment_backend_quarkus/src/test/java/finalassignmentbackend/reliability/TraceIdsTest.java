package finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class TraceIdsTest {

    @Test
    void incomingValueIsKeptAndBlankValuesAreGenerated() {
        assertEquals("trace-1", TraceIds.resolve("  trace-1  "));
        assertTrue(TraceIds.resolve(null).matches("[0-9a-f]{16}"));
        assertTrue(TraceIds.resolve("   ").matches("[0-9a-f]{16}"));
    }
}
