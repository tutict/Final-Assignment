package com.tutict.finalassignmentbackend.controller.view;

import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import com.tutict.finalassignmentbackend.service.view.OffenseDetailsService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/offense-details")
public class OffenseDetailsController {


    private final OffenseDetailsService offenseDetailsService;

    public OffenseDetailsController(OffenseDetailsService offenseDetailsService) {
        this.offenseDetailsService = offenseDetailsService;
    }

    // 获取所有违规详情记录
    @GetMapping
    public ResponseEntity<List<OffenseDetails>> getAllOffenseDetails() {
        List<OffenseDetails> offenseDetailsList = offenseDetailsService.getAllOffenseDetails();
        return ResponseEntity.ok(offenseDetailsList);
    }

    // 根据 ID 获取违规详情
    @GetMapping("/{id}")
    public ResponseEntity<OffenseDetails> getOffenseDetailsById(@PathVariable Integer id) {
        OffenseDetails offenseDetails = offenseDetailsService.getOffenseDetailsById(id);
        if (offenseDetails != null) {
            return ResponseEntity.ok(offenseDetails);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    // 将违规详情发送到 Kafka
    @PostMapping("/send-to-kafka/{id}")
    public ResponseEntity<String> updateOffenseDetailsToKafka(@PathVariable Integer id, @RequestParam String idempotencyKey) {
        OffenseDetails offenseDetails = offenseDetailsService.getOffenseDetailsById(id);
        if (offenseDetails != null) {
            offenseDetailsService.checkAndInsertIdempotency(idempotencyKey, offenseDetails);
            return ResponseEntity.ok("OffenseDetails sent to Kafka topic successfully!");
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("OffenseDetails not found for id: " + id);
        }
    }
}
