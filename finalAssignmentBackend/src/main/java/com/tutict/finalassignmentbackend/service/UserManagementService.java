package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.UserManagementMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserManagementService {

    private final UserManagementMapper userManagementMapper;

    @Autowired
    public UserManagementService(UserManagementMapper userManagementMapper) {
        this.userManagementMapper = userManagementMapper;
    }
}
