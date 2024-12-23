import 'package:flutter/material.dart';

import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';

/// 车辆管理主页面
class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => _VehicleManagementState();
}

class _VehicleManagementState extends State<VehicleManagement> {
  // 搜索框控制器
  final TextEditingController _searchController = TextEditingController();

  // 用于管理接口调用的 API 类
  late VehicleInformationControllerApi vehicleApi;

  // 当前的车辆列表
  List<VehicleInformation> _vehicleList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    vehicleApi = VehicleInformationControllerApi();

    // 初始加载所有车辆
    _fetchAllVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 获取所有车辆信息
  Future<void> _fetchAllVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // apiVehiclesGet 返回类型: Future<List<Object>?>
      final rawList = await vehicleApi.apiVehiclesGet();
      if (rawList == null) {
        setState(() {
          _vehicleList = [];
          _isLoading = false;
        });
        return;
      }

      // 将 List<Object> 转为 List<VehicleInformation>
      final list = rawList
          .map((item) => VehicleInformation.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _vehicleList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载车辆信息失败: $e';
      });
    }
  }

  /// 根据搜索内容进行查询
  Future<void> _searchVehicles(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 如果搜索内容是空，则加载所有
      if (query.isEmpty) {
        await _fetchAllVehicles();
        return;
      }

      // 简单逻辑：如果输入包含中文或字母，就按车主姓名搜，否则按车牌搜
      // 你可自行决定: 也可加一个按钮, 分别点击"按车牌搜索" or "按车主搜索"
      final isLetter = RegExp(r'[a-zA-Z\u4e00-\u9fa5]').hasMatch(query);

      List<Object>? rawList;
      if (isLetter) {
        // 调用: 根据车主名称获取车辆列表
        rawList = await vehicleApi.apiVehiclesOwnerOwnerNameGet(ownerName: query);
      } else {
        // 调用: 根据车牌号获取车辆信息
        // 此处要么是 "apiVehiclesLicensePlateLicensePlateGet" (单个?),
        // 要么你后端也支持多结果?
        // 下面演示：如果后端是一个返回单条记录的接口
        // 就把它包装成 list, 仅做示例
        final singleVehicle = await vehicleApi.apiVehiclesLicensePlateLicensePlateGet(
          licensePlate: query,
        );
        if (singleVehicle == null) {
          rawList = [];
        } else {
          // singleVehicle 是 Object? 可能是 Map<String, dynamic>
          rawList = [singleVehicle];
        }
      }

      if (rawList == null) {
        setState(() {
          _vehicleList = [];
          _isLoading = false;
        });
        return;
      }

      final list = rawList
          .map((item) => VehicleInformation.fromJson(item as Map<String, dynamic>))
          .toList();
      setState(() {
        _vehicleList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
      });
    }
  }

  /// 车辆列表项的点击事件，跳转详情页
  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailPage(vehicle: vehicle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆管理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 搜索框
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜索车辆',
                hintText: '输入车牌号或车主姓名',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // 进行搜索
                _searchVehicles(value);
              },
            ),
            const SizedBox(height: 16.0),
            // 显示加载中 或 错误信息
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(child: Text(_errorMessage)),
              )
            else
            // 展示车辆列表
              Expanded(
                child: _vehicleList.isEmpty
                    ? const Center(child: Text('暂无车辆信息'))
                    : ListView.builder(
                  itemCount: _vehicleList.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicleList[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 4,
                      child: ListTile(
                        title: Text('车牌号: ${vehicle.licensePlate ?? ""}'),
                        subtitle: Text(
                          '车主: ${vehicle.ownerName ?? ""}\n车辆类型: ${vehicle.vehicleType ?? ""}',
                        ),
                        onTap: () => _goToDetailPage(vehicle),
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

/// 车辆详情页面
class VehicleDetailPage extends StatelessWidget {
  final VehicleInformation vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆详情'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRow('车牌号', vehicle.licensePlate),
            _buildRow('车辆类型', vehicle.vehicleType),
            _buildRow('车主姓名', vehicle.ownerName),
            _buildRow('身份证号码', vehicle.idCardNumber),
            _buildRow('联系电话', vehicle.contactNumber),
            _buildRow('发动机号', vehicle.engineNumber),
            _buildRow('车架号', vehicle.frameNumber),
            _buildRow('车身颜色', vehicle.vehicleColor),
            _buildRow('首次注册日期', vehicle.firstRegistrationDate),
            _buildRow('当前状态', vehicle.currentStatus),
          ],
        ),
      ),
    );
  }

  /// 用来统一渲染一行
  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '')),
        ],
      ),
    );
  }
}
