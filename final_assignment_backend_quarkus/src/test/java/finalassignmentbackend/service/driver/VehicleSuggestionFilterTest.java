package finalassignmentbackend.service.driver;

import finalassignmentbackend.entity.VehicleInformation;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class VehicleSuggestionFilterTest {

    @Test
    void platesAreScopedToOwnedVehiclesAndPrefix() {
        List<String> plates = VehicleSuggestionFilter.plates(List.of(
                vehicle("粤A11111", "轿车"),
                vehicle("粤A12222", "SUV"),
                vehicle("京B99999", "轿车")
        ), "粤A1", 10);
        assertEquals(List.of("粤A11111", "粤A12222"), plates);
    }

    @Test
    void typesAreScopedAndDeduped() {
        List<String> types = VehicleSuggestionFilter.types(List.of(
                vehicle("粤A11111", "轿车"),
                vehicle("粤A12222", "轿车"),
                vehicle("京B99999", "SUV")
        ), "轿", 10);
        assertEquals(List.of("轿车"), types);
    }

    @Test
    void emptyOwnedVehiclesYieldEmptySuggestions() {
        assertEquals(List.of(), VehicleSuggestionFilter.plates(List.of(), "粤", 5));
    }

    private static VehicleInformation vehicle(String plate, String type) {
        VehicleInformation vehicle = new VehicleInformation();
        vehicle.setLicensePlate(plate);
        vehicle.setVehicleType(type);
        return vehicle;
    }
}