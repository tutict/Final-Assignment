package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.utils.GaoDeGeocoder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/eventbus/")
public class LocationController {

//    @Autowired
    @Autowired
    private GaoDeGeocoder gaoDeGeocoder;

//    @PostMapping("/location")
    @PostMapping("/location")
    public String handleLocation(@RequestBody Map<String, Object> locationData) throws Exception {

        double longitude = (double) locationData.get("laitude");
        double latitude = (double) locationData.get("longitude");

        String address = gaoDeGeocoder.getAddress(longitude, latitude);

        return "你的地址是" + address;
    }
}
