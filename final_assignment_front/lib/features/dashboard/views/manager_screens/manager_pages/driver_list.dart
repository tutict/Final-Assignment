import 'dart:developer' as developer;
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '无';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

class DriverList extends StatefulWidget {
  const DriverList({super.key});

  @override
  State<DriverList> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverList> {
  late DriverInformationControllerApi driverApi;
  List<DriverInformation> _drivers = [];
  List<DriverInformation> _filteredDrivers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  late ScrollController _scrollController;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();
    _scrollController = ScrollController();
    _loadDrivers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _driverLicenseNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await driverApi.initializeWithJwt();
      final drivers = await driverApi.apiDriversGet() ?? [];
      setState(() {
        _drivers = drivers;
        _filteredDrivers = drivers;
        _isLoading = false;
        if (_drivers.isEmpty) _errorMessage = '暂无司机信息';
      });
      developer.log('Loaded drivers: ${_drivers.length}');
    } catch (e) {
      developer.log('Error fetching drivers: $e',
          stackTrace: StackTrace.current);
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e);
        if (e.toString().contains('未登录') || e.toString().contains('403')) {
          _redirectToLogin();
        }
      });
    }
  }

  void _applyFilters() {
    final name = _nameController.text.trim().toLowerCase();
    final idCard = _idCardNumberController.text.trim().toLowerCase();
    final license = _driverLicenseNumberController.text.trim().toLowerCase();

    setState(() {
      _isLoading = false;
      _errorMessage = '';
      if (name.isEmpty && idCard.isEmpty && license.isEmpty) {
        _filteredDrivers = _drivers;
      } else {
        _filteredDrivers = _drivers.where((driver) {
          final driverName = (driver.name ?? '').toLowerCase();
          final driverIdCard = (driver.idCardNumber ?? '').toLowerCase();
          final driverLicense =
              (driver.driverLicenseNumber ?? '').toLowerCase();
          return (name.isEmpty || driverName.contains(name)) &&
              (idCard.isEmpty || driverIdCard.contains(idCard)) &&
              (license.isEmpty || driverLicense.contains(license));
        }).toList();
      }
      if (_filteredDrivers.isEmpty) {
        _errorMessage =
            name.isNotEmpty || idCard.isNotEmpty || license.isNotEmpty
                ? '未找到符合条件的司机信息'
                : '暂无司机信息';
      }
      developer.log('Filtered drivers: ${_filteredDrivers.length}');
    });
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Get.offAllNamed(AppPages.login);
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              color: isError
                  ? themeData.colorScheme.onError
                  : themeData.colorScheme.onPrimary),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  void _goToDetailPage(DriverInformation driver) {
    Get.to(() => DriverDetailPage(driver: driver))?.then((value) {
      if (value == true && mounted) _loadDrivers();
    });
  }

  Widget _buildSearchBar(ThemeData themeData) {
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: '按姓名搜索',
                      labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                          color: themeData.colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.person,
                          color: themeData.colorScheme.primary),
                      suffixIcon: _nameController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color:
                                      themeData.colorScheme.onSurfaceVariant),
                              onPressed: () {
                                _nameController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 16.0),
                    ),
                    onChanged: (value) => _applyFilters(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idCardNumberController,
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: '按身份证号搜索',
                      labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                          color: themeData.colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.card_membership,
                          color: themeData.colorScheme.primary),
                      suffixIcon: _idCardNumberController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color:
                                      themeData.colorScheme.onSurfaceVariant),
                              onPressed: () {
                                _idCardNumberController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 16.0),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _applyFilters(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _driverLicenseNumberController,
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: '按驾驶证号搜索',
                      labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                          color: themeData.colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.drive_eta,
                          color: themeData.colorScheme.primary),
                      suffixIcon: _driverLicenseNumberController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color:
                                      themeData.colorScheme.onSurfaceVariant),
                              onPressed: () {
                                _driverLicenseNumberController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 16.0),
                    ),
                    onChanged: (value) => _applyFilters(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(DriverInformation driver, ThemeData themeData) {
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        title: Text(
          '姓名: ${driver.name ?? "未知"} (ID: ${driver.driverId ?? "无"})',
          style: themeData.textTheme.titleMedium?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '驾驶证号: ${driver.driverLicenseNumber ?? "无"}',
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
              ),
              Text(
                '联系电话: ${driver.contactNumber ?? "无"}',
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
              ),
              Text(
                '出生日期: ${formatDateTime(driver.birthdate)}',
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        trailing: Icon(
          CupertinoIcons.forward,
          color: themeData.colorScheme.primary,
          size: 18,
        ),
        onTap: () => _goToDetailPage(driver),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '司机信息列表',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _loadDrivers,
                  child: Icon(
                    CupertinoIcons.refresh,
                    color: themeData.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () =>
                      Get.to(() => const AddDriverPage())?.then((value) {
                    if (value == true && mounted) _loadDrivers();
                  }),
                  child: Icon(
                    CupertinoIcons.add,
                    color: themeData.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
              ],
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchBar(themeData),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CupertinoActivityIndicator(
                              color: themeData.colorScheme.primary,
                              radius: 16.0,
                            ),
                          )
                        : _errorMessage.isNotEmpty && _filteredDrivers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.exclamationmark_triangle,
                                      color: themeData.colorScheme.error,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage,
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        color: themeData.colorScheme.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_errorMessage.contains('无权限'))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 20.0),
                                        child: ElevatedButton(
                                          onPressed: _redirectToLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                themeData.colorScheme.primary,
                                            foregroundColor:
                                                themeData.colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12.0)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24.0,
                                                vertical: 12.0),
                                          ),
                                          child: const Text('重新登录'),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : CupertinoScrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                thickness: 6.0,
                                thicknessWhileDragging: 10.0,
                                child: RefreshIndicator(
                                  onRefresh: _loadDrivers,
                                  color: themeData.colorScheme.primary,
                                  backgroundColor:
                                      themeData.colorScheme.surfaceContainer,
                                  child: _filteredDrivers.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                CupertinoIcons.person_2,
                                                color: themeData.colorScheme
                                                    .onSurfaceVariant,
                                                size: 48,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                '暂无司机信息',
                                                style: themeData
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: themeData.colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _scrollController,
                                          itemCount: _filteredDrivers.length,
                                          itemBuilder: (context, index) {
                                            final driver =
                                                _filteredDrivers[index];
                                            return _buildDriverCard(
                                                driver, themeData);
                                          },
                                        ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final driverApi = DriverInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _firstLicenseDateController =
      TextEditingController();
  final TextEditingController _allowedVehicleTypeController =
      TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  bool _isLoading = false;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await driverApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _driverLicenseNumberController.dispose();
    _genderController.dispose();
    _birthdateController.dispose();
    _firstLicenseDateController.dispose();
    _allowedVehicleTypeController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _submitDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final driver = DriverInformation(
        name: _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
        birthdate: _birthdateController.text.trim().isEmpty
            ? null
            : DateTime.parse('${_birthdateController.text.trim()}T00:00:00'),
        firstLicenseDate: _firstLicenseDateController.text.trim().isEmpty
            ? null
            : DateTime.parse(
                '${_firstLicenseDateController.text.trim()}T00:00:00'),
        allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: _issueDateController.text.trim().isEmpty
            ? null
            : DateTime.parse('${_issueDateController.text.trim()}T00:00:00'),
        expiryDate: _expiryDateController.text.trim().isEmpty
            ? null
            : DateTime.parse('${_expiryDateController.text.trim()}T00:00:00'),
      );

      await driverApi.apiDriversPost(
        driverInformation: driver,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSnackBar('创建司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              color: isError
                  ? themeData.colorScheme.onError
                  : themeData.colorScheme.onPrimary),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController textController) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => Theme(
        data: controller.currentBodyTheme.value.copyWith(
          colorScheme: controller.currentBodyTheme.value.colorScheme.copyWith(
            primary: controller.currentBodyTheme.value.colorScheme.primary,
            onPrimary: controller.currentBodyTheme.value.colorScheme.onPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                foregroundColor:
                    controller.currentBodyTheme.value.colorScheme.primary),
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        textController.text = formatDateTime(pickedDate);
      });
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '添加新司机',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Card(
                          elevation: 4,
                          color: themeData.colorScheme.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTextField(themeData, '姓名 *', Icons.person,
                                    _nameController,
                                    required: true),
                                const SizedBox(height: 16),
                                _buildTextField(
                                    themeData,
                                    '身份证号码 *',
                                    Icons.card_membership,
                                    _idCardNumberController,
                                    keyboardType: TextInputType.number,
                                    required: true),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '联系电话 *',
                                    Icons.phone, _contactNumberController,
                                    keyboardType: TextInputType.phone,
                                    required: true),
                                const SizedBox(height: 16),
                                _buildTextField(
                                    themeData,
                                    '驾驶证号 *',
                                    Icons.drive_eta,
                                    _driverLicenseNumberController,
                                    required: true),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '性别',
                                    Icons.person_outline, _genderController),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '出生日期',
                                    Icons.calendar_today, _birthdateController,
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(_birthdateController)),
                                const SizedBox(height: 16),
                                _buildTextField(
                                    themeData,
                                    '首次领证日期',
                                    Icons.calendar_today,
                                    _firstLicenseDateController,
                                    readOnly: true,
                                    onTap: () => _selectDate(
                                        _firstLicenseDateController)),
                                const SizedBox(height: 16),
                                _buildTextField(
                                    themeData,
                                    '允许驾驶车辆类型',
                                    Icons.directions_car,
                                    _allowedVehicleTypeController),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '发证日期',
                                    Icons.calendar_today, _issueDateController,
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(_issueDateController)),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '有效期截止日期',
                                    Icons.calendar_today, _expiryDateController,
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(_expiryDateController)),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _submitDriver,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        themeData.colorScheme.primary,
                                    foregroundColor:
                                        themeData.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14.0, horizontal: 24.0),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    '提交',
                                    style: themeData.textTheme.labelLarge
                                        ?.copyWith(
                                      color: themeData.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField(ThemeData themeData, String label, IconData icon,
      TextEditingController controller,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        suffixIcon: readOnly
            ? Icon(Icons.calendar_today, color: themeData.colorScheme.primary)
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainer,
        labelStyle: themeData.textTheme.bodyMedium
            ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      ),
      style: themeData.textTheme.bodyMedium
          ?.copyWith(color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator:
          required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
    );
  }
}

