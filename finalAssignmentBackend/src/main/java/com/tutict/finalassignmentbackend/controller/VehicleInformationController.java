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
            @RequestParam String idCardNumber) {
        Logger log = Logger.getLogger(this.getClass().getName());
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        log.log(Level.INFO, "Fetching license plate suggestions for user: {0}, prefix: {1}, maxSuggestions: {2}, idCardNumber: {3}",
                new Object[]{currentUsername, prefix, maxSuggestions, idCardNumber});

        // 验证 idCardNumber
        if (idCardNumber == null || idCardNumber.trim().isEmpty()) {
            log.log(Level.WARNING, "Invalid idCardNumber provided for user: {0}", new Object[]{currentUsername});
            return ResponseEntity.badRequest().body(List.of());
        }

        // 解码 prefix 和 idCardNumber
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        String decodedIdCardNumber = URLDecoder.decode(idCardNumber, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Decoded prefix: {0}, idCardNumber: {1}", new Object[]{decodedPrefix, decodedIdCardNumber});

        List<String> suggestions = vehicleInformationService.getLicensePlateAutocompleteSuggestions(
                decodedIdCardNumber, decodedPrefix, maxSuggestions);

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No license plate suggestions found for prefix: {0} with idCardNumber: {1} for user: {2}",
                    new Object[]{decodedPrefix, decodedIdCardNumber, currentUsername});
        }
        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/vehicle-type/me")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<String>> getVehicleTypeAutocompleteSuggestions(
            @RequestParam String prefix,
            @RequestParam(defaultValue = "5") int maxSuggestions,
            @RequestParam String idCardNumber) {
        Logger log = Logger.getLogger(this.getClass().getName());
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        log.log(Level.INFO, "Fetching vehicle type suggestions for user: {0}, prefix: {1}, maxSuggestions: {2}, idCardNumber: {3}",
                new Object[]{currentUsername, prefix, maxSuggestions, idCardNumber});

        // 验证 idCardNumber
        if (idCardNumber == null || idCardNumber.trim().isEmpty()) {
            log.log(Level.WARNING, "Invalid idCardNumber provided for user: {0}", new Object[]{currentUsername});
            return ResponseEntity.badRequest().body(List.of());
        }

        // 解码 prefix 和 idCardNumber
        String decodedPrefix = URLDecoder.decode(prefix, StandardCharsets.UTF_8);
        String decodedIdCardNumber = URLDecoder.decode(idCardNumber, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Decoded prefix: {0}, idCardNumber: {1}", new Object[]{decodedPrefix, decodedIdCardNumber});

        List<String> suggestions = vehicleInformationService.getVehicleTypeAutocompleteSuggestions(
                decodedIdCardNumber, decodedPrefix, maxSuggestions);

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No vehicle type suggestions found for prefix: {0} with idCardNumber: {1} for user: {2}",
                    new Object[]{decodedPrefix, decodedIdCardNumber, currentUsername});
        }
        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/license-plate-globally/me")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<String>> getLicensePlateAutocompleteSuggestionsGlobally(
            @RequestParam String licensePlate) {

        // Decode URL-encoded prefix
        String decodedPrefix = URLDecoder.decode(licensePlate, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching license plate suggestions for prefix: {0}, decoded: {1}",
                new Object[]{licensePlate, decodedPrefix});

        // Fetch suggestions, default to empty list if null
        List<String> suggestions = vehicleInformationService.getVehicleInformationByLicensePlateGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No license plate suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} license plate suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
        }

        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/autocomplete/vehicle-type-globally/me")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<String>> getVehicleTypeAutocompleteSuggestionsGlobally(
            @RequestParam String vehicleType) {

        // Decode URL-encoded prefix
        String decodedPrefix = URLDecoder.decode(vehicleType, StandardCharsets.UTF_8);
        log.log(Level.INFO, "Fetching vehicle type suggestions for prefix: {0}, decoded: {1}",
                new Object[]{vehicleType, decodedPrefix});

        // Fetch suggestions, default to empty list if null
        List<String> suggestions = vehicleInformationService.getVehicleTypesByPrefixGlobally(decodedPrefix);
        if (suggestions == null) {
            suggestions = Collections.emptyList();
        }

        if (suggestions.isEmpty()) {
            log.log(Level.INFO, "No vehicle type suggestions found for prefix: {0}", new Object[]{decodedPrefix});
        } else {
            log.log(Level.INFO, "Found {0} vehicle type suggestions for prefix: {1}",
                    new Object[]{suggestions.size(), decodedPrefix});
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

    @GetMapping("/id-card-number/{idCardNumber}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByIdCardNumber(@PathVariable String idCardNumber) {
        try {
            List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByIdCardNumber(idCardNumber);
            return ResponseEntity.ok(vehicleInformationList);
        } catch (IllegalArgumentException e) {
            log.warning("Invalid ID card number: " + idCardNumber);
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