import 'dart:convert';
import 'dart:developer' as developer;
import 'package:final_assignment_front/utils/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListPage();
}

class _VehicleListPage extends State<VehicleList> {
  late Future<List<Vehicle>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = _fetchVehicles();
  }

  Future<List<Vehicle>> _fetchVehicles({
    String? licensePlate,
    String? vehicleType,
    String? ownerName,
  }) async {
    Uri url;

    if (licensePlate != null) {
      url = Uri.parse(
          '${AppConfig.baseUrl}${AppConfig.vehicleInformationEndpoint}/license-plate/$licensePlate');
    } else if (vehicleType != null) {
      url = Uri.parse(
          '${AppConfig.baseUrl}${AppConfig.vehicleInformationEndpoint}/type/$vehicleType');
    } else if (ownerName != null) {
      url = Uri.parse(
          '${AppConfig.baseUrl}${AppConfig.vehicleInformationEndpoint}/owner/$ownerName');
    } else {
      url = Uri.parse(
          '${AppConfig.baseUrl}${AppConfig.vehicleInformationEndpoint}');
    }

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> vehiclesJson = jsonDecode(response.body);
        return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      developer.log('Error: $e');
      throw Exception('Failed to load vehicles: $e');
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.vehicleInformationEndpoint}/$vehicleId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除车辆信息成功！')),
        );
        setState(() {
          _vehiclesFuture =
              _fetchVehicles(); // Refresh vehicle list after delete
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除车辆信息失败，请稍后重试。')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发生错误，请检查网络连接。')),
      );
    }
  }

  void _searchVehiclesByLicensePlate(String licensePlate) {
    setState(() {
      _vehiclesFuture = _fetchVehicles(licensePlate: licensePlate);
    });
  }

  void _searchVehiclesByVehicleType(String vehicleType) {
    setState(() {
      _vehiclesFuture = _fetchVehicles(vehicleType: vehicleType);
    });
  }

  void _searchVehiclesByOwnerName(String ownerName) {
    setState(() {
      _vehiclesFuture = _fetchVehicles(ownerName: ownerName);
    });
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
          Expanded(
            child: FutureBuilder<List<Vehicle>>(
              future: _vehiclesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('加载车辆信息时发生错误: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('没有找到车辆信息'));
                } else {
                  final vehicles = snapshot.data!;
                  return ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text('车辆类型: ${vehicle.vehicleType}'),
                          subtitle: Text(
                              '车牌号: ${vehicle.licensePlate}\n车主: ${vehicle.ownerName}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteVehicle(vehicle.vehicleId),
                            tooltip: '删除此车辆信息',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      VehicleDetailPage(vehicle: vehicle)),
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

class VehicleDetailPage extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailPage({required this.vehicle, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆详细信息'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('车辆类型: ${vehicle.vehicleType}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text('车牌号: ${vehicle.licensePlate}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('车主: ${vehicle.ownerName}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('车辆状态: ${vehicle.currentStatus}',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class Vehicle {
  final int vehicleId;
  final String vehicleType;
  final String licensePlate;
  final String ownerName;
  final String currentStatus;

  Vehicle({
    required this.vehicleId,
    required this.vehicleType,
    required this.licensePlate,
    required this.ownerName,
    required this.currentStatus,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicleId'],
      vehicleType: json['vehicleType'],
      licensePlate: json['licensePlate'],
      ownerName: json['ownerName'],
      currentStatus: json['currentStatus'],
    );
  }
}
