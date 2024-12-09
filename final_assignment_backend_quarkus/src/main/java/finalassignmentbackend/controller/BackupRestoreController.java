package finalassignmentbackend.controller;

import finalassignmentbackend.entity.BackupRestore;
import finalassignmentbackend.service.BackupRestoreService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;

// 控制器类，处理与事件总线备份相关的HTTP请求
@Path("/eventbus/backups")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class BackupRestoreController {

    // 备份恢复服务的依赖注入
    @Inject
    BackupRestoreService backupRestoreService;

    // 创建一个新备份
    // 接受一个BackupRestore对象作为请求体，创建备份并返回201状态码
    @POST
    @RunOnVirtualThread
    public Response createBackup(BackupRestore backup) {
        backupRestoreService.createBackup(backup);
        return Response.status(Response.Status.CREATED).build();
    }

    // 获取所有备份列表
    // 返回备份列表和200状态码
    @GET
    @RunOnVirtualThread
    public Response getAllBackups() {
        List<BackupRestore> backups = backupRestoreService.getAllBackups();
        return Response.ok(backups).build();
    }

    // 根据ID获取备份
    // 如果找到对应ID的备份，返回该备份和200状态码；否则返回404状态码
    @GET
    @Path("/{backupId}")
    @RunOnVirtualThread
    public Response getBackupById(@PathParam("backupId") int backupId) {
        BackupRestore backup = backupRestoreService.getBackupById(backupId);
        if (backup != null) {
            return Response.ok(backup).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    // 删除指定ID的备份
    // 删除备份后返回204状态码
    @DELETE
    @Path("/{backupId}")
    @RunOnVirtualThread
    public Response deleteBackup(@PathParam("backupId") int backupId) {
        backupRestoreService.deleteBackup(backupId);
        return Response.noContent().build();
    }

    // 更新指定ID的备份
    // 如果找到对应ID的备份，更新备份信息并返回200状态码；否则返回404状态码
    @PUT
    @Path("/{backupId}")
    @RunOnVirtualThread
    public Response updateBackup(@PathParam("backupId") int backupId, BackupRestore updatedBackup) {
        BackupRestore existingBackup = backupRestoreService.getBackupById(backupId);
        if (existingBackup != null) {
            updatedBackup.setBackupId(backupId);
            backupRestoreService.updateBackup(updatedBackup);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    // 根据文件名获取备份
    // 如果找到对应文件名的备份，返回该备份和200状态码；否则返回404状态码
    @GET
    @Path("/filename/{backupFileName}")
    @RunOnVirtualThread
    public Response getBackupByFileName(@PathParam("backupFileName") String backupFileName) {
        BackupRestore backup = backupRestoreService.getBackupByFileName(backupFileName);
        if (backup != null) {
            return Response.ok(backup).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    // 根据备份时间获取备份列表
    // 返回匹配指定时间的备份列表和200状态码
    @GET
    @Path("/time/{backupTime}")
    @RunOnVirtualThread
    public Response getBackupsByTime(@PathParam("backupTime") String backupTime) {
        List<BackupRestore> backups = backupRestoreService.getBackupsByTime(backupTime);
        return Response.ok(backups).build();
    }
}
