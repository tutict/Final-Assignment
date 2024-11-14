import 'dart:convert';

import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:final_assignment_front/utils/services/message_provider.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 车辆管理页面的 StatefulWidget
class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => _VehicleManagementState();
}

/// 车辆管理页面的状态类
class _VehicleManagementState extends State<VehicleManagement> {
  // 搜索框的控制器
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();

  // REST API 服务的实例
  late RestApiServices restApiServices;

  @override
  void initState() {
    super.initState();
    restApiServices = RestApiServices();

    // 初始化 WebSocket 连接，并传入 MessageProvider
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    restApiServices.initWebSocket(
        AppConfig.vehicleInformationEndpoint, messageProvider);

    // 发送获取车辆信息的请求
    restApiServices.sendMessage(jsonEncode({'action': 'getVehicles'}));
  }

  @override
  void dispose() {
    // 关闭 WebSocket 连接
    restApiServices.closeWebSocket();
    _searchController.dispose();
    _plateNumberController.dispose();
    _vehicleTypeController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  // 构建车辆管理页面的 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆信息管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 搜索框
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜索车辆信息',
                hintText: '输入车牌号或车主姓名',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // 当搜索框文本变化时，过滤车辆列表
                // 这里的过滤将在 Consumer 中处理
              },
            ),
            const SizedBox(height: 16.0),
            // 车辆信息表单
            TextField(
              controller: _plateNumberController,
              decoration: const InputDecoration(
                labelText: '车牌号',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _vehicleTypeController,
              decoration: const InputDecoration(
                labelText: '车辆类型',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _ownerController,
              decoration: const InputDecoration(
                labelText: '车主姓名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // 处理添加或更新车辆信息的逻辑
                String plateNumber = _plateNumberController.text;
                String vehicleType = _vehicleTypeController.text;
                String owner = _ownerController.text;

                // 发送添加或更新车辆信息的请求
                restApiServices.sendMessage(
                  jsonEncode({
                    'action': 'addOrUpdateVehicle',
                    'plateNumber': plateNumber,
                    'vehicleType': vehicleType,
                    'owner': owner,
                  }),
                );
              },
              child: const Text('保存车辆信息'),
            ),
            const SizedBox(height: 16.0),
            // 使用 Consumer 监听 MessageProvider 的变化
            Expanded(
              child: Consumer<MessageProvider>(
                builder: (context, messageProvider, child) {
                  final message = messageProvider.message;
                  if (message != null &&
                      message.action == 'getVehiclesResponse') {
                    if (message.data['status'] == 'success') {
                      // 解析车辆数据
                      List<Vehicle> vehicleList = List<Vehicle>.from(
                        message.data['data']
                            .map((item) => Vehicle.fromJson(item)),
                      );

                      if (vehicleList.isEmpty) {
                        return const Center(
                          child: Text('没有找到符合条件的车辆信息'),
                        );
                      }

                      return ListView.builder(
                        itemCount: vehicleList.length,
                        itemBuilder: (context, index) {
                          final vehicle = vehicleList[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 4,
                            child: ListTile(
                              title: Text('车牌号: ${vehicle.plateNumber}'),
                              subtitle: Text(
                                  '车辆类型: ${vehicle.vehicleType}\n车主: ${vehicle.owner}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  // 编辑车辆信息的逻辑
                                  _plateNumberController.text =
                                      vehicle.plateNumber;
                                  _vehicleTypeController.text =
                                      vehicle.vehicleType;
                                  _ownerController.text = vehicle.owner;
                                },
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return Center(
                        child: Text('加载车辆信息失败: ${message.data['message']}'),
                      );
                    }
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 车辆信息模型
class Vehicle {
  String plateNumber;
  String vehicleType;
  String owner;

  Vehicle({
    required this.plateNumber,
    required this.vehicleType,
    required this.owner,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      plateNumber: json['plateNumber'],
      vehicleType: json['vehicleType'],
      owner: json['owner'],
    );
  }
}
