package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/vehicles")
public class VehicleInformationController {

    private static final Logger log = Logger.getLogger(VehicleInformationController.class.getName());

    private final VehicleInformationService vehicleInformationService;

    public VehicleInformationController(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> searchVehicles(
            @RequestParam String query,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            List<VehicleInformation> vehicles = vehicleInformationService.searchVehicles(query, page, size);
            return ResponseEntity.ok(vehicles);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid search parameters: " + e.getMessage());
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }
    }

    @GetMapping("/autocomplete/license-plate/me")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<String>> getLicensePlateAutocompleteSuggestions(
            @RequestParam String prefix,
            @RequestParam(defaultValue = "5") int maxSuggestions,
            @RequestParam(required = false) String ownerName) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        log.log(Level.INFO, "Fetching license plate suggestions for user: {0}, prefix: {1}, maxSuggestions: {2}",
                new Object[]{currentUsername, prefix, maxSuggestions});

        // 解码 ownerName
        String decodedOwnerName = ownerName != null ? URLDecoder.decode(ownerName, StandardCharsets.UTF_8) : currentUsername;
        log.log(Level.INFO, "Decoded ownerName: {0}", new Object[]{decodedOwnerName});

        List<String> suggestions = vehicleInformationService.getLicensePlateAutocompleteSuggestions(
                decodedOwnerName, prefix, maxSuggestions);

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No license plate suggestions found for prefix: {0} for user: {1}",
                    new Object[]{prefix, currentUsername});
        }
        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/vehicle-type/me")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<String>> getVehicleTypeAutocompleteSuggestions(
            @RequestParam String prefix,
            @RequestParam(defaultValue = "5") int maxSuggestions,
            @RequestParam(required = false) String ownerName) {

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        log.log(Level.INFO, "Fetching vehicle type suggestions for user: {0}, prefix: {1}, maxSuggestions: {2}",
                new Object[]{currentUsername, prefix, maxSuggestions});

        // 解码 prefix 和 ownerName
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        String decodedOwnerName = ownerName != null ? URLDecoder.decode(ownerName, StandardCharsets.UTF_8) : currentUsername;
        log.log(Level.INFO, "Decoded prefix: {0}, ownerName: {1}", new Object[]{decodedPrefix, decodedOwnerName});

        List<String> suggestions = vehicleInformationService.getVehicleTypeAutocompleteSuggestions(
                decodedOwnerName, decodedPrefix, maxSuggestions);

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No vehicle type suggestions found for prefix: {0} for user: {1}",
                    new Object[]{prefix, currentUsername});
        }
        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/license-plate-globally/me")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<String>> getLicensePlateAutocompleteSuggestionsGlobally(
            @RequestParam String prefix,
            @RequestParam(defaultValue = "5") int maxSuggestions) {

        // 解码 URL 编码的 prefix
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching license plate suggestions for prefix: {0}, decoded: {1}, maxSuggestions: {2}",
                new Object[]{prefix, decodedPrefix, maxSuggestions});

        List<String> suggestions = vehicleInformationService.getVehicleInformationByLicensePlateGlobally(decodedPrefix, maxSuggestions);

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No license plate suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        }
        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/vehicle-type-globally/me")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<String>> getVehicleTypeAutocompleteSuggestionsGlobally(
            @RequestParam String prefix,
            @RequestParam(defaultValue = "5") int maxSuggestions) {

        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching vehicle type suggestions for prefix: {0}, decoded: {1}, maxSuggestions: {2}",
                new Object[]{prefix, decodedPrefix, maxSuggestions});

        List<String> suggestions = vehicleInformationService.getVehicleInformationByTypeGlobally(decodedPrefix, maxSuggestions);

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No vehicle type suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        }
        return ResponseEntity.ok(suggestions);
    }

    @PostMapping
    @Transactional
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Void> createVehicleInformation(
            @Valid @RequestBody VehicleInformation vehicleInformation,
            @RequestParam String idempotencyKey) {
        try {
            vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, vehicleInformation, "create");
            log.info("Vehicle created with idempotencyKey: " + idempotencyKey);
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (RuntimeException e) {
            log.log(Level.SEVERE, "Failed to create vehicle: " + e.getMessage(), e);
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{vehicleId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<VehicleInformation> getVehicleInformationById(@PathVariable int vehicleId) {
        try {
            VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationById(vehicleId);
            if (vehicleInformation == null) {
                log.info("Vehicle not found for ID: " + vehicleId);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            return ResponseEntity.ok(vehicleInformation);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid vehicle ID: " + vehicleId);
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/license-plate/{licensePlate}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<VehicleInformation> getVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        try {
            VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
            if (vehicleInformation == null) {
                log.info("Vehicle not found for license plate: " + licensePlate);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            return ResponseEntity.ok(vehicleInformation);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid license plate: " + licensePlate);
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> getAllVehicleInformation() {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getAllVehicleInformation();
        return ResponseEntity.ok(vehicleInformationList);
    }

    @GetMapping("/type/{vehicleType}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByType(@PathVariable String vehicleType) {
        try {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByType(vehicleType);
            return ResponseEntity.ok(vehicleInformationList);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid vehicle type: " + vehicleType);
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }
    }

    @GetMapping("/owner/{ownerName}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByOwnerName(@PathVariable String ownerName) {
        try {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByOwnerName(ownerName);
            return ResponseEntity.ok(vehicleInformationList);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid owner name: " + ownerName);
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }
    }

    @GetMapping("/status/{currentStatus}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByStatus(@PathVariable String currentStatus) {
        try {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByStatus(currentStatus);
            return ResponseEntity.ok(vehicleInformationList);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid current status: " + currentStatus);
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }
    }

    @PutMapping("/{vehicleId}")
    @Transactional
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<VehicleInformation> updateVehicleInformation(
            @PathVariable int vehicleId,
            @Valid @RequestBody VehicleInformation vehicleInformation,
            @RequestParam String idempotencyKey) {
        try {
            vehicleInformation.setVehicleId(vehicleId);
            vehicleInformationService.checkAndInsertIdempotency(idempotencyKey, vehicleInformation, "update");
            log.info("Vehicle updated with ID: " + vehicleId);
            return ResponseEntity.ok(vehicleInformationService.getVehicleInformationById(vehicleId));
        } catch (RuntimeException e) {
            log.log(Level.SEVERE, "Failed to update vehicle: " + e.getMessage(), e);
            if (e.getMessage().contains("Duplicate request")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).build();
            } else if (e.getMessage().contains("Vehicle not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @DeleteMapping("/{vehicleId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteVehicleInformation(@PathVariable int vehicleId) {
        try {
            vehicleInformationService.deleteVehicleInformation(vehicleId);
            log.info("Vehicle deleted with ID: " + vehicleId);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            log.log(Level.SEVERE, "Failed to delete vehicle: " + e.getMessage(), e);
            if (e.getMessage().contains("Vehicle not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @DeleteMapping("/license-plate/{licensePlate}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        try {
            vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
            log.info("Vehicle(s) deleted with license plate: " + licensePlate);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            log.log(Level.SEVERE, "Failed to delete vehicle by license plate: " + e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/exists/{licensePlate}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<Boolean> isLicensePlateExists(@PathVariable String licensePlate) {
        try {
            boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
            return ResponseEntity.ok(exists);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid license plate: " + licensePlate);
            return ResponseEntity.badRequest().body(false);
        }
    }
}