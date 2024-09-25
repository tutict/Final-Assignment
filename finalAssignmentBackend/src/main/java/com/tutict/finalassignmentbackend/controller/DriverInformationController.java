package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.service.DriverInformationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

// 控制器类，处理与司机信息相关的HTTP请求
@RestController
@RequestMapping("/eventbus/drivers")
public class DriverInformationController {

    // 司机信息服务的依赖项，处理具体的业务逻辑
    private final DriverInformationService driverInformationService;

    // 构造函数注入司机信息服务
    @Autowired
    public DriverInformationController(DriverInformationService driverInformationService) {
        this.driverInformationService = driverInformationService;
    }

    // 创建司机信息的POST请求处理方法
    @PostMapping
    public ResponseEntity<Void> createDriver(@RequestBody DriverInformation driverInformation) {
        driverInformationService.createDriver(driverInformation);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    // 根据ID获取司机信息的GET请求处理方法
    @GetMapping("/{driverId}")
    public ResponseEntity<DriverInformation> getDriverById(@PathVariable int driverId) {
        DriverInformation driverInformation = driverInformationService.getDriverById(driverId);
        if (driverInformation != null) {
            return ResponseEntity.ok(driverInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 获取所有司机信息的GET请求处理方法
    @GetMapping
    public ResponseEntity<List<DriverInformation>> getAllDrivers() {
        List<DriverInformation> drivers = driverInformationService.getAllDrivers();
        return ResponseEntity.ok(drivers);
    }

    // 更新司机信息的PUT请求处理方法
    @PutMapping("/{driverId}")
    public ResponseEntity<Void> updateDriver(@PathVariable int driverId, @RequestBody DriverInformation updatedDriverInformation) {
        DriverInformation existingDriverInformation = driverInformationService.getDriverById(driverId);
        if (existingDriverInformation != null) {
            updatedDriverInformation.setDriverId(driverId);
            driverInformationService.updateDriver(updatedDriverInformation);
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 删除司机信息的DELETE请求处理方法
    @DeleteMapping("/{driverId}")
    public ResponseEntity<Void> deleteDriver(@PathVariable int driverId) {
        driverInformationService.deleteDriver(driverId);
        return ResponseEntity.noContent().build();
    }

    // 根据身份证号码获取司机信息的GET请求处理方法
    @GetMapping("/idCardNumber/{idCardNumber}")
    public ResponseEntity<List<DriverInformation>> getDriversByIdCardNumber(@PathVariable String idCardNumber) {
        List<DriverInformation> drivers = driverInformationService.getDriversByIdCardNumber(idCardNumber);
        return ResponseEntity.ok(drivers);
    }

    // 根据驾驶证号码获取司机信息的GET请求处理方法
    @GetMapping("/driverLicenseNumber/{driverLicenseNumber}")
    public ResponseEntity<DriverInformation> getDriverByDriverLicenseNumber(@PathVariable String driverLicenseNumber) {
        DriverInformation driverInformation = driverInformationService.getDriverByDriverLicenseNumber(driverLicenseNumber);
        if (driverInformation != null) {
            return ResponseEntity.ok(driverInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // 根据姓名获取司机信息的GET请求处理方法
    @GetMapping("/name/{name}")
    public ResponseEntity<List<DriverInformation>> getDriversByName(@PathVariable String name) {
        List<DriverInformation> drivers = driverInformationService.getDriversByName(name);
        return ResponseEntity.ok(drivers);
    }
}
