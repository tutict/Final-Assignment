package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.service.FineInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/fines")
public class FineInformationController {

    private final FineInformationService fineInformationService;

    @Autowired
    public FineInformationController(FineInformationService fineInformationService) {
        this.fineInformationService = fineInformationService;
    }
}
