package contract

import "net/http"

func AdminRouteSpecs() []RouteSpec {
	routes := []RouteSpec{}
	routes = append(routes, UserManagementRouteSpecs()...)
	routes = append(routes, RoleManagementRouteSpecs()...)
	routes = append(routes, PermissionManagementRouteSpecs()...)
	routes = append(routes, SystemSettingsRouteSpecs()...)
	routes = append(routes, BackupRestoreRouteSpecs()...)
	return routes
}

func UserManagementRouteSpecs() []RouteSpec {
	return []RouteSpec{
		userRoute(http.MethodPost, "/api/users", "createUser", "@PostMapping"),
		userRoute(http.MethodGet, "/api/users", "listUsers", "@GetMapping"),
		userRoute(http.MethodGet, "/api/users/search/username/:username", "getByUsername", `@GetMapping("/search/username/{username}")`),
		userRoute(http.MethodGet, "/api/users/search/username/prefix", "searchByUsernamePrefix", `@GetMapping("/search/username/prefix")`),
		userRoute(http.MethodGet, "/api/users/search/username/fuzzy", "searchByUsernameFuzzy", `@GetMapping("/search/username/fuzzy")`),
		userRoute(http.MethodGet, "/api/users/search/real-name/prefix", "searchByRealNamePrefix", `@GetMapping("/search/real-name/prefix")`),
		userRoute(http.MethodGet, "/api/users/search/real-name/fuzzy", "searchByRealNameFuzzy", `@GetMapping("/search/real-name/fuzzy")`),
		userRoute(http.MethodGet, "/api/users/search/id-card", "searchByIdCard", `@GetMapping("/search/id-card")`),
		userRoute(http.MethodGet, "/api/users/search/contact", "searchByContact", `@GetMapping("/search/contact")`),
		userRoute(http.MethodGet, "/api/users/search/status", "listByStatus", `@GetMapping("/search/status")`),
		userRoute(http.MethodGet, "/api/users/search/department", "listByDepartment", `@GetMapping("/search/department")`),
		userRoute(http.MethodGet, "/api/users/search/department/prefix", "searchByDepartmentPrefix", `@GetMapping("/search/department/prefix")`),
		userRoute(http.MethodGet, "/api/users/search/employee-number", "searchByEmployeeNumber", `@GetMapping("/search/employee-number")`),
		userRoute(http.MethodGet, "/api/users/search/last-login-range", "searchByLastLoginRange", `@GetMapping("/search/last-login-range")`),
		userRoute(http.MethodDelete, "/api/users/roles/:relationId", "deleteUserRole", `@DeleteMapping("/roles/{relationId}")`),
		userRoute(http.MethodPut, "/api/users/role-bindings/:relationId", "updateUserRole", `@PutMapping("/role-bindings/{relationId}")`),
		userRoute(http.MethodGet, "/api/users/role-bindings/:relationId", "getUserRole", `@GetMapping("/role-bindings/{relationId}")`),
		userRoute(http.MethodGet, "/api/users/role-bindings", "listRoleBindings", `@GetMapping("/role-bindings")`),
		userRoute(http.MethodGet, "/api/users/role-bindings/by-role/:roleId", "listBindingsByRole", `@GetMapping("/role-bindings/by-role/{roleId}")`),
		userRoute(http.MethodGet, "/api/users/role-bindings/search", "searchBindings", `@GetMapping("/role-bindings/search")`),
		userRoute(http.MethodPut, "/api/users/:userId", "updateUser", `@PutMapping("/{userId}")`),
		userRoute(http.MethodDelete, "/api/users/:userId", "deleteUser", `@DeleteMapping("/{userId}")`),
		userRoute(http.MethodGet, "/api/users/:userId", "getUser", `@GetMapping("/{userId}")`),
		userRoute(http.MethodPost, "/api/users/:userId/roles", "addUserRole", `@PostMapping("/{userId}/roles")`),
		userRoute(http.MethodGet, "/api/users/:userId/roles", "listUserRoles", `@GetMapping("/{userId}/roles")`),
	}
}

