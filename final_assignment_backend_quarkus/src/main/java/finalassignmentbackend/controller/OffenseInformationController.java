package finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/eventbus/offenses")
public class OffenseInformationController {

    private final OffenseInformationService offenseInformationService;

    @Autowired
    public OffenseInformationController(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    @PostMapping
    public ResponseEntity<Void> createOffense(@RequestBody OffenseInformation offenseInformation) {
        offenseInformationService.createOffense(offenseInformation);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{offenseId}")
    public ResponseEntity<OffenseInformation> getOffenseByOffenseId(@PathVariable int offenseId) {
        OffenseInformation offenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (offenseInformation != null) {
            return ResponseEntity.ok(offenseInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<OffenseInformation>> getOffensesInformation() {
        List<OffenseInformation> offensesInformation = offenseInformationService.getOffensesInformation();
        return ResponseEntity.ok(offensesInformation);
    }

    @PutMapping("/{offenseId}")
    public ResponseEntity<Void> updateOffense(@PathVariable int offenseId, @RequestBody OffenseInformation updatedOffenseInformation) {
        OffenseInformation existingOffenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (existingOffenseInformation != null) {
            updatedOffenseInformation.setOffenseId(offenseId);
            offenseInformationService.updateOffense(updatedOffenseInformation);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{offenseId}")
    public ResponseEntity<Void> deleteOffense(@PathVariable int offenseId) {
        offenseInformationService.deleteOffense(offenseId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/timeRange")
    public ResponseEntity<List<OffenseInformation>> getOffensesByTimeRange(
            @RequestParam("startTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date startTime,
            @RequestParam("endTime") @DateTimeFormat(pattern = "yyyy-MM-dd") Date endTime) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByTimeRange(startTime, endTime);
        return ResponseEntity.ok(offenses);
    }

    @GetMapping("/processState/{processState}")
    public ResponseEntity<List<OffenseInformation>> getOffensesByProcessState(@PathVariable String processState) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByProcessState(processState);
        return ResponseEntity.ok(offenses);
    }

    @GetMapping("/driverName/{driverName}")
    public ResponseEntity<List<OffenseInformation>> getOffensesByDriverName(@PathVariable String driverName) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByDriverName(driverName);
        return ResponseEntity.ok(offenses);
    }

    @GetMapping("/licensePlate/{licensePlate}")
    public ResponseEntity<List<OffenseInformation>> getOffensesByLicensePlate(@PathVariable String licensePlate) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByLicensePlate(licensePlate);
        return ResponseEntity.ok(offenses);
    }
}