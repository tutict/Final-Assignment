package com.tutict.finalassignmentcloud.ai.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.List;
import java.util.Map;

@FeignClient(name = "finalassignmentcloud-traffic")
public interface TrafficClient {
    @GetMapping("/api/offenses")
    List<Map<String, Object>> offenses();

    @GetMapping("/api/offenses/driver/{driverId}")
    List<Map<String, Object>> offensesByDriver(@PathVariable("driverId") Long driverId);

    @PostMapping("/api/offenses")
    Map<String, Object> createOffense(@RequestBody Map<String, Object> body);

    @GetMapping("/api/fines")
    List<Map<String, Object>> fines();

    @GetMapping("/api/fines/{fineId}")
    Map<String, Object> fine(@PathVariable("fineId") Long fineId);

    @GetMapping("/api/fines/driver/{driverId}")
    List<Map<String, Object>> finesByDriver(@PathVariable("driverId") Long driverId);

    @PostMapping("/api/fines")
    Map<String, Object> createFine(@RequestBody Map<String, Object> body);

    @GetMapping("/api/appeals")
    List<Map<String, Object>> appeals();

    @GetMapping("/api/appeals/driver/{driverId}")
    List<Map<String, Object>> appealsByDriver(@PathVariable("driverId") Long driverId);

    @PostMapping("/api/appeals")
    Map<String, Object> createAppeal(@RequestBody Map<String, Object> body);

    @PostMapping("/api/appeals/{appealId}/reviews")
    Map<String, Object> reviewAppeal(@PathVariable("appealId") Long appealId, @RequestBody Map<String, Object> body);

    @GetMapping("/api/vehicles")
    List<Map<String, Object>> vehicles();

    @GetMapping("/api/vehicles/drivers/{driverId}/vehicles")
    List<Map<String, Object>> vehiclesByDriver(@PathVariable("driverId") Long driverId);

    @PostMapping("/api/vehicles/{vehicleId}/drivers")
    Map<String, Object> bindVehicle(@PathVariable("vehicleId") Long vehicleId, @RequestBody Map<String, Object> body);

    @GetMapping("/api/drivers")
    List<Map<String, Object>> drivers();

    @GetMapping("/api/drivers/{driverId}")
    Map<String, Object> driver(@PathVariable("driverId") Long driverId);

    @PutMapping("/api/drivers/{driverId}")
    Map<String, Object> updateDriver(@PathVariable("driverId") Long driverId, @RequestBody Map<String, Object> body);

    @GetMapping("/api/progress")
    List<Map<String, Object>> progress();

    @PostMapping("/api/deductions")
    Map<String, Object> createDeduction(@RequestBody Map<String, Object> body);

    @PostMapping("/api/payments")
    Map<String, Object> createPayment(@RequestBody Map<String, Object> body);
}