func RoleManagementRouteSpecs() []RouteSpec {
	return []RouteSpec{
		roleRoute(http.MethodPost, "/api/roles", "createRole", "@PostMapping"),
		roleRoute(http.MethodGet, "/api/roles", "listRoles", "@GetMapping"),
		roleRoute(http.MethodGet, "/api/roles/by-code/:roleCode", "getByRoleCode", `@GetMapping("/by-code/{roleCode}")`),
		roleRoute(http.MethodGet, "/api/roles/search/code/prefix", "searchByRoleCodePrefix", `@GetMapping("/search/code/prefix")`),
		roleRoute(http.MethodGet, "/api/roles/name/:roleName", "getRoleByName", `@GetMapping("/name/{roleName}")`),
		roleRoute(http.MethodDelete, "/api/roles/name/:roleName", "deleteRoleByName", `@DeleteMapping("/name/{roleName}")`),
		roleRoute(http.MethodGet, "/api/roles/search", "searchRoles", `@GetMapping("/search")`),
		roleRoute(http.MethodGet, "/api/roles/search/code/fuzzy", "searchByRoleCodeFuzzy", `@GetMapping("/search/code/fuzzy")`),
		roleRoute(http.MethodGet, "/api/roles/search/name/prefix", "searchByRoleNamePrefix", `@GetMapping("/search/name/prefix")`),
		roleRoute(http.MethodGet, "/api/roles/search/name/fuzzy", "searchByRoleNameFuzzy", `@GetMapping("/search/name/fuzzy")`),
		roleRoute(http.MethodGet, "/api/roles/search/type", "findByRoleType", `@GetMapping("/search/type")`),
		roleRoute(http.MethodGet, "/api/roles/search/data-scope", "findByDataScope", `@GetMapping("/search/data-scope")`),
		roleRoute(http.MethodGet, "/api/roles/search/status", "findByStatus", `@GetMapping("/search/status")`),
		roleRoute(http.MethodDelete, "/api/roles/permissions/:relationId", "deleteRolePermission", `@DeleteMapping("/permissions/{relationId}")`),
		roleRoute(http.MethodPut, "/api/roles/permissions/:relationId", "updateRolePermission", `@PutMapping("/permissions/{relationId}")`),
		roleRoute(http.MethodGet, "/api/roles/permissions/:relationId", "getRolePermission", `@GetMapping("/permissions/{relationId}")`),
		roleRoute(http.MethodGet, "/api/roles/permissions", "listRolePermissions", `@GetMapping("/permissions")`),
		roleRoute(http.MethodGet, "/api/roles/permissions/by-permission/:permissionId", "listRolePermissionsByPermission", `@GetMapping("/permissions/by-permission/{permissionId}")`),
		roleRoute(http.MethodGet, "/api/roles/permissions/search", "searchRolePermissions", `@GetMapping("/permissions/search")`),
		roleRoute(http.MethodPut, "/api/roles/:roleId", "updateRole", `@PutMapping("/{roleId}")`),
		roleRoute(http.MethodDelete, "/api/roles/:roleId", "deleteRole", `@DeleteMapping("/{roleId}")`),
		roleRoute(http.MethodGet, "/api/roles/:roleId", "getRole", `@GetMapping("/{roleId}")`),
		roleRoute(http.MethodPost, "/api/roles/:roleId/permissions", "addRolePermission", `@PostMapping("/{roleId}/permissions")`),
		roleRoute(http.MethodGet, "/api/roles/:roleId/permissions", "listRolePermissionsByRole", `@GetMapping("/{roleId}/permissions")`),
	}
}

