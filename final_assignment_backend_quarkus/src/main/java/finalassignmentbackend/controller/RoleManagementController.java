package finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.service.RoleManagementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/eventbus/roles")
public class RoleManagementController {

    private final RoleManagementService roleManagementService;

    @Autowired
    public RoleManagementController(RoleManagementService roleManagementService) {
        this.roleManagementService = roleManagementService;
    }

    @PostMapping
    public ResponseEntity<Void> createRole(@RequestBody RoleManagement role) {
        roleManagementService.createRole(role);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/{roleId}")
    public ResponseEntity<RoleManagement> getRoleById(@PathVariable int roleId) {
        RoleManagement role = roleManagementService.getRoleById(roleId);
        if (role != null) {
            return ResponseEntity.ok(role);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<RoleManagement>> getAllRoles() {
        List<RoleManagement> roles = roleManagementService.getAllRoles();
        return ResponseEntity.ok(roles);
    }

    @GetMapping("/name/{roleName}")
    public ResponseEntity<RoleManagement> getRoleByName(@PathVariable String roleName) {
        RoleManagement role = roleManagementService.getRoleByName(roleName);
        if (role != null) {
            return ResponseEntity.ok(role);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/search")
    public ResponseEntity<List<RoleManagement>> getRolesByNameLike(@RequestParam("name") String roleName) {
        List<RoleManagement> roles = roleManagementService.getRolesByNameLike(roleName);
        return ResponseEntity.ok(roles);
    }

    @PutMapping("/{roleId}")
    public ResponseEntity<Void> updateRole(@PathVariable int roleId, @RequestBody RoleManagement updatedRole) {
        RoleManagement existingRole = roleManagementService.getRoleById(roleId);
        if (existingRole != null) {
            updatedRole.setRoleId(roleId);
            roleManagementService.updateRole(updatedRole);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{roleId}")
    public ResponseEntity<Void> deleteRole(@PathVariable int roleId) {
        roleManagementService.deleteRole(roleId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/name/{roleName}")
    public ResponseEntity<Void> deleteRoleByName(@PathVariable String roleName) {
        roleManagementService.deleteRoleByName(roleName);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{roleId}/permissions")
    public ResponseEntity<String> getPermissionListByRoleId(@PathVariable int roleId) {
        String permissionList = roleManagementService.getPermissionListByRoleId(roleId);
        if (permissionList != null) {
            return ResponseEntity.ok(permissionList);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}