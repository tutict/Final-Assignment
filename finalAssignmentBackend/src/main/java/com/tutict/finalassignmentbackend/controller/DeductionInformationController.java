package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.DeductionInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/deductions")
public class DeductionInformationController {

    private final DeductionInformationService deductionInformationService;

    @Autowired
    public DeductionInformationController(DeductionInformationService deductionInformationService) {
        this.deductionInformationService = deductionInformationService;
    }
}
