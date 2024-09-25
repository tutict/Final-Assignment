package com.tutict.finalassignmentbackend.controller;

import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.service.VehicleInformationService;
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

@RestController
@RequestMapping("/eventbus/vehicles")
/*
 * 车辆信息控制器类，用于处理与车辆信息相关的HTTP请求。
 */
public class VehicleInformationController {

    private final VehicleInformationService vehicleInformationService;

    @Autowired
    public VehicleInformationController(VehicleInformationService vehicleInformationService) {
        this.vehicleInformationService = vehicleInformationService;
    }

    /**
     * 创建新的车辆信息。
     *
     * @param vehicleInformation 新创建的车辆信息对象
     * @return HTTP响应状态码201 Created
     */
    @PostMapping
    public ResponseEntity<Void> createVehicleInformation(@RequestBody VehicleInformation vehicleInformation) {
        vehicleInformationService.createVehicleInformation(vehicleInformation);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    /**
     * 根据ID获取车辆信息。
     *
     * @param vehicleId 车辆ID
     * @return 包含车辆信息的HTTP响应或NotFound状态
     */
    @GetMapping("/{vehicleId}")
    public ResponseEntity<VehicleInformation> getVehicleInformationById(@PathVariable int vehicleId) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationById(vehicleId);
        if (vehicleInformation != null) {
            return ResponseEntity.ok(vehicleInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * 根据车牌号获取车辆信息。
     *
     * @param licensePlate 车牌号
     * @return 包含车辆信息的HTTP响应或NotFound状态
     */
    @GetMapping("/license-plate/{licensePlate}")
    public ResponseEntity<VehicleInformation> getVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
        if (vehicleInformation != null) {
            return ResponseEntity.ok(vehicleInformation);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * 获取所有车辆信息。
     *
     * @return 包含所有车辆信息列表的HTTP响应
     */
    @GetMapping
    public ResponseEntity<List<VehicleInformation>> getAllVehicleInformation() {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getAllVehicleInformation();
        return ResponseEntity.ok(vehicleInformationList);
    }

    /**
     * 根据车辆类型获取车辆信息列表。
     *
     * @param vehicleType 车辆类型
     * @return 包含车辆信息列表的HTTP响应
     */
    @GetMapping("/type/{vehicleType}")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByType(@PathVariable String vehicleType) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByType(vehicleType);
        return ResponseEntity.ok(vehicleInformationList);
    }

    /**
     * 根据车主名称获取车辆信息列表。
     *
     * @param ownerName 车主名称
     * @return 包含车辆信息列表的HTTP响应
     */
    @GetMapping("/owner/{ownerName}")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByOwnerName(@PathVariable String ownerName) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByOwnerName(ownerName);
        return ResponseEntity.ok(vehicleInformationList);
    }

    /**
     * 根据车辆状态获取车辆信息列表。
     *
     * @param currentStatus 车辆状态
     * @return 包含车辆信息列表的HTTP响应
     */
    @GetMapping("/status/{currentStatus}")
    public ResponseEntity<List<VehicleInformation>> getVehicleInformationByStatus(@PathVariable String currentStatus) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByStatus(currentStatus);
        return ResponseEntity.ok(vehicleInformationList);
    }

    /**
     * 更新车辆信息。
     *
     * @param vehicleId 车辆ID
     * @param vehicleInformation 更新后的车辆信息对象
     * @return HTTP响应状态码200 OK
     */
    @PutMapping("/{vehicleId}")
    public ResponseEntity<Void> updateVehicleInformation(@PathVariable int vehicleId, @RequestBody VehicleInformation vehicleInformation) {
        vehicleInformation.setVehicleId(vehicleId);
        vehicleInformationService.updateVehicleInformation(vehicleInformation);
        return ResponseEntity.ok().build();
    }

    /**
     * 根据ID删除车辆信息。
     *
     * @param vehicleId 车辆ID
     * @return HTTP响应状态码204 No Content
     */
    @DeleteMapping("/{vehicleId}")
    public ResponseEntity<Void> deleteVehicleInformation(@PathVariable int vehicleId) {
        vehicleInformationService.deleteVehicleInformation(vehicleId);
        return ResponseEntity.noContent().build();
    }

    /**
     * 根据车牌号删除车辆信息。
     *
     * @param licensePlate 车牌号
     * @return HTTP响应状态码204 No Content
     */
    @DeleteMapping("/license-plate/{licensePlate}")
    public ResponseEntity<Void> deleteVehicleInformationByLicensePlate(@PathVariable String licensePlate) {
        vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
        return ResponseEntity.noContent().build();
    }

    /**
     * 检查车牌号是否存在。
     *
     * @param licensePlate 车牌号
     * @return 包含检查结果的HTTP响应
     */
    @GetMapping("/exists/{licensePlate}")
    public ResponseEntity<Boolean> isLicensePlateExists(@PathVariable String licensePlate) {
        boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
        return ResponseEntity.ok(exists);
    }
}