class EditDriverPage extends StatefulWidget {
  final DriverInformation driver;

  const EditDriverPage({super.key, required this.driver});

  @override
  State<EditDriverPage> createState() => _EditDriverPageState();
}

class _EditDriverPageState extends State<EditDriverPage> {
  final driverApi = DriverInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _firstLicenseDateController =
      TextEditingController();
  final TextEditingController _allowedVehicleTypeController =
      TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  bool _isLoading = false;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await driverApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeFields() {
    _nameController.text = widget.driver.name ?? '';
    _idCardNumberController.text = widget.driver.idCardNumber ?? '';
    _contactNumberController.text = widget.driver.contactNumber ?? '';
    _driverLicenseNumberController.text =
        widget.driver.driverLicenseNumber ?? '';
    _genderController.text = widget.driver.gender ?? '';
    _birthdateController.text = formatDateTime(widget.driver.birthdate);
    _firstLicenseDateController.text =
        formatDateTime(widget.driver.firstLicenseDate);
    _allowedVehicleTypeController.text = widget.driver.allowedVehicleType ?? '';
    _issueDateController.text = formatDateTime(widget.driver.issueDate);
    _expiryDateController.text = formatDateTime(widget.driver.expiryDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _driverLicenseNumberController.dispose();
    _genderController.dispose();
    _birthdateController.dispose();
    _firstLicenseDateController.dispose();
    _allowedVehicleTypeController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _submitDriver() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.driver.driverId == null) {
      _showSnackBar('司机ID无效，无法更新', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final driver = DriverInformation(
        driverId: widget.driver.driverId,
        name: _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
        birthdate: _birthdateController.text.trim().isEmpty
            ? null
            : DateTime.parse('${_birthdateController.text.trim()}T00:00:00'),
        firstLicenseDate: _firstLicenseDateController.text.trim().isEmpty
            ? null
            : DateTime.parse(
                '${_firstLicenseDateController.text.trim()}T00:00:00'),
        allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: _issueDateController.text.trim().isEmpty
            ? null
            : DateTime.parse('${_issueDateController.text.trim()}T00:00:00'),
        expiryDate: _expiryDateController.text.trim().isEmpty
            ? null
            : DateTime.parse('${_expiryDateController.text.trim()}T00:00:00'),
      );

      await driverApi.apiDriversDriverIdPut(
        driverId: widget.driver.driverId!,
        driverInformation: driver,
        idempotencyKey: generateIdempotencyKey(),
      );
      _showSnackBar('更新司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              color: isError
                  ? themeData.colorScheme.onError
                  : themeData.colorScheme.onPrimary),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController textController) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(textController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => Theme(
        data: controller.currentBodyTheme.value.copyWith(
          colorScheme: controller.currentBodyTheme.value.colorScheme.copyWith(
            primary: controller.currentBodyTheme.value.colorScheme.primary,
            onPrimary: controller.currentBodyTheme.value.colorScheme.onPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                foregroundColor:
                    controller.currentBodyTheme.value.colorScheme.primary),
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        textController.text = formatDateTime(pickedDate);
      });
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '编辑司机信息',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Card(
                          elevation: 4,
                          color: themeData.colorScheme.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTextField(themeData, '姓名 *', Icons.person,
                                    _nameController,
                                    required: true),
                                const SizedBox(height: 16),
                                _buildTextField(
                                    themeData,
                                    '身份证号码 *',
                                    Icons.card_membership,
                                    _idCardNumberController,
                                    keyboardType: TextInputType.number,
                                    required: true),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '联系电话 *',
                                    Icons.phone, _contactNumberController,
                                    keyboardType: TextInputType.phone,
                                    required: true),
                                const SizedBox(height: 16),
                                _buildTextField(
                                    themeData,
                                    '驾驶证号 *',
                                    Icons.drive_eta,
                                    _driverLicenseNumberController,
                                    required: true),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '性别',
                                    Icons.person_outline, _genderController),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '出生日期',
                                    Icons.calendar_today, _birthdateController,
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(_birthdateController)),
                                const SizedBox(height: 16),
                                _buildTextField(
                                    themeData,
                                    '首次领证日期',
                                    Icons.calendar_today,
                                    _firstLicenseDateController,
                                    readOnly: true,
                                    onTap: () => _selectDate(
                                        _firstLicenseDateController)),
                                const SizedBox(height: 16),
                                _buildTextField(
                                    themeData,
                                    '允许驾驶车辆类型',
                                    Icons.directions_car,
                                    _allowedVehicleTypeController),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '发证日期',
                                    Icons.calendar_today, _issueDateController,
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(_issueDateController)),
                                const SizedBox(height: 16),
                                _buildTextField(themeData, '有效期截止日期',
                                    Icons.calendar_today, _expiryDateController,
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(_expiryDateController)),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _submitDriver,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        themeData.colorScheme.primary,
                                    foregroundColor:
                                        themeData.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14.0, horizontal: 24.0),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    '保存',
                                    style: themeData.textTheme.labelLarge
                                        ?.copyWith(
                                      color: themeData.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField(ThemeData themeData, String label, IconData icon,
      TextEditingController controller,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        suffixIcon: readOnly
            ? Icon(Icons.calendar_today, color: themeData.colorScheme.primary)
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainer,
        labelStyle: themeData.textTheme.bodyMedium
            ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      ),
      style: themeData.textTheme.bodyMedium
          ?.copyWith(color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator:
          required ? (value) => value!.isEmpty ? '$label不能为空' : null : null,
    );
  }
}

