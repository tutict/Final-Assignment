package finalassignmentbackend.service.driver;

import finalassignmentbackend.entity.VehicleInformation;

import java.util.List;
import java.util.Locale;
import java.util.Objects;

public final class VehicleSuggestionFilter {
    private VehicleSuggestionFilter() {
    }

    public static List<String> plates(List<VehicleInformation> vehicles, String prefix, int limit) {
        return values(vehicles, VehicleInformation::getLicensePlate, prefix, limit);
    }

    public static List<String> types(List<VehicleInformation> vehicles, String prefix, int limit) {
        return values(vehicles, VehicleInformation::getVehicleType, prefix, limit);
    }

    private static List<String> values(List<VehicleInformation> vehicles,
                                       java.util.function.Function<VehicleInformation, String> getter,
                                       String prefix,
                                       int limit) {
        if (vehicles == null || vehicles.isEmpty()) {
            return List.of();
        }
        String normalized = prefix == null ? "" : prefix.trim().toLowerCase(Locale.ROOT);
        int resolvedLimit = Math.max(limit, 1);
        return vehicles.stream()
                .map(getter)
                .filter(Objects::nonNull)
                .filter(value -> normalized.isEmpty() || value.toLowerCase(Locale.ROOT).startsWith(normalized))
                .distinct()
                .limit(resolvedLimit)
                .toList();
    }
}