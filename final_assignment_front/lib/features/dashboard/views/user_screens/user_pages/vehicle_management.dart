import 'dart:convert';

import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';

// 车辆管理页面的 StatefulWidget
class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => _VehicleManagementState();
}

// 车辆管理页面的状态类
class _VehicleManagementState extends State<VehicleManagement> {
  // 搜索框的控制器
  final TextEditingController _searchController = TextEditingController();

  // 存储所有车辆信息的列表
  List<Map<String, String>> _vehicleList = [];

  // 存储过滤后的车辆信息列表
  List<Map<String, String>> _filteredVehicleList = [];

  // REST API 服务的实例
  late RestApiServices restApiServices;

  // 初始化状态
  @override
  void initState() {
    super.initState();
    // 初始化 REST API 服务
    restApiServices = RestApiServices();
    // 初始化 WebSocket 连接
    restApiServices.initWebSocket(AppConfig.vehicleInformationEndpoint);
    // 加载车辆数据
    _loadVehicleData();
  }

  // 从服务器加载车辆数据
  Future<void> _loadVehicleData() async {
    try {
      // 使用 WebSocket 请求车辆信息
      restApiServices.sendMessage(jsonEncode({'action': 'getVehicles'}));
      final response =
          await restApiServices.getMessages().firstWhere((message) {
        final decodedMessage = jsonDecode(message);
        return decodedMessage['action'] == 'getVehiclesResponse';
      });

      final decodedMessage = jsonDecode(response);
      if (decodedMessage['status'] == 'success') {
        // 更新车辆信息列表
        setState(() {
          _vehicleList = List<Map<String, String>>.from(decodedMessage['data']
              .map((item) => item.cast<String, String>()));
          _filteredVehicleList = _vehicleList;
        });
      } else {
        // 打印加载失败的信息
        debugPrint('加载车辆信息失败: ${decodedMessage['message']}');
      }
    } catch (e) {
      // 打印异常信息
      debugPrint('加载车辆信息失败: $e');
    }
  }

  // 根据查询字符串过滤车辆列表
  void _filterVehicleList(String query) {
    setState(() {
      if (query.isEmpty) {
        // 如果查询为空，显示所有车辆信息
        _filteredVehicleList = _vehicleList;
      } else {
        // 根据车牌号或车主姓名过滤车辆信息
        _filteredVehicleList = _vehicleList
            .where((vehicle) =>
                vehicle['plateNumber']!
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                vehicle['owner']!
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
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
                _filterVehicleList(value);
              },
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: _filteredVehicleList.isEmpty
                  ? const Center(
                      child: Text('没有找到符合条件的车辆信息'),
                    )
                  : ListView.builder(
                      itemCount: _filteredVehicleList.length,
                      itemBuilder: (context, index) {
                        final vehicle = _filteredVehicleList[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 4,
                          child: ListTile(
                            title: Text('车牌号: ${vehicle['plateNumber']}'),
                            subtitle: Text('车辆类型: ${vehicle['vehicleType']}'
                                '车主: ${vehicle['owner']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                // 编辑车辆信息的逻辑
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