class DriverDetailPage extends StatefulWidget {
  final DriverInformation driver;

  const DriverDetailPage({super.key, required this.driver});

  @override
  State<DriverDetailPage> createState() => _DriverDetailPageState();
}

class _DriverDetailPageState extends State<DriverDetailPage> {
  final driverApi = DriverInformationControllerApi();
  late DriverInformation _driver;
  bool _isLoading = false;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _driver = widget.driver;
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await driverApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDriver(int? driverId) async {
    if (driverId == null) {
      _showSnackBar('司机ID无效，无法删除', isError: true);
      return;
    }
    final confirmed = await _showConfirmationDialog('确认删除', '您确定要删除此司机信息吗？');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await driverApi.apiDriversDriverIdDelete(driverId: driverId);
      _showSnackBar('删除司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
              color: isError
                  ? themeData.colorScheme.onError
                  : themeData.colorScheme.onPrimary),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    if (!mounted) return false;
    final themeData = controller.currentBodyTheme.value;
    return await showDialog<bool>(
          context: context,
          builder: (context) => Theme(
            data: themeData,
            child: AlertDialog(
              backgroundColor: themeData.colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: Text(
                title,
                style: themeData.textTheme.titleLarge?.copyWith(
                  color: themeData.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                content,
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    '取消',
                    style: themeData.textTheme.labelLarge?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    '确定',
                    style: themeData.textTheme.labelLarge?.copyWith(
                      color: themeData.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<void> _loadDriverDetails() async {
    if (_driver.driverId == null) {
      _showSnackBar('司机ID无效，无法加载详情', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final updatedDriver =
          await driverApi.apiDriversDriverIdGet(driverId: _driver.driverId!);
      if (updatedDriver != null && mounted) {
        setState(() => _driver = updatedDriver);
      }
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      final driverId = _driver.driverId?.toString() ?? '未提供';
      final name = _driver.name ?? '未知';
      final idCard = _driver.idCardNumber ?? '无';
      final contact = _driver.contactNumber ?? '无';
      final license = _driver.driverLicenseNumber ?? '无';
      final gender = _driver.gender ?? '未知';
      final birthdate = formatDateTime(_driver.birthdate);
      final firstLicenseDate = formatDateTime(_driver.firstLicenseDate);
      final allowedVehicleType = _driver.allowedVehicleType ?? '无';
      final issueDate = formatDateTime(_driver.issueDate);
      final expiryDate = formatDateTime(_driver.expiryDate);

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          backgroundColor: themeData.colorScheme.surface,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '司机详细信息',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                CupertinoIcons.back,
                color: themeData.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => EditDriverPage(driver: _driver))
                      ?.then((value) {
                    if (value == true && mounted) _loadDriverDetails();
                  }),
                  child: Icon(
                    CupertinoIcons.pencil,
                    color: themeData.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _deleteDriver(_driver.driverId),
                  child: Icon(
                    CupertinoIcons.trash,
                    color: themeData.colorScheme.error,
                    size: 24,
                  ),
                ),
              ],
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                  : CupertinoScrollbar(
                      controller: ScrollController(),
                      thumbVisibility: true,
                      thickness: 6.0,
                      thicknessWhileDragging: 10.0,
                      child: SingleChildScrollView(
                        child: Card(
                          elevation: 4,
                          color: themeData.colorScheme.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('司机 ID', driverId, themeData),
                                _buildDetailRow('姓名', name, themeData),
                                _buildDetailRow('身份证号', idCard, themeData),
                                _buildDetailRow('联系电话', contact, themeData),
                                _buildDetailRow('驾驶证号', license, themeData),
                                _buildDetailRow('性别', gender, themeData),
                                _buildDetailRow('出生日期', birthdate, themeData),
                                _buildDetailRow(
                                    '首次领证日期', firstLicenseDate, themeData),
                                _buildDetailRow(
                                    '允许驾驶车辆类型', allowedVehicleType, themeData),
                                _buildDetailRow('发证日期', issueDate, themeData),
                                _buildDetailRow(
                                    '有效期截止日期', expiryDate, themeData),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }
}
