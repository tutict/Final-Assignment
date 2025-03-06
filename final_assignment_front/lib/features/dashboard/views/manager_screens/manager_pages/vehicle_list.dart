import 'package:final_assignment_front/features/dashboard/views/user_screens/user_pages/process_pages/vehicle_management.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:get/Get.dart';

/// Unique identifier generator for idempotency
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleList> {
  late VehicleInformationControllerApi vehicleApi;
  late Future<List<VehicleInformation>> _vehiclesFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  bool _isLoading = true;
  String _errorMessage = '';

  // 搜索时使用的控制器
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    vehicleApi = VehicleInformationControllerApi();
    _loadVehicles(); // Load vehicles with proper JWT initialization
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await vehicleApi
          .initializeWithJwt(); // Set JWT before making the API call
      _vehiclesFuture =
          vehicleApi.apiVehiclesGet(); // Assign future after JWT is set
      await _vehiclesFuture; // Wait for the data
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载车辆信息失败: $e';
        if (e.toString().contains('未登录')) {
          _redirectToLogin();
        }
      });
    }
  }

  Future<void> _searchVehicles(String type, String query) async {
    if (query.isEmpty) {
      _loadVehicles();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await vehicleApi.initializeWithJwt(); // Ensure JWT is set
      switch (type) {
        case 'licensePlate':
          final vehicle = await vehicleApi
              .apiVehiclesLicensePlateLicensePlateGet(licensePlate: query);
          _vehiclesFuture = Future.value(vehicle != null ? [vehicle] : []);
          break;
        case 'vehicleType':
          _vehiclesFuture =
              vehicleApi.apiVehiclesTypeVehicleTypeGet(vehicleType: query);
          break;
        case 'ownerName':
          _vehiclesFuture =
              vehicleApi.apiVehiclesOwnerOwnerNameGet(ownerName: query);
          break;
        case 'status':
          _vehiclesFuture = vehicleApi.apiVehiclesStatusCurrentStatusGet(
              currentStatus: query);
          break;
        default:
          _loadVehicles();
          return;
      }
      await _vehiclesFuture;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
        if (e.toString().contains('未登录')) {
          _redirectToLogin();
        }
      });
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(
        context, '/login'); // Adjust route name as needed
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(color: isError ? Colors.red : Colors.white)),
        backgroundColor: isError ? Colors.grey[800] : Colors.green,
      ),
    );
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => VehicleDetailPage(vehicle: vehicle)),
    ).then((value) {
      if (value == true && mounted) {
        _loadVehicles();
      }
    });
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await vehicleApi.initializeWithJwt();
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      _loadVehicles();
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  Future<void> _deleteVehicleByLicensePlate(String licensePlate) async {
    try {
      await vehicleApi.initializeWithJwt();
      await vehicleApi.apiVehiclesLicensePlateLicensePlateDelete(
          licensePlate: licensePlate);
      _showSnackBar('按车牌删除车辆成功！');
      _loadVehicles();
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  Widget _buildSearchField(String label, TextEditingController controller,
      String type, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                labelStyle:
                    TextStyle(color: isLight ? Colors.black87 : Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isLight ? Colors.grey : Colors.grey[500]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isLight ? Colors.blue : Colors.blueGrey),
                ),
              ),
              onChanged: (value) => _searchVehicles(type, value),
              style: TextStyle(color: isLight ? Colors.black : Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _searchVehicles(type, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆信息列表'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddVehiclePage()),
              ).then((value) {
                if (value == true && mounted) {
                  _loadVehicles();
                }
              });
            },
            tooltip: '添加新车辆信息',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSearchField(
                '按车牌号搜索', _licensePlateController, 'licensePlate', isLight),
            _buildSearchField(
                '按车辆类型搜索', _vehicleTypeController, 'vehicleType', isLight),
            _buildSearchField(
                '按车主名称搜索', _ownerNameController, 'ownerName', isLight),
            _buildSearchField('按状态搜索', _statusController, 'status', isLight),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage.isNotEmpty)
              Expanded(child: Center(child: Text(_errorMessage)))
            else
              Expanded(
                child: FutureBuilder<List<VehicleInformation>>(
                  future: _vehiclesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '加载车辆信息时发生错误: ${snapshot.error}',
                          style: TextStyle(
                              color: isLight ? Colors.black : Colors.white),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          '没有找到车辆信息',
                          style: TextStyle(
                              color: isLight ? Colors.black : Colors.white),
                        ),
                      );
                    } else {
                      final vehicles = snapshot.data!;
                      return ListView.builder(
                        itemCount: vehicles.length,
                        itemBuilder: (context, index) {
                          final v = vehicles[index];
                          final type = v.vehicleType ?? '未知类型';
                          final plate = v.licensePlate ?? '未知车牌';
                          final owner = v.ownerName ?? '未知车主';
                          final vid = v.vehicleId ?? 0;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            elevation: 4,
                            color: isLight ? Colors.white : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            child: ListTile(
                              title: Text('车辆类型: $type',
                                  style: TextStyle(
                                      color: isLight
                                          ? Colors.black87
                                          : Colors.white)),
                              subtitle: Text('车牌号: $plate\n车主: $owner',
                                  style: TextStyle(
                                      color: isLight
                                          ? Colors.black54
                                          : Colors.white70)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _goToDetailPage(v);
                                  } else if (value == 'delete') {
                                    _deleteVehicle(vid);
                                  } else if (value == 'deleteByPlate') {
                                    _deleteVehicleByLicensePlate(plate);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem<String>(
                                      value: 'edit', child: Text('编辑')),
                                  const PopupMenuItem<String>(
                                      value: 'delete', child: Text('按ID删除')),
                                  const PopupMenuItem<String>(
                                      value: 'deleteByPlate',
                                      child: Text('按车牌删除')),
                                ],
                                icon: Icon(Icons.more_vert,
                                    color: isLight
                                        ? Colors.black87
                                        : Colors.white),
                              ),
                              onTap: () => _goToDetailPage(v),
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
      ),
    );
  }
}
