package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;
import java.util.logging.Level;

@RestController
@RequestMapping("/api/offenses")
public class OffenseInformationController {

    private static final Logger logger = Logger.getLogger(OffenseInformationController.class.getName());

    private final OffenseInformationService offenseInformationService;

    public OffenseInformationController(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    // 创建新的违法行为信息 (仅 ADMIN)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> createOffense(
            @RequestBody OffenseInformation offenseInformation,
            @RequestParam String idempotencyKey) {
        try {
            offenseInformationService.checkAndInsertIdempotency(idempotencyKey, offenseInformation, "create");
            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(null); // Duplicate request or DB error
        }
    }

    // 根据违法行为ID获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/{offenseId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<OffenseInformation> getOffenseByOffenseId(@PathVariable int offenseId) {
        try {
            OffenseInformation offenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
            if (offenseInformation != null) {
                return ResponseEntity.ok(offenseInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    // 获取所有违法行为的信息 (USER 和 ADMIN)
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> getOffensesInformation() {
        List<OffenseInformation> offensesInformation = offenseInformationService.getOffensesInformation();
        return ResponseEntity.ok(offensesInformation);
    }

    // 更新指定违法行为的信息 (仅 ADMIN)
    @PutMapping("/{offenseId}")
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<OffenseInformation> updateOffense(
            @PathVariable int offenseId,
            @RequestBody OffenseInformation updatedOffenseInformation,
            @RequestParam String idempotencyKey) {
        try {
            OffenseInformation existingOffenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
            if (existingOffenseInformation != null) {
                updatedOffenseInformation.setOffenseId(offenseId);
                offenseInformationService.checkAndInsertIdempotency(idempotencyKey, updatedOffenseInformation, "update");
                return ResponseEntity.ok(updatedOffenseInformation);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build(); // Duplicate request or DB error
        }
    }

    // 删除指定违法行为的信息 (仅 ADMIN)
    @DeleteMapping("/{offenseId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteOffense(@PathVariable int offenseId) {
        try {
            offenseInformationService.deleteOffense(offenseId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // 根据时间范围获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/timeRange")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> getOffensesByTimeRange(
            @RequestParam(defaultValue = "1970-01-01") Date startTime,
            @RequestParam(defaultValue = "2100-01-01") Date endTime) {
        try {
            List<OffenseInformation> offenses = offenseInformationService.getOffensesByTimeRange(startTime, endTime);
            return ResponseEntity.ok(offenses);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/by-offense-type")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> searchByOffenseType(
            @RequestParam String query,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        logger.log(Level.INFO, "Received request to search offenses by offense type: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        try {
            List<OffenseInformation> results = offenseInformationService.searchOffenseType(query, page, size);

            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No offenses found for offense type: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }

            logger.log(Level.INFO, "Returning {0} offenses for offense type: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for offense type search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by offense type: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    // 根据司机姓名获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/by-driver-name")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> searchByDriverName(
            @RequestParam String query,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        logger.log(Level.INFO, "Received request to search offenses by driver name: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        try {
            List<OffenseInformation> results = offenseInformationService.searchByDriverName(query, page, size);

            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No offenses found for driver name: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }

            logger.log(Level.INFO, "Returning {0} offenses for driver name: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for driver name search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by driver name: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }

    // 根据车牌号获取违法行为信息 (USER 和 ADMIN)
    @GetMapping("/by-license-plate")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public ResponseEntity<List<OffenseInformation>> searchByLicensePlate(
            @RequestParam String query,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        logger.log(Level.INFO, "Received request to search offenses by license plate: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        try {
            List<OffenseInformation> results = offenseInformationService.searchLicensePlate(query, page, size);

            if (results == null || results.isEmpty()) {
                logger.log(Level.INFO, "No offenses found for license plate: {0}", new Object[]{query});
                return ResponseEntity.noContent().build();
            }

            logger.log(Level.INFO, "Returning {0} offenses for license plate: {1}",
                    new Object[]{results.size(), query});
            return ResponseEntity.ok(results);
        } catch (IllegalArgumentException e) {
            logger.log(Level.WARNING, "Invalid pagination parameters for license plate search: {0}", new Object[]{e.getMessage()});
            return ResponseEntity.badRequest().body(null);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error processing search by license plate: {0}, error: {1}",
                    new Object[]{query, e.getMessage()});
            return ResponseEntity.status(500).body(null);
        }
    }
}