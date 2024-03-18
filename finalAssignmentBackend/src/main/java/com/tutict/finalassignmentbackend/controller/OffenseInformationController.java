package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.service.OffenseInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/offenses")
public class OffenseInformationController {

    private final OffenseInformationService offenseInformationService;

    @Autowired
    public OffenseInformationController(OffenseInformationService offenseInformationService) {
        this.offenseInformationService = offenseInformationService;
    }

    @GetMapping
    public List<OffenseInformation> getAllOffenses() {
        return offenseInformationService.getAllOffenses();
    }

    @GetMapping("/{offenseId}")
    public OffenseInformation getOffenseById(@PathVariable Long offenseId) {
        return offenseInformationService.getOffenseById(offenseId);
    }

    @PostMapping
    public OffenseInformation saveOffense(@RequestBody OffenseInformation offenseInformation) {
        offenseInformationService.saveOffense(offenseInformation);
        return offenseInformation;
    }

    @DeleteMapping("/{offenseId}")
    public void deleteOffense(@PathVariable Long offenseId) {
        offenseInformationService.deleteOffense(offenseId);
    }
}