func PermissionManagementRouteSpecs() []RouteSpec {
	return []RouteSpec{
		permissionRoute(http.MethodPost, "/api/permissions", "createPermission", "@PostMapping"),
		permissionRoute(http.MethodGet, "/api/permissions", "listPermissions", "@GetMapping"),
		permissionRoute(http.MethodGet, "/api/permissions/parent/:parentId", "listByParent", `@GetMapping("/parent/{parentId}")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/code/prefix", "searchByPermissionCodePrefix", `@GetMapping("/search/code/prefix")`),
		permissionRoute(http.MethodGet, "/api/permissions/name/:permissionName", "getByPermissionName", `@GetMapping("/name/{permissionName}")`),
		permissionRoute(http.MethodDelete, "/api/permissions/name/:permissionName", "deleteByPermissionName", `@DeleteMapping("/name/{permissionName}")`),
		permissionRoute(http.MethodGet, "/api/permissions/search", "searchPermissions", `@GetMapping("/search")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/code/fuzzy", "searchByPermissionCodeFuzzy", `@GetMapping("/search/code/fuzzy")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/name/prefix", "searchByPermissionNamePrefix", `@GetMapping("/search/name/prefix")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/name/fuzzy", "searchByPermissionNameFuzzy", `@GetMapping("/search/name/fuzzy")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/type", "findByPermissionType", `@GetMapping("/search/type")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/api-path", "findByApiPath", `@GetMapping("/search/api-path")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/menu-path", "findByMenuPath", `@GetMapping("/search/menu-path")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/visible", "findByVisible", `@GetMapping("/search/visible")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/external", "findByExternal", `@GetMapping("/search/external")`),
		permissionRoute(http.MethodGet, "/api/permissions/search/status", "findByPermissionStatus", `@GetMapping("/search/status")`),
		permissionRoute(http.MethodPut, "/api/permissions/:permissionId", "updatePermission", `@PutMapping("/{permissionId}")`),
		permissionRoute(http.MethodDelete, "/api/permissions/:permissionId", "deletePermission", `@DeleteMapping("/{permissionId}")`),
		permissionRoute(http.MethodGet, "/api/permissions/:permissionId", "getPermission", `@GetMapping("/{permissionId}")`),
	}
}

func SystemSettingsRouteSpecs() []RouteSpec {
	return []RouteSpec{
		settingsRoute(http.MethodPost, "/api/system/settings", "createSetting", "@PostMapping"),
		settingsRoute(http.MethodGet, "/api/system/settings", "listSettings", "@GetMapping"),
		settingsRoute(http.MethodGet, "/api/system/settings/key/:settingKey", "getBySettingKey", `@GetMapping("/key/{settingKey}")`),
		settingsRoute(http.MethodGet, "/api/system/settings/category/:category", "listByCategory", `@GetMapping("/category/{category}")`),
		settingsRoute(http.MethodGet, "/api/system/settings/search/key/prefix", "searchSettingKeyPrefix", `@GetMapping("/search/key/prefix")`),
		settingsRoute(http.MethodGet, "/api/system/settings/search/key/fuzzy", "searchSettingKeyFuzzy", `@GetMapping("/search/key/fuzzy")`),
		settingsRoute(http.MethodGet, "/api/system/settings/search/type", "searchSettingsByType", `@GetMapping("/search/type")`),
		settingsRoute(http.MethodGet, "/api/system/settings/search/editable", "searchSettingsByEditable", `@GetMapping("/search/editable")`),
		settingsRoute(http.MethodGet, "/api/system/settings/search/encrypted", "searchSettingsByEncrypted", `@GetMapping("/search/encrypted")`),
		settingsRoute(http.MethodPost, "/api/system/settings/dicts", "createDict", `@PostMapping("/dicts")`),
		settingsRoute(http.MethodGet, "/api/system/settings/dicts", "listDicts", `@GetMapping("/dicts")`),
		settingsRoute(http.MethodGet, "/api/system/settings/dicts/search/type", "searchDictsByType", `@GetMapping("/dicts/search/type")`),
		settingsRoute(http.MethodGet, "/api/system/settings/dicts/search/code", "searchDictsByCode", `@GetMapping("/dicts/search/code")`),
		settingsRoute(http.MethodGet, "/api/system/settings/dicts/search/label/prefix", "searchDictLabelPrefix", `@GetMapping("/dicts/search/label/prefix")`),
		settingsRoute(http.MethodGet, "/api/system/settings/dicts/search/label/fuzzy", "searchDictLabelFuzzy", `@GetMapping("/dicts/search/label/fuzzy")`),
		settingsRoute(http.MethodGet, "/api/system/settings/dicts/search/parent", "searchDictsByParent", `@GetMapping("/dicts/search/parent")`),
		settingsRoute(http.MethodGet, "/api/system/settings/dicts/search/default", "searchDefaultDicts", `@GetMapping("/dicts/search/default")`),
		settingsRoute(http.MethodGet, "/api/system/settings/dicts/search/status", "searchDictsByStatus", `@GetMapping("/dicts/search/status")`),
		settingsRoute(http.MethodPut, "/api/system/settings/dicts/:dictId", "updateDict", `@PutMapping("/dicts/{dictId}")`),
		settingsRoute(http.MethodDelete, "/api/system/settings/dicts/:dictId", "deleteDict", `@DeleteMapping("/dicts/{dictId}")`),
		settingsRoute(http.MethodGet, "/api/system/settings/dicts/:dictId", "getDict", `@GetMapping("/dicts/{dictId}")`),
		settingsRoute(http.MethodPut, "/api/system/settings/:settingId", "updateSetting", `@PutMapping("/{settingId}")`),
		settingsRoute(http.MethodDelete, "/api/system/settings/:settingId", "deleteSetting", `@DeleteMapping("/{settingId}")`),
		settingsRoute(http.MethodGet, "/api/system/settings/:settingId", "getSetting", `@GetMapping("/{settingId}")`),
	}
}

