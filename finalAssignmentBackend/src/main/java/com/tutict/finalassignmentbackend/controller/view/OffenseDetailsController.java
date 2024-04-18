package com.tutict.finalassignmentbackend.controller.view;

import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import com.tutict.finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/offense-details")
public class OffenseDetailsController {

    private final OffenseDetailsMapper offenseDetailsMapper;

    public OffenseDetailsController(OffenseDetailsMapper offenseDetailsMapper) {
        this.offenseDetailsMapper = offenseDetailsMapper;
    }

    @GetMapping
    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    @GetMapping("/{id}")
    public OffenseDetails getOffenseDetailsById(@PathVariable Integer id) {
        return offenseDetailsMapper.selectById(id);
    }
}