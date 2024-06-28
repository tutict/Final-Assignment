package finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/eventbus/vehicles")
public class VehicleInformationController {

    private final VehicleInformationService vehicleInformationService;

    @Autowired
    public VehicleInformationController(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    // Create a new vehicle
    @PostMapping
    public ResponseEntity<Void> createVehicleInformation(@RequestBody VehicleInformation vehicleInformation) {
        vehicleInformationService.createVehicleInformation(vehicleInformation);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // Get a vehicle by ID
    @GetMapping("/{vehicleId}")
    public ResponseEntity<VehicleInformation> getVehicleInformationById(@PathVariable int vehicleId) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationById(vehicleId);
        if (vehicleInformation != null) {
            return ResponseEntity.ok(vehicleInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // Get a vehicle by license plate
    @GetMapping("/license-plate/{licensePlate}")
    public ResponseEntity<VehicleInformation> getVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
        if (vehicleInformation != null) {
            return ResponseEntity.ok(vehicleInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // Get all vehicles
    @GetMapping
    public ResponseEntity<List<VehicleInformation>> getAllVehicleInformation() {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getAllVehicleInformation();
        return ResponseEntity.ok(vehicleInformationList);
    }

    // Get a vehicle by type
    @GetMapping("/type/{vehicleType}")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByType(@PathVariable String vehicleType) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByType(vehicleType);
        return ResponseEntity.ok(vehicleInformationList);
    }

    // Get a vehicle by owner name
    @GetMapping("/owner/{ownerName}")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByOwnerName(@PathVariable String ownerName) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByOwnerName(ownerName);
        return ResponseEntity.ok(vehicleInformationList);
    }

    // Get a vehicle by status
    @GetMapping("/status/{currentStatus}")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByStatus(@PathVariable String currentStatus) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByStatus(currentStatus);
        return ResponseEntity.ok(vehicleInformationList);
    }

    // Update a vehicle
    @PutMapping("/{vehicleId}")
    public ResponseEntity<Void> updateVehicleInformation(@PathVariable int vehicleId, @RequestBody VehicleInformation vehicleInformation) {
        vehicleInformation.setVehicleId(vehicleId);
        vehicleInformationService.updateVehicleInformation(vehicleInformation);
        return ResponseEntity.ok().build();
    }

    // Delete a vehicle by ID
    @DeleteMapping("/{vehicleId}")
    public ResponseEntity<Void> deleteVehicleInformation(@PathVariable int vehicleId) {
        vehicleInformationService.deleteVehicleInformation(vehicleId);
        return ResponseEntity.noContent().build();
    }

    // Delete a vehicle by license plate
    @DeleteMapping("/license-plate/{licensePlate}")
    public ResponseEntity<Void> deleteVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
        return ResponseEntity.noContent().build();
    }

    // Check if a vehicle exists
    @GetMapping("/exists/{licensePlate}")
    public ResponseEntity<Boolean> isLicensePlateExists(@PathVariable String licensePlate) {
        boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
        return ResponseEntity.ok(exists);
    }
}

