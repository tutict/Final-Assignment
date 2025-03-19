import 'dart:convert';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDate(DateTime? date) {
  if (date == null) return '无';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListState();
}

class _VehicleListState extends State<VehicleList> {
  final TextEditingController _searchController = TextEditingController();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final List<VehicleInformation> _vehicleList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentDriverName;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  String _searchType = 'licensePlate'; // 默认搜索类型为车牌号
  bool _isAdmin = false; // 判断是否为管理员

  final DashboardController? controller =
      Get.isRegistered<DashboardController>()
          ? Get.find<DashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await vehicleApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final decodedToken = JwtDecoder.decode(jwtToken);
      _currentDriverName = decodedToken['sub'] ?? '';
      if (_currentDriverName!.isEmpty) throw Exception('JWT 中未找到用户名');
      await _checkUserRole();
      await _fetchVehicles(reset: true);
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        final roles = (userData['roles'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            [];
        setState(() => _isAdmin = roles.contains('ADMIN'));
      } else {
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicles({bool reset = false, String? query}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _vehicleList.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final searchQuery = query?.trim() ?? '';
      debugPrint(
          'Fetching vehicles with query: $searchQuery, page: $_currentPage, searchType: $_searchType');

      List<VehicleInformation> vehicles;
      if (searchQuery.isEmpty) {
        vehicles = await vehicleApi.apiVehiclesGet(
          page: _currentPage,
          size: _pageSize,
        );
      } else {
        switch (_searchType) {
          case 'licensePlate':
            final vehicle = await vehicleApi.apiVehiclesLicensePlateGet(
                licensePlate: searchQuery);
            vehicles = vehicle != null ? [vehicle] : [];
            break;
          case 'vehicleType':
            vehicles = await vehicleApi.apiVehiclesTypeGet(
              vehicleType: searchQuery,
              page: _currentPage,
              size: _pageSize,
            );
            break;
          default:
            vehicles = await vehicleApi.apiVehiclesGet(
              page: _currentPage,
              size: _pageSize,
            );
            break;
        }
      }

      setState(() {
        _vehicleList.addAll(vehicles);
        if (vehicles.length < _pageSize) _hasMore = false;
        if (_vehicleList.isEmpty && _currentPage == 1) {
          _errorMessage = query != null ? '未找到符合条件的车辆' : '当前没有车辆记录';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            e.toString().contains('403') ? '未授权，请重新登录' : '获取车辆信息失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreVehicles() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchVehicles(query: _searchController.text);
  }

  Future<void> _refreshVehicles() async {
    _searchController.clear();
    await _fetchVehicles(reset: true);
  }

  Future<void> _searchVehicles() async {
    final query = _searchController.text.trim();
    await _fetchVehicles(reset: true, query: query);
  }

  void _createVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    ).then((value) {
      if (value == true && mounted) _fetchVehicles(reset: true);
    });
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => VehicleDetailPage(vehicle: vehicle)),
    ).then((value) {
      if (value == true && mounted) _fetchVehicles(reset: true);
    });
  }

  void _editVehicle(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditVehiclePage(vehicle: vehicle)),
    ).then((value) {
      if (value == true && mounted) _fetchVehicles(reset: true);
    });
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      _fetchVehicles(reset: true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData =
            controller?.currentBodyTheme.value ?? ThemeData.light();
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '确认删除',
            style: themeData.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          content: Text(
            '您确定要$action此车辆吗？此操作不可撤销。',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '取消',
                style: themeData.textTheme.labelLarge?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.error,
                foregroundColor: themeData.colorScheme.onError,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildSearchField(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: themeData.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: _searchType == 'licensePlate' ? '搜索车牌号' : '搜索车辆类型',
                hintStyle: TextStyle(
                    color: themeData.colorScheme.onSurface.withOpacity(0.6)),
                prefixIcon:
                    Icon(Icons.search, color: themeData.colorScheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: themeData.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          _searchController.clear();
                          _fetchVehicles(reset: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeData.colorScheme.outline.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeData.colorScheme.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: themeData.colorScheme.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
              ),
              onSubmitted: (value) => _searchVehicles(),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _searchType,
            onChanged: (String? newValue) {
              setState(() {
                _searchType = newValue!;
                _searchController.clear();
                _fetchVehicles(reset: true);
              });
            },
            items: <String>['licensePlate', 'vehicleType']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value == 'licensePlate' ? '按车牌号' : '按车辆类型',
                  style: TextStyle(color: themeData.colorScheme.onSurface),
                ),
              );
            }).toList(),
            dropdownColor: themeData.colorScheme.surfaceContainer,
            icon: Icon(Icons.arrow_drop_down,
                color: themeData.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text('车辆管理',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimaryContainer,
            )),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshVehicles,
            tooltip: '刷新车辆列表',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createVehicle,
            tooltip: '添加新车辆信息',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshVehicles,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchField(themeData),
              const SizedBox(height: 12),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent &&
                        _hasMore) {
                      _loadMoreVehicles();
                    }
                    return false;
                  },
                  child: _isLoading && _currentPage == 1
                      ? Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                  themeData.colorScheme.primary)))
                      : _errorMessage.isNotEmpty && _vehicleList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _errorMessage,
                                    style: themeData.textTheme.titleMedium
                                        ?.copyWith(
                                      color: themeData.colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_errorMessage.contains('未授权'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pushReplacementNamed(
                                                context, '/login'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              themeData.colorScheme.primary,
                                          foregroundColor:
                                              themeData.colorScheme.onPrimary,
                                        ),
                                        child: const Text('重新登录'),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  _vehicleList.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _vehicleList.length && _hasMore) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final vehicle = _vehicleList[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  elevation: 3,
                                  color: themeData.colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16.0)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 12.0),
                                    title: Text(
                                      '车牌号: ${vehicle.licensePlate ?? '未知车牌'}',
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        color: themeData.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          '类型: ${vehicle.vehicleType ?? '未知类型'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '车主: ${vehicle.ownerName ?? '未知车主'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '状态: ${vehicle.currentStatus ?? '无'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: _isAdmin
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    size: 18),
                                                color: themeData
                                                    .colorScheme.primary,
                                                onPressed: () =>
                                                    _editVehicle(vehicle),
                                                tooltip: '编辑车辆',
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    size: 18,
                                                    color: themeData
                                                        .colorScheme.error),
                                                onPressed: () =>
                                                    _showDeleteConfirmationDialog(
                                                        '删除',
                                                        () => _deleteVehicle(
                                                            vehicle.vehicleId ??
                                                                0)),
                                                tooltip: '删除车辆',
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: themeData.colorScheme
                                                    .onSurfaceVariant,
                                                size: 18,
                                              ),
                                            ],
                                          )
                                        : Icon(
                                            Icons.arrow_forward_ios,
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                            size: 18,
                                          ),
                                    onTap: () => _goToDetailPage(vehicle),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createVehicle,
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        tooltip: '添加新车辆',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditVehiclePage extends StatefulWidget {
  final VehicleInformation vehicle;

  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _idCardNumberController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _frameNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _firstRegistrationDateController = TextEditingController();
  final _currentStatusController = TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false;
  List<DriverInformation> _drivers = []; // Define _drivers here
  DriverInformation? _selectedDriver;

  final DashboardController? controller =
      Get.isRegistered<DashboardController>()
          ? Get.find<DashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await _checkUserRole();
      if (_isAdmin) {
        await _fetchDrivers();
      }
      _initializeFields();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        final roles = (userData['roles'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            [];
        setState(() => _isAdmin = roles.contains('ADMIN'));
      } else {
        throw Exception('验证失败：${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('加载权限失败: $e', isError: true);
    }
  }

  Future<void> _fetchDrivers() async {
    try {
      final drivers = await driverApi.apiDriversGet();
      setState(() {
        _drivers = drivers;
        if (_drivers.isNotEmpty) {
          _selectedDriver = _drivers.firstWhere(
            (driver) => driver.name == widget.vehicle.ownerName,
            orElse: () => _drivers[0],
          );
          _ownerNameController.text = _selectedDriver!.name ?? '';
          _idCardNumberController.text = _selectedDriver!.idCardNumber ?? '';
          _contactNumberController.text = _selectedDriver!.contactNumber ?? '';
        }
      });
    } catch (e) {
      _showSnackBar('加载司机列表失败: $e', isError: true);
    }
  }

  void _initializeFields() {
    _licensePlateController.text =
        widget.vehicle.licensePlate?.replaceFirst('黑A', '') ?? '';
    _vehicleTypeController.text = widget.vehicle.vehicleType ?? '';
    if (!_isAdmin) {
      _ownerNameController.text = widget.vehicle.ownerName ?? '';
      _idCardNumberController.text = widget.vehicle.idCardNumber ?? '';
      _contactNumberController.text = widget.vehicle.contactNumber ?? '';
    }
    _engineNumberController.text = widget.vehicle.engineNumber ?? '';
    _frameNumberController.text = widget.vehicle.frameNumber ?? '';
    _vehicleColorController.text = widget.vehicle.vehicleColor ?? '';
    _firstRegistrationDateController.text =
        formatDate(widget.vehicle.firstRegistrationDate);
    _currentStatusController.text = widget.vehicle.currentStatus ?? '';
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _engineNumberController.dispose();
    _frameNumberController.dispose();
    _vehicleColorController.dispose();
    _firstRegistrationDateController.dispose();
    _currentStatusController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final vehicle = VehicleInformation(
        vehicleId: widget.vehicle.vehicleId,
        licensePlate: '黑A${_licensePlateController.text.trim()}',
        vehicleType: _vehicleTypeController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim().isEmpty
            ? null
            : _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim().isEmpty
            ? null
            : _contactNumberController.text.trim(),
        engineNumber: _engineNumberController.text.trim().isEmpty
            ? null
            : _engineNumberController.text.trim(),
        frameNumber: _frameNumberController.text.trim().isEmpty
            ? null
            : _frameNumberController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim().isEmpty
            ? null
            : _vehicleColorController.text.trim(),
        firstRegistrationDate: _firstRegistrationDateController.text.isEmpty
            ? null
            : DateTime.parse(_firstRegistrationDateController.text.trim()),
        currentStatus: _currentStatusController.text.trim().isEmpty
            ? null
            : _currentStatusController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.apiVehiclesVehicleIdPut(
        vehicleId: widget.vehicle.vehicleId ?? 0,
        vehicleInformation: vehicle,
        idempotencyKey: idempotencyKey,
      );

      _showSnackBar('更新车辆成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('更新车辆失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.vehicle.firstRegistrationDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: controller?.currentBodyTheme.value.colorScheme.primary),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(
          () => _firstRegistrationDateController.text = formatDate(pickedDate));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      String? prefix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
                  size: 18, color: themeData.colorScheme.primary)
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly || (_isAdmin ? false : label == '车主姓名'),
        onTap: onTap,
        validator:
            required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
      ),
    );
  }

  Widget _buildDriverDropdown(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<DriverInformation>(
        value: _selectedDriver,
        decoration: InputDecoration(
          labelText: '车主姓名',
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
        ),
        items: _drivers.map((driver) {
          return DropdownMenuItem<DriverInformation>(
            value: driver,
            child: Text(driver.name ?? '未知司机',
                style: TextStyle(color: themeData.colorScheme.onSurface)),
          );
        }).toList(),
        onChanged: (DriverInformation? newValue) {
          setState(() {
            _selectedDriver = newValue;
            _ownerNameController.text = newValue?.name ?? '';
            _idCardNumberController.text = newValue?.idCardNumber ?? '';
            _contactNumberController.text = newValue?.contactNumber ?? '';
          });
        },
        validator: (value) => value == null ? '车主姓名不能为空' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '编辑车辆信息',
          style: themeData.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        elevation: 3,
                        color: themeData.colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildTextField(
                                  '车牌号', _licensePlateController, themeData,
                                  required: true, prefix: '黑A'),
                              _buildTextField(
                                  '车辆类型', _vehicleTypeController, themeData,
                                  required: true),
                              if (_isAdmin)
                                _buildDriverDropdown(themeData)
                              else
                                _buildTextField(
                                    '车主姓名', _ownerNameController, themeData,
                                    required: true, readOnly: true),
                              _buildTextField(
                                  '身份证号码', _idCardNumberController, themeData,
                                  keyboardType: TextInputType.number),
                              _buildTextField(
                                  '联系电话', _contactNumberController, themeData,
                                  keyboardType: TextInputType.phone),
                              _buildTextField(
                                  '发动机号', _engineNumberController, themeData),
                              _buildTextField(
                                  '车架号', _frameNumberController, themeData),
                              _buildTextField(
                                  '车身颜色', _vehicleColorController, themeData),
                              _buildTextField('首次注册日期',
                                  _firstRegistrationDateController, themeData,
                                  readOnly: true, onTap: _pickDate),
                              _buildTextField(
                                  '当前状态', _currentStatusController, themeData),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 20.0),
                          textStyle: themeData.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _idCardNumberController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _frameNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _firstRegistrationDateController = TextEditingController();
  final _currentStatusController = TextEditingController();
  bool _isLoading = false;
  List<DriverInformation> _drivers = [];
  DriverInformation? _selectedDriver;

  final DashboardController? controller =
      Get.isRegistered<DashboardController>()
          ? Get.find<DashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await _fetchDrivers();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDrivers() async {
    try {
      final drivers = await driverApi.apiDriversGet();
      setState(() {
        _drivers = drivers;
        if (_drivers.isNotEmpty) {
          _selectedDriver = _drivers[0];
          _ownerNameController.text = _selectedDriver!.name ?? '';
          _idCardNumberController.text = _selectedDriver!.idCardNumber ?? '';
          _contactNumberController.text = _selectedDriver!.contactNumber ?? '';
        }
      });
    } catch (e) {
      _showSnackBar('加载司机列表失败: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _engineNumberController.dispose();
    _frameNumberController.dispose();
    _vehicleColorController.dispose();
    _firstRegistrationDateController.dispose();
    _currentStatusController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final vehicle = VehicleInformation(
        licensePlate: '黑A${_licensePlateController.text.trim()}',
        vehicleType: _vehicleTypeController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim().isEmpty
            ? null
            : _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim().isEmpty
            ? null
            : _contactNumberController.text.trim(),
        engineNumber: _engineNumberController.text.trim().isEmpty
            ? null
            : _engineNumberController.text.trim(),
        frameNumber: _frameNumberController.text.trim().isEmpty
            ? null
            : _frameNumberController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim().isEmpty
            ? null
            : _vehicleColorController.text.trim(),
        firstRegistrationDate: _firstRegistrationDateController.text.isEmpty
            ? null
            : DateTime.parse(_firstRegistrationDateController.text.trim()),
        currentStatus: _currentStatusController.text.trim().isEmpty
            ? null
            : _currentStatusController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.apiVehiclesPost(
          vehicleInformation: vehicle, idempotencyKey: idempotencyKey);

      _showSnackBar('创建车辆成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('创建车辆失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: controller?.currentBodyTheme.value.colorScheme.primary),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(
          () => _firstRegistrationDateController.text = formatDate(pickedDate));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      String? prefix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
                  size: 18, color: themeData.colorScheme.primary)
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator:
            required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
      ),
    );
  }

  Widget _buildDriverDropdown(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<DriverInformation>(
        value: _selectedDriver,
        decoration: InputDecoration(
          labelText: '车主姓名',
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: themeData.colorScheme.surfaceContainerLowest,
        ),
        items: _drivers.map((driver) {
          return DropdownMenuItem<DriverInformation>(
            value: driver,
            child: Text(driver.name ?? '未知司机',
                style: TextStyle(color: themeData.colorScheme.onSurface)),
          );
        }).toList(),
        onChanged: (DriverInformation? newValue) {
          setState(() {
            _selectedDriver = newValue;
            _ownerNameController.text = newValue?.name ?? '';
            _idCardNumberController.text = newValue?.idCardNumber ?? '';
            _contactNumberController.text = newValue?.contactNumber ?? '';
          });
        },
        validator: (value) => value == null ? '车主姓名不能为空' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '添加新车辆',
          style: themeData.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        elevation: 3,
                        color: themeData.colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildTextField(
                                  '车牌号', _licensePlateController, themeData,
                                  required: true, prefix: '黑A'),
                              _buildTextField(
                                  '车辆类型', _vehicleTypeController, themeData,
                                  required: true),
                              _buildDriverDropdown(themeData),
                              _buildTextField(
                                  '身份证号码', _idCardNumberController, themeData,
                                  keyboardType: TextInputType.number),
                              _buildTextField(
                                  '联系电话', _contactNumberController, themeData,
                                  keyboardType: TextInputType.phone),
                              _buildTextField(
                                  '发动机号', _engineNumberController, themeData),
                              _buildTextField(
                                  '车架号', _frameNumberController, themeData),
                              _buildTextField(
                                  '车身颜色', _vehicleColorController, themeData),
                              _buildTextField('首次注册日期',
                                  _firstRegistrationDateController, themeData,
                                  readOnly: true, onTap: _pickDate),
                              _buildTextField(
                                  '当前状态', _currentStatusController, themeData),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 20.0),
                          textStyle: themeData.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        child: const Text('提交'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class VehicleDetailPage extends StatefulWidget {
  final VehicleInformation vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';

  final DashboardController? controller =
      Get.isRegistered<DashboardController>()
          ? Get.find<DashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await vehicleApi.initializeWithJwt();
      await _checkUserRole();
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      debugPrint('JWT Token: $jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');

      final decodedToken = JwtDecoder.decode(jwtToken);
      debugPrint('Decoded Token: $decodedToken');

      // Handle the roles field based on its type
      List<String> roles = [];
      final rawRoles = decodedToken['roles'];
      if (rawRoles is String) {
        roles = [rawRoles];
      } else if (rawRoles is List<dynamic>) {
        roles = rawRoles.map((r) => r.toString()).toList();
      } else {
        roles = [];
      }

      debugPrint('Roles from Token: $roles');
      setState(() => _isAdmin = roles.contains('ADMIN')); // Check for 'ADMIN'
      debugPrint('Is Admin: $_isAdmin');
    } catch (e) {
      debugPrint('Error in _checkUserRole: $e');
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData =
            controller?.currentBodyTheme.value ?? ThemeData.light();
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '确认删除',
            style: themeData.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          content: Text(
            '您确定要$action此车辆吗？此操作不可撤销。',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '取消',
                style: themeData.textTheme.labelLarge?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.error,
                foregroundColor: themeData.colorScheme.onError,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _editVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditVehiclePage(vehicle: widget.vehicle)),
    ).then((value) {
      if (value == true && mounted) Navigator.pop(context, true);
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value ?? '无',
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building VehicleDetailPage, isAdmin: $_isAdmin');
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '车辆详情',
          style: themeData.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
        actions: _isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editVehicle,
                  tooltip: '编辑车辆',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: themeData.colorScheme.error),
                  onPressed: () => _showDeleteConfirmationDialog('删除',
                      () => _deleteVehicle(widget.vehicle.vehicleId ?? 0)),
                  tooltip: '删除车辆',
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: themeData.textTheme.titleMedium?.copyWith(
                        color: themeData.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    child: Card(
                      elevation: 3,
                      color: themeData.colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem(
                                '车牌号', widget.vehicle.licensePlate, themeData),
                            _buildDetailItem(
                                '车辆类型', widget.vehicle.vehicleType, themeData),
                            _buildDetailItem(
                                '车主姓名', widget.vehicle.ownerName, themeData),
                            _buildDetailItem('身份证号码',
                                widget.vehicle.idCardNumber, themeData),
                            _buildDetailItem('联系电话',
                                widget.vehicle.contactNumber, themeData),
                            _buildDetailItem(
                                '发动机号', widget.vehicle.engineNumber, themeData),
                            _buildDetailItem(
                                '车架号', widget.vehicle.frameNumber, themeData),
                            _buildDetailItem(
                                '车身颜色', widget.vehicle.vehicleColor, themeData),
                            _buildDetailItem(
                                '首次注册日期',
                                formatDate(
                                    widget.vehicle.firstRegistrationDate),
                                themeData),
                            _buildDetailItem('当前状态',
                                widget.vehicle.currentStatus, themeData),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
