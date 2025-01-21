import 'package:flutter/material.dart';

// 引入你提供的 VehicleInformationControllerApi 和 VehicleInformation
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleList> {
  // 用于调用后端接口
  late VehicleInformationControllerApi vehicleApi;

  // Future 用于异步加载车辆信息列表
  late Future<List<VehicleInformation>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    vehicleApi =
        VehicleInformationControllerApi(); // 若要自定义 basePath，可传入新的 ApiClient(basePath:'...')
    _vehiclesFuture = _fetchVehicles();
  }

  /// 根据可选参数 (licensePlate / vehicleType / ownerName) 从后端获取车辆信息
  Future<List<VehicleInformation>> _fetchVehicles({
    String? licensePlate,
    String? vehicleType,
    String? ownerName,
  }) async {
    try {
      // 1) 按车牌号
      if (licensePlate != null && licensePlate.isNotEmpty) {
        final result = await vehicleApi.apiVehiclesLicensePlateLicensePlateGet(
          licensePlate: licensePlate,
        );
        // 可能返回单条(Map)或列表(List)
        return _parseVehicleResult(result);
      }
      // 2) 按车辆类型
      else if (vehicleType != null && vehicleType.isNotEmpty) {
        final listObj = await vehicleApi.apiVehiclesTypeVehicleTypeGet(
          vehicleType: vehicleType,
        );
        return _parseVehicleList(listObj);
      }
      // 3) 按车主姓名
      else if (ownerName != null && ownerName.isNotEmpty) {
        final listObj = await vehicleApi.apiVehiclesOwnerOwnerNameGet(
          ownerName: ownerName,
        );
        return _parseVehicleList(listObj);
      }
      // 4) 否则获取全部
      else {
        final listObj = await vehicleApi.apiVehiclesGet();
        return _parseVehicleList(listObj);
      }
    } catch (e) {
      // 可以在此处打印或 rethrow
      throw Exception('获取车辆信息失败: $e');
    }
  }

  /// 删除车辆
  /// 这里示例假设我们用 vehicleId 删除，如果你后端是按 licensePlate 则调用 apiVehiclesLicensePlateLicensePlateDelete
  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      final success = await vehicleApi.apiVehiclesVehicleIdDelete(
        vehicleId: vehicleId.toString(),
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除车辆信息成功！')),
        );
        // 刷新列表
        setState(() {
          _vehiclesFuture = _fetchVehicles();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除车辆信息失败: $e')),
      );
    }
  }

  /// 搜索：按车牌号
  void _searchVehiclesByLicensePlate(String plate) {
    setState(() {
      _vehiclesFuture = _fetchVehicles(licensePlate: plate);
    });
  }

  /// 搜索：按车辆类型
  void _searchVehiclesByVehicleType(String type) {
    setState(() {
      _vehiclesFuture = _fetchVehicles(vehicleType: type);
    });
  }

  /// 搜索：按车主姓名
  void _searchVehiclesByOwnerName(String owner) {
    setState(() {
      _vehiclesFuture = _fetchVehicles(ownerName: owner);
    });
  }

  /// 解析后端返回: 可能是单条(Map)或多条(List)
  List<VehicleInformation> _parseVehicleResult(Object? result) {
    if (result == null) return [];
    if (result is List) {
      return result.map((item) {
        return VehicleInformation.fromJson(item as Map<String, dynamic>);
      }).toList();
    } else if (result is Map<String, dynamic>) {
      return [VehicleInformation.fromJson(result)];
    } else {
      return [];
    }
  }

  /// 解析后端返回的List<Object>?
  List<VehicleInformation> _parseVehicleList(List<Object>? listObj) {
    if (listObj == null) return [];
    return listObj.map((item) {
      return VehicleInformation.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆信息列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 跳转到添加车辆页面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddVehiclePage()),
              ).then((value) {
                if (value == true) {
                  setState(() {
                    _vehiclesFuture = _fetchVehicles();
                  });
                }
              });
            },
            tooltip: '添加新车辆信息',
          ),
        ],
      ),
      body: Column(
        children: [
          // 按车牌号搜索
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchVehiclesByLicensePlate,
              decoration: const InputDecoration(
                labelText: '按车牌号搜索',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // 按车辆类型搜索
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchVehiclesByVehicleType,
              decoration: const InputDecoration(
                labelText: '按车辆类型搜索',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // 按车主姓名搜索
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchVehiclesByOwnerName,
              decoration: const InputDecoration(
                labelText: '按车主名称搜索',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // 列表
          Expanded(
            child: FutureBuilder<List<VehicleInformation>>(
              future: _vehiclesFuture,
              builder: (context, snapshot) {
                // 加载中
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // 出错
                else if (snapshot.hasError) {
                  return Center(
                    child: Text('加载车辆信息时发生错误: ${snapshot.error}'),
                  );
                }
                // 没数据
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('没有找到车辆信息'));
                }
                // 有数据
                else {
                  final vehicles = snapshot.data!;
                  return ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      final type = v.vehicleType ?? '未知类型';
                      final plate = v.licensePlate ?? '未知车牌';
                      final owner = v.ownerName ?? '未知车主';
                      final status = v.currentStatus ?? '状态未知';
                      final vid = v.vehicleId ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: ListTile(
                          title: Text('车辆类型: $type'),
                          subtitle: Text('车牌号: $plate\n车主: $owner'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteVehicle(vid),
                            tooltip: '删除此车辆信息',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VehicleDetailPage(
                                  vehicle: v,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 添加车辆页面 (示例)
class AddVehiclePage extends StatelessWidget {
  const AddVehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加新车辆信息'),
      ),
      body: const Center(
        child: Text('此页面用于添加新车辆信息（尚未实现）'),
      ),
    );
  }
}

/// 车辆详情页面 (示例)
class VehicleDetailPage extends StatelessWidget {
  final VehicleInformation vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final type = vehicle.vehicleType ?? '未知类型';
    final plate = vehicle.licensePlate ?? '未知车牌';
    final owner = vehicle.ownerName ?? '未知车主';
    final status = vehicle.currentStatus ?? '未知状态';

    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆详细信息'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('车辆类型: $type', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text('车牌号: $plate', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('车主: $owner', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('车辆状态: $status', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
