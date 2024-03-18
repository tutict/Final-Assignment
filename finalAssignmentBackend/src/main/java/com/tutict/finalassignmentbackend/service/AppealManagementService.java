package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.AppealManagementMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AppealManagementService {

    private final AppealManagementMapper appealManagementMapper;

    @Autowired
    public AppealManagementService(AppealManagementMapper appealManagementMapper) {
        this.appealManagementMapper = appealManagementMapper;
    }

    public List<AppealManagement> getAllAppeals(){
        return appealManagementMapper.getAllAppeals();
    }

}
