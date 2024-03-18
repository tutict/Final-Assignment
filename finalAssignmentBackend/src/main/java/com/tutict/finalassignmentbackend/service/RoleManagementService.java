package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.RoleManagementMapper;
import lombok.experimental.Accessors;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RoleManagementService {

    private final RoleManagementMapper roleManagementMapper;

    @Autowired
    public RoleManagementService(RoleManagementMapper roleManagementMapper) {
        this.roleManagementMapper = roleManagementMapper;
    }
}