func BackupRestoreRouteSpecs() []RouteSpec {
	return []RouteSpec{
		backupRoute(http.MethodPost, "/api/system/backup", "createBackup", "@PostMapping"),
		backupRoute(http.MethodGet, "/api/system/backup", "listBackups", "@GetMapping"),
		backupRoute(http.MethodGet, "/api/system/backup/search/type", "searchByBackupType", `@GetMapping("/search/type")`),
		backupRoute(http.MethodGet, "/api/system/backup/search/file-name", "searchByFileName", `@GetMapping("/search/file-name")`),
		backupRoute(http.MethodGet, "/api/system/backup/search/handler", "searchByHandler", `@GetMapping("/search/handler")`),
		backupRoute(http.MethodGet, "/api/system/backup/search/restore-status", "searchByRestoreStatus", `@GetMapping("/search/restore-status")`),
		backupRoute(http.MethodGet, "/api/system/backup/search/status", "searchByStatus", `@GetMapping("/search/status")`),
		backupRoute(http.MethodGet, "/api/system/backup/search/backup-time-range", "searchByBackupTimeRange", `@GetMapping("/search/backup-time-range")`),
		backupRoute(http.MethodGet, "/api/system/backup/search/restore-time-range", "searchByRestoreTimeRange", `@GetMapping("/search/restore-time-range")`),
		backupRoute(http.MethodPut, "/api/system/backup/:backupId", "updateBackup", `@PutMapping("/{backupId}")`),
		backupRoute(http.MethodDelete, "/api/system/backup/:backupId", "deleteBackup", `@DeleteMapping("/{backupId}")`),
		backupRoute(http.MethodGet, "/api/system/backup/:backupId", "getBackup", `@GetMapping("/{backupId}")`),
	}
}

func userRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "user-management", operation, "UserManagementController", mapping)
}

func roleRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "roles", operation, "RoleManagementController", mapping)
}

func permissionRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "permissions", operation, "PermissionManagementController", mapping)
}

func settingsRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "system-settings", operation, "SystemSettingsController", mapping)
}

func backupRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "backup-restore", operation, "BackupRestoreController", mapping)
}
