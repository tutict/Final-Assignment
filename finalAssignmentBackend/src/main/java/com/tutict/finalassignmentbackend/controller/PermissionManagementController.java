package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.service.PermissionManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/permissions")
public class PermissionManagementController {

    private final PermissionManagementService permissionManagementService;

    @Autowired
    public PermissionManagementController(PermissionManagementService permissionManagementService) {
        this.permissionManagementService = permissionManagementService;
    }

    @PostMapping
    public ResponseEntity<Void> createPermission(@RequestBody PermissionManagement permission) {
        permissionManagementService.createPermission(permission);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{permissionId}")
    public ResponseEntity<PermissionManagement> getPermissionById(@PathVariable int permissionId) {
        PermissionManagement permission = permissionManagementService.getPermissionById(permissionId);
        if (permission != null) {
            return ResponseEntity.ok(permission);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<PermissionManagement>> getAllPermissions() {
        List<PermissionManagement> permissions = permissionManagementService.getAllPermissions();
        return ResponseEntity.ok(permissions);
    }

    @GetMapping("/name/{permissionName}")
    public ResponseEntity<PermissionManagement> getPermissionByName(@PathVariable String permissionName) {
        PermissionManagement permission = permissionManagementService.getPermissionByName(permissionName);
        if (permission != null) {
            return ResponseEntity.ok(permission);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/search")
    public ResponseEntity<List<PermissionManagement>> getPermissionsByNameLike(@RequestParam("name") String permissionName) {
        List<PermissionManagement> permissions = permissionManagementService.getPermissionsByNameLike(permissionName);
        return ResponseEntity.ok(permissions);
    }

    @PutMapping("/{permissionId}")
    public ResponseEntity<Void> updatePermission(@PathVariable int permissionId, @RequestBody PermissionManagement updatedPermission) {
        PermissionManagement existingPermission = permissionManagementService.getPermissionById(permissionId);
        if (existingPermission != null) {
            updatedPermission.setPermissionId(permissionId);
            permissionManagementService.updatePermission(updatedPermission);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{permissionId}")
    public ResponseEntity<Void> deletePermission(@PathVariable int permissionId) {
        permissionManagementService.deletePermission(permissionId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/name/{permissionName}")
    public ResponseEntity<Void> deletePermissionByName(@PathVariable String permissionName) {
        permissionManagementService.deletePermissionByName(permissionName);
        return ResponseEntity.noContent().build();
    }
}