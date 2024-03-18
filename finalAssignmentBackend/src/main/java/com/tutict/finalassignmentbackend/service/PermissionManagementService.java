package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.PermissionManagementMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PermissionManagementService {

    private final PermissionManagementMapper permissionManagementMapper;

    @Autowired
    public PermissionManagementService(PermissionManagementMapper permissionManagementMapper) {
        this.permissionManagementMapper = permissionManagementMapper;
    }
}
