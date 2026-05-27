// ignore_for_file: use_build_context_synchronously
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/core/auth/role_utils.dart';
import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_business_page_chrome.dart';
import 'package:final_assignment_front/shared/dialogs/app_dialog.dart';
import 'package:final_assignment_front/utils/widgets/index.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// Utility methods for validation
bool isValidLicensePlate(String value) {
  final regex = RegExp(r'^[\u4e00-\u9fa5][A-Za-z][A-Za-z0-9]{5,6}$');
  return regex.hasMatch(value);
}

bool isValidIdCardNumber(String value) {
  final regex = RegExp(r'^\d{15}$|^\d{17}[\dX]$');
  return regex.hasMatch(value);
}

bool isValidPhoneNumber(String value) {
  final regex = RegExp(r'^1[3-9]\d{9}$');
  return regex.hasMatch(value);
}

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDate(DateTime? date) {
  if (date == null) return '无';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementState();
}

class _VehicleManagementState extends State<VehicleManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final UserManagementControllerApi userApi = UserManagementControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final List<VehicleInformation> _vehicleList = [];
  List<VehicleInformation> _filteredVehicleList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _currentDriverId;
  String? _currentDriverName;
  String? _currentDriverIdCardNumber;
  bool _hasMore = true;
  String _searchType = 'licensePlate';

  final UserDashboardController controller =
      Get.find<UserDashboardController>();

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
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub'] ?? '';
      if (username.isEmpty) throw Exception('JWT 中未找到用户名');
      AppLogger.debug('Current username from JWT: $username');

      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await userApi.initializeWithJwt();

      final profile = await Get.find<UserProfileService>().getProfile();
      final driverId = profile.driverId;
      if (driverId == null) {
        throw Exception('您的账户尚未关联司机档案');
      }
      final driverInfo = await driverApi.getDriver(driverId: driverId);
      _currentDriverId = driverId;
      _currentDriverName = driverInfo?.name ?? username;
      _currentDriverIdCardNumber = driverInfo?.idCardNumber;
      AppLogger.debug(
          'Current driver name: $_currentDriverName, idCardNumber: $_currentDriverIdCardNumber');

      if (_currentDriverIdCardNumber == null ||
          _currentDriverIdCardNumber!.isEmpty) {
        throw Exception('未找到身份证号码，请确保驾驶员信息已完善');
      }

      await _fetchUserVehicles(reset: true);
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserVehicles({bool reset = false, String? query}) async {
    if (_currentDriverId == null) {
      setState(() {
        _errorMessage = '缺少身份证号码，无法获取车辆信息';
        _isLoading = false;
      });
      return;
    }

    if (reset) {
      _hasMore = true;
      _vehicleList.clear();
      _filteredVehicleList.clear();
    }
    if (!_hasMore && query == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final searchQuery = query?.trim() ?? '';
    AppLogger.debug(
        'Fetching vehicles with query: $searchQuery, searchType: $_searchType');

    try {
      final vehicles = await vehicleApi.listVehicleRecordsByDriver(
        driverId: _currentDriverId!,
      );

      AppLogger.debug(
          'Vehicles fetched: ${vehicles.map((v) => v.toJson()).toList()}');
      setState(() {
        _vehicleList
          ..clear()
          ..addAll(vehicles);
        _hasMore = false;
        _applyFilters(searchQuery);
        if (_filteredVehicleList.isEmpty) {
          _errorMessage = searchQuery.isNotEmpty ? '未找到符合条件的车辆' : '您当前没有车辆记录';
        }
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('400')) {
          _errorMessage = '身份证号码或查询无效，请检查后重试';
        } else if (e.toString().contains('404')) {
          _vehicleList.clear();
          _filteredVehicleList.clear();
          _errorMessage =
              '未找到符合条件的车辆，可能${_searchType == 'vehicleType' ? '车辆类型' : '车牌号'} "$searchQuery" 不存在';
          _hasMore = false;
        } else {
          _errorMessage =
              e.toString().contains('403') ? '您没有权限查看车辆信息' : '获取车辆信息失败: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        _filteredVehicleList.clear();
        _filteredVehicleList.addAll(_vehicleList);
      } else {
        _filteredVehicleList = _vehicleList.where((vehicle) {
          final licensePlate = (vehicle.licensePlate ?? '').toLowerCase();
          final vehicleType = (vehicle.vehicleType ?? '').toLowerCase();
          if (_searchType == 'licensePlate') {
            return licensePlate.contains(searchQuery);
          } else {
            return vehicleType.contains(searchQuery);
          }
        }).toList();
      }
      if (_filteredVehicleList.isEmpty && _vehicleList.isNotEmpty) {
        _errorMessage = '未找到符合条件的车辆';
      } else {
        _errorMessage = _filteredVehicleList.isEmpty && _vehicleList.isEmpty
            ? '您当前没有车辆记录'
            : '';
      }
      AppLogger.debug('Filtered vehicles: ${_filteredVehicleList.length}');
    });
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    if (_currentDriverIdCardNumber == null) {
      AppLogger.debug('Cannot fetch suggestions: idCardNumber is null');
      return [];
    }
    try {
      if (_searchType == 'licensePlate') {
        AppLogger.debug(
            'Fetching license plate suggestions for idCardNumber: $_currentDriverIdCardNumber, prefix: $prefix');
        final suggestions = await vehicleApi.autocompleteVehiclePlates(
          prefix: prefix,
          idCard: _currentDriverIdCardNumber!,
          size: 5,
        );
        return suggestions
            .where((s) => s.toLowerCase().contains(prefix.toLowerCase()))
            .toList();
      } else {
        AppLogger.debug(
            'Fetching vehicle type suggestions for idCardNumber: $_currentDriverIdCardNumber, prefix: $prefix');
        final suggestions = await vehicleApi.autocompleteVehicleTypes(
          prefix: prefix,
          idCard: _currentDriverIdCardNumber!,
          size: 5,
        );
        return suggestions
            .where((s) => s.toLowerCase().contains(prefix.toLowerCase()))
            .toList();
      }
    } catch (e) {
      AppLogger.debug('Autocomplete failed: ${e.toString()}');
      return [];
    }
  }

  Future<void> _loadMoreVehicles() async {
    if (!_hasMore || _isLoading) return;
    await _fetchUserVehicles(query: _searchController.text);
  }

  Future<void> _refreshVehicles() async {
    _searchController.clear();
    await _fetchUserVehicles(reset: true);
  }

  Future<void> _searchVehicles() async {
    final query = _searchController.text.trim();
    _applyFilters(query);
  }

  void _createVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    ).then((value) {
      if (value == true && mounted) _fetchUserVehicles(reset: true);
    });
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => VehicleDetailPage(vehicle: vehicle)),
    ).then((value) {
      if (value == true && mounted) _fetchUserVehicles(reset: true);
    });
  }

  Future<void> _deleteVehicle(int vehicleId, String licensePlate) async {
    final confirmed = await AppDialog.showConfirmDelete(
      context,
      itemName: '该车辆',
      extraWarning: '此操作不可撤销。',
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await vehicleApi.deleteVehicle(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      _fetchUserVehicles(reset: true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    showUserBusinessToast(context, message: message, isError: isError);
  }

  Widget _buildSearchField(ThemeData themeData) {
    return SearchFilterBar(
      controller: _searchController,
      wrapInCard: true,
      cardElevation: 2,
      cardBorderRadius: 8,
      cardColor: themeData.colorScheme.surfaceContainer,
      cardPadding: const EdgeInsets.all(8),
      inputBorderRadius: 8,
      fillColor: themeData.colorScheme.surfaceContainerLowest,
      searchTypes: const [
        SearchFilterOption(
          value: 'licensePlate',
          label: '按车牌号',
          hintText: '搜索车牌号',
        ),
        SearchFilterOption(
          value: 'vehicleType',
          label: '按车辆类型',
          hintText: '搜索车辆类型',
        ),
      ],
      selectedSearchType: _searchType,
      onTypeChanged: (value) {
        setState(() {
          _searchType = value;
          _searchController.clear();
          _fetchUserVehicles(reset: true);
        });
      },
      suggestions: _fetchAutocompleteSuggestions,
      onSearch: (_) => _searchVehicles(),
      onChanged: _applyFilters,
      onClear: () {
        _searchController.clear();
        _fetchUserVehicles(reset: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: themeData,
        title: '车辆登记',
        pageType: DashboardPageType.user,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          DashboardPageBarAction(
            icon: Icons.refresh,
            tooltip: '刷新车辆',
            onPressed: _refreshVehicles,
          ),
          DashboardPageBarAction(
            icon: Icons.add,
            tooltip: '添加新车辆信息',
            onPressed: _createVehicle,
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _refreshVehicles,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                UserBusinessPageHeader(
                  title: '车辆登记',
                  subtitle: '维护车牌、车辆类型、车主和车辆状态等资料。',
                  icon: Icons.directions_car_filled_rounded,
                  badge: '${_filteredVehicleList.length} 辆车辆',
                  accentColor: const Color(0xFF7C8CF8),
                ),
                const SizedBox(height: 12),
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
                    child: _isLoading && _vehicleList.isEmpty
                        ? Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                    themeData.colorScheme.primary)))
                        : _errorMessage.isNotEmpty &&
                                _filteredVehicleList.isEmpty
                            ? Center(
                                child: UserBusinessStatusPanel(
                                  message: _errorMessage,
                                  kind: _errorMessage.contains('暂无') ||
                                          _errorMessage.contains('未找到')
                                      ? UserBusinessStatusKind.empty
                                      : UserBusinessStatusKind.error,
                                  actionLabel: userBusinessMessageNeedsLogin(
                                          _errorMessage)
                                      ? '重新登录'
                                      : null,
                                  onAction: userBusinessMessageNeedsLogin(
                                          _errorMessage)
                                      ? () => Navigator.pushReplacementNamed(
                                          context, '/login')
                                      : null,
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredVehicleList.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredVehicleList.length &&
                                      _hasMore) {
                                    return const Padding(
                                        padding: EdgeInsets.all(8.0));
                                  }
                                  final vehicle = _filteredVehicleList[index];
                                  return UserBusinessRecordCard(
                                    icon: Icons.directions_car_filled_rounded,
                                    title: vehicle.licensePlate ?? '未知车牌',
                                    badge: vehicle.currentStatus ?? '无状态',
                                    accentColor: const Color(0xFF7C8CF8),
                                    details: [
                                      '车辆类型：${vehicle.vehicleType ?? '未知类型'}',
                                      '车主：${vehicle.ownerName ?? '未知车主'}',
                                      '首次登记：${formatDate(vehicle.firstRegistrationDate)}',
                                    ],
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded),
                                          color: themeData.colorScheme.primary,
                                          onPressed: () =>
                                              _goToDetailPage(vehicle),
                                          tooltip: '编辑',
                                        ),
                                        IconButton(
                                          icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color:
                                                  themeData.colorScheme.error),
                                          onPressed: () => _deleteVehicle(
                                              vehicle.vehicleId ?? 0,
                                              vehicle.licensePlate ?? ''),
                                          tooltip: '删除',
                                        ),
                                      ],
                                    ),
                                    onTap: () => _goToDetailPage(vehicle),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class AddVehiclePage extends StatefulWidget {
  final VoidCallback? onVehicleAdded;

  const AddVehiclePage({super.key, this.onVehicleAdded});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final UserManagementControllerApi userApi = UserManagementControllerApi();
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
  int? _driverId;
  bool _isLoading = false;

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub'] ?? '';
      if (username.isEmpty) throw Exception('JWT 中未找到用户名');

      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await userApi.initializeWithJwt();
      await _preFillForm(username);
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _preFillForm(String username) async {
    final user = await _fetchUserManagement();
    final profile = await Get.find<UserProfileService>().getProfile();
    final driverId = profile.driverId;
    final driverInfo =
        driverId != null ? await driverApi.getDriver(driverId: driverId) : null;
    _driverId = driverId;

    AppLogger.debug('Fetched UserManagement: ${user?.toJson()}');
    AppLogger.debug('Fetched DriverInformation: ${driverInfo?.toString()}');

    if (driverInfo == null || driverInfo.name == null) {
      throw Exception(
          '无法获取驾驶员信息或姓名 (Driver ID: ${user?.userId}, Username: $username)');
    }

    setState(() {
      _ownerNameController.text = driverInfo.name!;
      _idCardNumberController.text = driverInfo.idCardNumber ?? '';
      _contactNumberController.text =
          driverInfo.contactNumber ?? user?.contactNumber ?? '';
      AppLogger.debug('Set ownerNameController.text to: ${driverInfo.name}');
    });
  }

  Future<UserManagement?> _fetchUserManagement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('userName');
      if (storedUsername == null || storedUsername.isEmpty) {
        AppLogger.debug('Username missing when fetching user info');
        return null;
      }
      await userApi.initializeWithJwt();
      return await userApi.searchUsersByUsername(username: storedUsername);
    } catch (e) {
      AppLogger.error('Error fetching UserManagement: $e');
      return null;
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

    final licensePlate = '黑A${_licensePlateController.text.trim()}';
    if (!isValidLicensePlate(licensePlate)) {
      _showSnackBar('车牌号格式无效，请输入有效车牌号（例如：黑A12345）', isError: true);
      return;
    }

    if (await vehicleApi.vehicleLicensePlateExists(
        licensePlate: licensePlate)) {
      _showSnackBar('车牌号已存在，请使用其他车牌号', isError: true);
      return;
    }

    final idCardNumber = _idCardNumberController.text.trim();
    if (idCardNumber.isEmpty) {
      _showSnackBar('请到个人-用户信息管理处填写身份证号码', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final vehicle = VehicleInformation(
        vehicleId: null,
        driverId: _driverId,
        licensePlate: licensePlate,
        vehicleType: _vehicleTypeController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerIdCard: idCardNumber,
        ownerContact: _contactNumberController.text.trim().isEmpty
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
            : DateTime.parse(
                '${_firstRegistrationDateController.text.trim()}T00:00:00.000'),
        status: _currentStatusController.text.trim().isEmpty
            ? 'Active'
            : _currentStatusController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.createVehicle(
        vehicle: vehicle,
        idempotencyKey: idempotencyKey,
      );

      _showSnackBar('创建车辆成功！');
      if (mounted) {
        Navigator.pop(context, true);
        widget.onVehicleAdded?.call();
      }
    } catch (e) {
      _showSnackBar('创建车辆失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    showUserBusinessToast(context, message: message, isError: isError);
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
      String? prefix,
      int? maxLength,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: AppTextFormField(
        label: label,
        controller: controller,
        helperText: label == '车牌号'
            ? '请输入车牌号后缀，例如：12345'
            : label == '身份证号码'
                ? '请输入15或18位身份证号码'
                : label == '联系电话'
                    ? '请输入11位手机号码'
                    : null,
        prefixText: prefix,
        suffix: readOnly && label == '首次注册日期'
            ? Icon(Icons.calendar_today,
                size: 18, color: themeData.colorScheme.primary)
            : null,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        validator: validator ??
            (value) {
              final trimmedValue = value?.trim() ?? '';
              if (required && trimmedValue.isEmpty) return '$label不能为空';
              if (label == '车牌号' && trimmedValue.isNotEmpty) {
                final fullPlate = '黑A$trimmedValue';
                if (fullPlate.length > 20) return '车牌号不能超过20个字符';
                if (!isValidLicensePlate(fullPlate)) {
                  return '车牌号格式无效（例如：黑A12345）';
                }
              }
              if (label == '车辆类型' && trimmedValue.length > 50) {
                return '车辆类型不能超过50个字符';
              }
              if (label == '车主姓名' && trimmedValue.length > 100) {
                return '车主姓名不能超过100个字符';
              }
              if (label == '身份证号码') {
                if (trimmedValue.isEmpty) return '身份证号码不能为空';
                if (trimmedValue.length > 18) return '身份证号码不能超过18个字符';
                if (!isValidIdCardNumber(trimmedValue)) return '身份证号码格式无效';
              }
              if (label == '联系电话' && trimmedValue.isNotEmpty) {
                if (trimmedValue.length > 20) return '联系电话不能超过20个字符';
                if (!isValidPhoneNumber(trimmedValue)) return '请输入有效的11位手机号码';
              }
              if (label == '发动机号' && trimmedValue.length > 50) {
                return '发动机号不能超过50个字符';
              }
              if (label == '车架号' && trimmedValue.length > 50) {
                return '车架号不能超过50个字符';
              }
              if (label == '车身颜色' && trimmedValue.length > 50) {
                return '车身颜色不能超过50个字符';
              }
              if (label == '首次注册日期' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) return '首次注册日期不能晚于当前日期';
              }
              if (label == '当前状态' && trimmedValue.length > 50) {
                return '当前状态不能超过50个字符';
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    final hideAppBar = widget.onVehicleAdded != null;
    return DashboardPageTemplate(
      theme: themeData,
      title: '添加新车辆',
      pageType: hideAppBar ? DashboardPageType.custom : DashboardPageType.user,
      bodyIsScrollable: true,
      padding: EdgeInsets.zero,
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
                              if (widget.onVehicleAdded != null)
                                Text('您当前没有车辆记录，请添加新车辆',
                                    style: themeData.textTheme.titleMedium
                                        ?.copyWith(
                                            color:
                                                themeData.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold)),
                              if (widget.onVehicleAdded != null)
                                const SizedBox(height: 16),
                              _buildTextField(
                                  '车牌号', _licensePlateController, themeData,
                                  required: true, prefix: '黑A', maxLength: 17),
                              _buildTextField(
                                  '车辆类型', _vehicleTypeController, themeData,
                                  required: true, maxLength: 50),
                              _buildTextField(
                                  '车主姓名', _ownerNameController, themeData,
                                  required: true,
                                  readOnly: true,
                                  maxLength: 100),
                              _buildTextField(
                                  '身份证号码', _idCardNumberController, themeData,
                                  required: true,
                                  keyboardType: TextInputType.number,
                                  maxLength: 18),
                              _buildTextField(
                                  '联系电话', _contactNumberController, themeData,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 20),
                              _buildTextField(
                                  '发动机号', _engineNumberController, themeData,
                                  maxLength: 50),
                              _buildTextField(
                                  '车架号', _frameNumberController, themeData,
                                  maxLength: 50),
                              _buildTextField(
                                  '车身颜色', _vehicleColorController, themeData,
                                  maxLength: 50),
                              _buildTextField('首次注册日期',
                                  _firstRegistrationDateController, themeData,
                                  readOnly: true, onTap: _pickDate),
                              _buildTextField(
                                  '当前状态', _currentStatusController, themeData,
                                  maxLength: 50),
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

class EditVehiclePage extends StatefulWidget {
  final VehicleInformation vehicle;

  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final UserManagementControllerApi userApi = UserManagementControllerApi();
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
  int? _driverId;
  bool _isLoading = false;

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
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
      await userApi.initializeWithJwt();
      await _initializeFields();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeFields() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) throw Exception('未找到 JWT');
    final decodedToken = JwtDecoder.decode(jwtToken);
    final username = decodedToken['sub'] ?? '';
    if (username.isEmpty) throw Exception('JWT 中未找到用户名');

    final profile = await Get.find<UserProfileService>().getProfile();
    final driverId = profile.driverId;
    final driverInfo =
        driverId != null ? await driverApi.getDriver(driverId: driverId) : null;
    _driverId = driverId;
    if (driverInfo == null || driverInfo.name == null) {
      throw Exception('无法获取驾驶员信息或姓名');
    }

    setState(() {
      _licensePlateController.text =
          widget.vehicle.licensePlate?.replaceFirst('黑A', '') ?? '';
      _vehicleTypeController.text = widget.vehicle.vehicleType ?? '';
      _ownerNameController.text = driverInfo.name!;
      _idCardNumberController.text = widget.vehicle.idCardNumber ?? '';
      _contactNumberController.text = widget.vehicle.contactNumber ?? '';
      _engineNumberController.text = widget.vehicle.engineNumber ?? '';
      _frameNumberController.text = widget.vehicle.frameNumber ?? '';
      _vehicleColorController.text = widget.vehicle.vehicleColor ?? '';
      _firstRegistrationDateController.text =
          formatDate(widget.vehicle.firstRegistrationDate);
      _currentStatusController.text = widget.vehicle.currentStatus ?? '';
    });
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

    final newLicensePlate = '黑A${_licensePlateController.text.trim()}';
    if (!isValidLicensePlate(newLicensePlate)) {
      _showSnackBar('车牌号格式无效，请输入有效车牌号（例如：黑A12345）', isError: true);
      return;
    }

    if (newLicensePlate != widget.vehicle.licensePlate &&
        await vehicleApi.vehicleLicensePlateExists(
            licensePlate: newLicensePlate)) {
      _showSnackBar('车牌号已存在，请使用其他车牌号', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final vehicle = VehicleInformation(
        vehicleId: widget.vehicle.vehicleId,
        driverId: widget.vehicle.driverId ?? _driverId,
        licensePlate: newLicensePlate,
        vehicleType: _vehicleTypeController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerIdCard: _idCardNumberController.text.trim(),
        ownerContact: _contactNumberController.text.trim().isEmpty
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
            : DateTime.parse(
                '${_firstRegistrationDateController.text.trim()}T00:00:00.000'),
        status: _currentStatusController.text.trim().isEmpty
            ? 'Active'
            : _currentStatusController.text.trim(),
      );

      final idempotencyKey = generateIdempotencyKey();
      await vehicleApi.updateVehicle(
        vehicleId: widget.vehicle.vehicleId ?? 0,
        vehicle: vehicle,
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
    showUserBusinessToast(context, message: message, isError: isError);
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
      String? prefix,
      int? maxLength,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: AppTextFormField(
        label: label,
        controller: controller,
        helperText: label == '车牌号'
            ? '请输入车牌号后缀，例如：12345'
            : label == '身份证号码'
                ? '请输入15或18位身份证号码'
                : label == '联系电话'
                    ? '请输入11位手机号码'
                    : null,
        hintText: readOnly && label == '身份证号码' ? '请在用户信息管理中修改身份证号码' : null,
        prefixText: prefix,
        suffix: readOnly && label == '首次注册日期'
            ? Icon(Icons.calendar_today,
                size: 18, color: themeData.colorScheme.primary)
            : null,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        validator: validator ??
            (value) {
              final trimmedValue = value?.trim() ?? '';
              if (required && trimmedValue.isEmpty) return '$label不能为空';
              if (label == '车牌号' && trimmedValue.isNotEmpty) {
                final fullPlate = '黑A$trimmedValue';
                if (fullPlate.length > 20) return '车牌号不能超过20个字符';
                if (!isValidLicensePlate(fullPlate)) {
                  return '车牌号格式无效（例如：黑A12345）';
                }
              }
              if (label == '车辆类型' && trimmedValue.length > 50) {
                return '车辆类型不能超过50个字符';
              }
              if (label == '车主姓名' && trimmedValue.length > 100) {
                return '车主姓名不能超过100个字符';
              }
              if (label == '身份证号码') {
                if (trimmedValue.isEmpty) return '身份证号码不能为空';
                if (trimmedValue.length > 18) return '身份证号码不能超过18个字符';
                if (!isValidIdCardNumber(trimmedValue)) return '身份证号码格式无效';
              }
              if (label == '联系电话' && trimmedValue.isNotEmpty) {
                if (trimmedValue.length > 20) return '联系电话不能超过20个字符';
                if (!isValidPhoneNumber(trimmedValue)) return '请输入有效的11位手机号码';
              }
              if (label == '发动机号' && trimmedValue.length > 50) {
                return '发动机号不能超过50个字符';
              }
              if (label == '车架号' && trimmedValue.length > 50) {
                return '车架号不能超过50个字符';
              }
              if (label == '车身颜色' && trimmedValue.length > 50) {
                return '车身颜色不能超过50个字符';
              }
              if (label == '首次注册日期' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) return '首次注册日期不能晚于当前日期';
              }
              if (label == '当前状态' && trimmedValue.length > 50) {
                return '当前状态不能超过50个字符';
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    return DashboardPageTemplate(
      theme: themeData,
      title: '编辑车辆信息',
      pageType: DashboardPageType.user,
      bodyIsScrollable: true,
      padding: EdgeInsets.zero,
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
                                  required: true, prefix: '黑A', maxLength: 17),
                              _buildTextField(
                                  '车辆类型', _vehicleTypeController, themeData,
                                  required: true, maxLength: 50),
                              _buildTextField(
                                  '车主姓名', _ownerNameController, themeData,
                                  required: true,
                                  readOnly: true,
                                  maxLength: 100),
                              _buildTextField(
                                  '身份证号码', _idCardNumberController, themeData,
                                  required: true,
                                  readOnly: true,
                                  keyboardType: TextInputType.number,
                                  maxLength: 18),
                              _buildTextField(
                                  '联系电话', _contactNumberController, themeData,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 20),
                              _buildTextField(
                                  '发动机号', _engineNumberController, themeData,
                                  maxLength: 50),
                              _buildTextField(
                                  '车架号', _frameNumberController, themeData,
                                  maxLength: 50),
                              _buildTextField(
                                  '车身颜色', _vehicleColorController, themeData,
                                  maxLength: 50),
                              _buildTextField('首次注册日期',
                                  _firstRegistrationDateController, themeData,
                                  readOnly: true, onTap: _pickDate),
                              _buildTextField(
                                  '当前状态', _currentStatusController, themeData,
                                  maxLength: 50),
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

class VehicleDetailPage extends StatefulWidget {
  final VehicleInformation vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final UserManagementControllerApi userApi = UserManagementControllerApi();
  bool _isLoading = false;
  bool _isEditable = false;
  String _errorMessage = '';
  String? _currentDriverIdCardNumber;

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub'] ?? '';
      if (username.isEmpty) throw Exception('JWT 中未找到用户名');

      await vehicleApi.initializeWithJwt();
      await userApi.initializeWithJwt();
      final profile = await Get.find<UserProfileService>().getProfile();
      final driverId = profile.driverId;
      final driverInfo =
          driverId != null ? await _fetchDriverInformation(driverId) : null;
      _currentDriverIdCardNumber = driverInfo?.idCardNumber;
      await _checkUserRole();
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<DriverInformation?> _fetchDriverInformation(int driverId) async {
    try {
      final driverApi = DriverInformationControllerApi();
      await driverApi.initializeWithJwt();
      return await driverApi.getDriver(driverId: driverId);
    } catch (e) {
      AppLogger.error('Failed to fetch DriverInformation: $e');
      return null;
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final roles = decodedToken['roles']?.toString().split(',') ?? [];
      setState(() {
        _isEditable = RoleUtils.isAdminRole(roles) ||
            (_currentDriverIdCardNumber != null &&
                _currentDriverIdCardNumber == widget.vehicle.idCardNumber);
      });
    } catch (e) {
      setState(() => _errorMessage = '加载权限失败: $e');
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    setState(() => _isLoading = true);
    try {
      await vehicleApi.deleteVehicle(vehicleId: vehicleId);
      _showSnackBar('删除车辆成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    showUserBusinessToast(context, message: message, isError: isError);
  }

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: themeData.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onSurface)),
          Expanded(
              child: Text(value,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      Future<void> Function() onConfirm) async {
    final confirmed = await AppDialog.showConfirmDelete(
      context,
      itemName: '该车辆',
      extraWarning: '此操作不可撤销。',
    );
    if (confirmed == true) {
      await onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    if (_errorMessage.isNotEmpty) {
      return DashboardPageTemplate(
        theme: themeData,
        title: '车辆详情',
        pageType: DashboardPageType.custom,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage,
                  style: themeData.textTheme.titleMedium?.copyWith(
                      color: themeData.colorScheme.error,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
              if (_errorMessage.contains('登录'))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.primary,
                        foregroundColor: themeData.colorScheme.onPrimary),
                    child: const Text('前往登录'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final actions = <DashboardPageBarAction>[];
    if (_isEditable) {
      actions.addAll([
        DashboardPageBarAction(
          icon: Icons.edit,
          tooltip: '编辑车辆信息',
          onPressed: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditVehiclePage(vehicle: widget.vehicle)))
                .then((value) {
              if (value == true && mounted) {
                Navigator.pop(context, true);
              }
            });
          },
        ),
        DashboardPageBarAction(
          icon: Icons.delete,
          color: themeData.colorScheme.error,
          tooltip: '删除车辆',
          onPressed: () => _showDeleteConfirmationDialog(
              () => _deleteVehicle(widget.vehicle.vehicleId ?? 0)),
        ),
      ]);
    }

    return DashboardPageTemplate(
      theme: themeData,
      title: '车辆详情',
      pageType: DashboardPageType.user,
      actions: actions,
      bodyIsScrollable: true,
      padding: EdgeInsets.zero,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(themeData.colorScheme.primary)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                color: themeData.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('车辆类型',
                            widget.vehicle.vehicleType ?? '未知类型', themeData),
                        _buildDetailRow('车牌号',
                            widget.vehicle.licensePlate ?? '未知车牌', themeData),
                        _buildDetailRow('车主姓名',
                            widget.vehicle.ownerName ?? '未知车主', themeData),
                        _buildDetailRow('车辆状态',
                            widget.vehicle.currentStatus ?? '无', themeData),
                        _buildDetailRow('身份证号码',
                            widget.vehicle.idCardNumber ?? '无', themeData),
                        _buildDetailRow('联系电话',
                            widget.vehicle.contactNumber ?? '无', themeData),
                        _buildDetailRow('发动机号',
                            widget.vehicle.engineNumber ?? '无', themeData),
                        _buildDetailRow('车架号',
                            widget.vehicle.frameNumber ?? '无', themeData),
                        _buildDetailRow('车身颜色',
                            widget.vehicle.vehicleColor ?? '无', themeData),
                        _buildDetailRow(
                            '首次注册日期',
                            formatDate(widget.vehicle.firstRegistrationDate),
                            themeData),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
