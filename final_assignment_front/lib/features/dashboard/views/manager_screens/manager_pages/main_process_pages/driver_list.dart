import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';


// Utility function to format DateTime
String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '';
  return DateFormat('yyyy-MM-dd').format(dateTime);
}

// Utility function to generate idempotency key (not used in API calls but kept for model compatibility)
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class DriverList extends StatefulWidget {
  const DriverList({super.key});

  @override
  State<DriverList> createState() => _DriverListState();
}

class _DriverListState extends State<DriverList> {
  final driverApi = DriverInformationControllerApi();
  final List<DriverInformation> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;

  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      debugPrint('Fetching drivers');
      await driverApi.initializeWithJwt();
      final newDrivers = await driverApi.apiDriversGet().timeout(const Duration(seconds: 10));
      debugPrint('Received ${newDrivers.length} drivers');
      setState(() {
        _drivers.addAll(newDrivers);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '获取司机列表失败: ${_formatErrorMessage(e)}';
      });
      _showSnackBar(_errorMessage!, isError: true);
    }
  }

  Future<void> _deleteDriver(int driverId) async {
    try {
      await driverApi.apiDriversDriverIdDelete(driverId: driverId).timeout(const Duration(seconds: 5));
      setState(() {
        _drivers.removeWhere((driver) => driver.driverId == driverId);
      });
      _showSnackBar('删除司机成功！');
    } catch (e) {
      debugPrint('Error deleting driver: $e');
      _showSnackBar('删除司机失败: ${_formatErrorMessage(e)}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isError ? themeData.colorScheme.onError : themeData.colorScheme.onPrimary),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  Future<void> _refreshDrivers() async {
    setState(() {
      _drivers.clear();
      _isLoading = true;
      _errorMessage = null;
    });
    await _fetchDrivers();
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return error.message.isNotEmpty ? error.message : '无效的请求数据';
        case 401:
          return '未授权: 请检查登录状态';
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '资源未找到';
        case 500:
          return '服务器错误';
        default:
          return error.message.isNotEmpty ? error.message : '未知错误';
      }
    }
    return error.toString();
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
              '司机列表',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            trailing: GestureDetector(
              onTap: () => Get.to(() => const AddDriverPage())?.then((result) {
                if (result == true) {
                  _refreshDrivers();
                }
              }),
              child: Icon(
                CupertinoIcons.add,
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
            child: RefreshIndicator(
              onRefresh: _refreshDrivers,
              color: themeData.colorScheme.primary,
              child: _isLoading && _drivers.isEmpty && _errorMessage == null
                  ? Center(
                child: CupertinoActivityIndicator(
                  color: themeData.colorScheme.primary,
                  radius: 16.0,
                ),
              )
                  : _drivers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage ?? '暂无司机信息',
                      style: themeData.textTheme.bodyLarge?.copyWith(
                        color: themeData.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton(
                          onPressed: _refreshDrivers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeData.colorScheme.primary,
                            foregroundColor: themeData.colorScheme.onPrimary,
                          ),
                          child: const Text('重试'),
                        ),
                      ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _drivers.length,
                itemBuilder: (context, index) {
                  final driver = _drivers[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    color: themeData.colorScheme.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        driver.name ?? '未知姓名',
                        style: themeData.textTheme.titleMedium?.copyWith(
                          color: themeData.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4.0),
                          Text(
                            '身份证: ${driver.idCardNumber ?? '未提供'}',
                            style: themeData.textTheme.bodyMedium?.copyWith(
                              color: themeData.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '电话: ${driver.contactNumber ?? '未提供'}',
                            style: themeData.textTheme.bodyMedium?.copyWith(
                              color: themeData.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              CupertinoIcons.pencil,
                              color: themeData.colorScheme.primary,
                            ),
                            onPressed: () {
                              Get.to(() => EditDriverPage(driver: driver))?.then((result) {
                                if (result == true) {
                                  _refreshDrivers();
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              CupertinoIcons.delete,
                              color: themeData.colorScheme.error,
                            ),
                            onPressed: () async {
                              final confirm = await showCupertinoDialog<bool>(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('确认删除'),
                                  content: Text('确定要删除司机 ${driver.name} 吗？'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('取消'),
                                      onPressed: () => Navigator.pop(context, false),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      child: const Text('删除'),
                                      onPressed: () => Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && driver.driverId != null) {
                                await _deleteDriver(driver.driverId!);
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Get.to(() => DriverDetailPage(driver: driver));
                      },
                    ),
                  );
                },
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
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _firstLicenseDateController = TextEditingController();
  final TextEditingController _allowedVehicleTypeController = TextEditingController();
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
      await driverApi.initializeWithJwt().timeout(const Duration(seconds: 5));
      debugPrint('JWT initialization successful');
    } catch (e) {
      debugPrint('Initialization error: $e');
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
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      _showSnackBar('请填写所有必填字段', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String normalizedContactNumber = _contactNumberController.text.trim();
      if (!normalizedContactNumber.startsWith('+')) {
        normalizedContactNumber = '+86$normalizedContactNumber';
      }
      final driver = DriverInformation(
        name: _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: normalizedContactNumber,
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        gender: _genderController.text.trim().isEmpty ? null : _genderController.text.trim(),
        birthdate: _birthdateController.text.trim().isEmpty ? null : DateTime.parse('${_birthdateController.text.trim()}T00:00:00'),
        firstLicenseDate: _firstLicenseDateController.text.trim().isEmpty ? null : DateTime.parse('${_firstLicenseDateController.text.trim()}T00:00:00'),
        allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty ? null : _allowedVehicleTypeController.text.trim(),
        issueDate: _issueDateController.text.trim().isEmpty ? null : DateTime.parse('${_issueDateController.text.trim()}T00:00:00'),
        expiryDate: _expiryDateController.text.trim().isEmpty ? null : DateTime.parse('${_expiryDateController.text.trim()}T00:00:00'),
      );
      debugPrint('Creating driver: ${driver.toJson()}');
      await driverApi.apiDriversPost(driverInformation: driver, idempotencyKey: generateIdempotencyKey()).timeout(const Duration(seconds: 5));
      _showSnackBar('添加司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Driver creation error: $e');
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
          style: TextStyle(color: isError ? themeData.colorScheme.onError : themeData.colorScheme.onPrimary),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
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
            style: TextButton.styleFrom(foregroundColor: controller.currentBodyTheme.value.colorScheme.primary),
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
          return '请求错误: ${error.message.isNotEmpty ? error.message : "无效的请求数据"}';
        case 401:
          return '未授权: 请检查登录状态';
        case 403:
          return '无权限: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
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
              '添加司机',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(themeData, '姓名 *', Icons.person, _nameController, required: true),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '身份证号码 *', Icons.card_membership, _idCardNumberController,
                              keyboardType: TextInputType.number, required: true),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '联系电话 *', Icons.phone, _contactNumberController,
                              keyboardType: TextInputType.phone,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '联系电话不能为空';
                                }
                                if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                                  return '请输入有效的电话号码（例如 +8613812345678 或 13812345678）';
                                }
                                return null;
                              }),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '驾驶证号 *', Icons.drive_eta, _driverLicenseNumberController, required: true),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '性别', Icons.person_outline, _genderController),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '出生日期', Icons.calendar_today, _birthdateController,
                              readOnly: true, onTap: () => _selectDate(_birthdateController)),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '首次领证日期', Icons.calendar_today, _firstLicenseDateController,
                              readOnly: true, onTap: () => _selectDate(_firstLicenseDateController)),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '允许驾驶车辆类型', Icons.directions_car, _allowedVehicleTypeController),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '发证日期', Icons.calendar_today, _issueDateController,
                              readOnly: true, onTap: () => _selectDate(_issueDateController)),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '有效期截止日期', Icons.calendar_today, _expiryDateController,
                              readOnly: true, onTap: () => _selectDate(_expiryDateController)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _submitDriver,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.colorScheme.primary,
                              foregroundColor: themeData.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
                              elevation: 2,
                            ),
                            child: Text(
                              '保存',
                              style: themeData.textTheme.labelLarge?.copyWith(
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

  Widget _buildTextField(ThemeData themeData, String label, IconData icon, TextEditingController controller,
      {TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap, bool required = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        suffixIcon: readOnly ? Icon(Icons.calendar_today, color: themeData.colorScheme.primary) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainer,
        labelStyle: themeData.textTheme.bodyMedium?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      ),
      style: themeData.textTheme.bodyMedium?.copyWith(color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator ??
          (required
              ? (value) => value!.isEmpty ? '$label不能为空' : null
              : null),
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
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _firstLicenseDateController = TextEditingController();
  final TextEditingController _allowedVehicleTypeController = TextEditingController();
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
      await driverApi.initializeWithJwt().timeout(const Duration(seconds: 5));
      debugPrint('JWT initialization successful');
    } catch (e) {
      debugPrint('Initialization error: $e');
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeFields() {
    _nameController.text = widget.driver.name ?? '';
    _idCardNumberController.text = widget.driver.idCardNumber ?? '';
    _contactNumberController.text = widget.driver.contactNumber ?? '';
    _driverLicenseNumberController.text = widget.driver.driverLicenseNumber ?? '';
    _genderController.text = widget.driver.gender ?? '';
    _birthdateController.text = formatDateTime(widget.driver.birthdate);
    _firstLicenseDateController.text = formatDateTime(widget.driver.firstLicenseDate);
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
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      _showSnackBar('请填写所有必填字段', isError: true);
      return;
    }
    if (widget.driver.driverId == null) {
      debugPrint('Invalid driver ID');
      _showSnackBar('司机ID无效，无法更新', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final driverId = widget.driver.driverId!;
      debugPrint('Updating driver ID: $driverId');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJoZ2xAYWRtaW4uY29tIiwicm9sZXMiOiJBRE1JTiIsImlhdCI6MTc0Nzg3MTYzNiwiZXhwIjoxNzQ3OTU4MDM2fQ.P90bMsE82pHNNyLJ4yUMRGhG2xmjbTFvs-Y3ViyuCf4',
      };

      // Update name
      if (_nameController.text.trim() != widget.driver.name) {
        debugPrint('Updating name: ${_nameController.text.trim()}');
        final body = jsonEncode({'name': _nameController.text.trim()});
        debugPrint('Name request body: $body');
        final response = await driverApi.apiClient.invokeAPI(
          '/api/drivers/$driverId/name',
          'PUT',
          [QueryParam('idempotencyKey', generateIdempotencyKey())],
          body,
          headers,
          {},
          'application/json',
          ['bearerAuth'],
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode >= 400) {
          debugPrint('Name update failed: ${response.statusCode} - ${response.body}');
          throw ApiException(response.statusCode, response.body.isNotEmpty ? response.body : 'Failed to update name');
        }
      }

      // Update ID card number
      if (_idCardNumberController.text.trim() != widget.driver.idCardNumber) {
        debugPrint('Updating idCardNumber: ${_idCardNumberController.text.trim()}');
        final body = jsonEncode({'idCardNumber': _idCardNumberController.text.trim()});
        debugPrint('ID card request body: $body');
        final response = await driverApi.apiClient.invokeAPI(
          '/api/drivers/$driverId/idCardNumber',
          'PUT',
          [QueryParam('idempotencyKey', generateIdempotencyKey())],
          body,
          headers,
          {},
          'application/json',
          ['bearerAuth'],
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode >= 400) {
          debugPrint('ID card update failed: ${response.statusCode} - ${response.body}');
          throw ApiException(response.statusCode, response.body.isNotEmpty ? response.body : 'Failed to update ID card number');
        }
      }

      // Update contact number
      if (_contactNumberController.text.trim() != widget.driver.contactNumber) {
        String normalizedContactNumber = _contactNumberController.text.trim();
        if (!normalizedContactNumber.startsWith('+')) {
          normalizedContactNumber = '+86$normalizedContactNumber';
        }
        debugPrint('Updating contactNumber: $normalizedContactNumber');
        final body = jsonEncode({'contactNumber': normalizedContactNumber});
        debugPrint('Contact number request body: $body');
        final response = await driverApi.apiClient.invokeAPI(
          '/api/drivers/$driverId/contactNumber',
          'PUT',
          [QueryParam('idempotencyKey', generateIdempotencyKey())],
          body,
          headers,
          {},
          'application/json',
          ['bearerAuth'],
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode >= 400) {
          debugPrint('Contact number update failed: ${response.statusCode} - ${response.body}');
          throw ApiException(response.statusCode, response.body.isNotEmpty ? response.body : 'Failed to update contact number');
        }
      }

      // Update other fields using the full update endpoint
      final otherFieldsChanged = _driverLicenseNumberController.text.trim() != widget.driver.driverLicenseNumber ||
          _genderController.text.trim() != (widget.driver.gender ?? '') ||
          _birthdateController.text.trim() != formatDateTime(widget.driver.birthdate) ||
          _firstLicenseDateController.text.trim() != formatDateTime(widget.driver.firstLicenseDate) ||
          _allowedVehicleTypeController.text.trim() != (widget.driver.allowedVehicleType ?? '') ||
          _issueDateController.text.trim() != formatDateTime(widget.driver.issueDate) ||
          _expiryDateController.text.trim() != formatDateTime(widget.driver.expiryDate);

      if (otherFieldsChanged) {
        final driver = DriverInformation(
          driverId: driverId,
          name: _nameController.text.trim(),
          idCardNumber: _idCardNumberController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
          driverLicenseNumber: _driverLicenseNumberController.text.trim(),
          gender: _genderController.text.trim().isEmpty ? null : _genderController.text.trim(),
          birthdate: _birthdateController.text.trim().isEmpty ? null : DateTime.parse('${_birthdateController.text.trim()}T00:00:00'),
          firstLicenseDate: _firstLicenseDateController.text.trim().isEmpty ? null : DateTime.parse('${_firstLicenseDateController.text.trim()}T00:00:00'),
          allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty ? null : _allowedVehicleTypeController.text.trim(),
          issueDate: _issueDateController.text.trim().isEmpty ? null : DateTime.parse('${_issueDateController.text.trim()}T00:00:00'),
          expiryDate: _expiryDateController.text.trim().isEmpty ? null : DateTime.parse('${_expiryDateController.text.trim()}T00:00:00'),
        );
        debugPrint('Updating full driver info: ${driver.toJson()}');
        await driverApi.apiDriversDriverIdPut(
          driverId: driverId,
          driverInformation: driver, idempotencyKey: generateIdempotencyKey(),
        ).timeout(const Duration(seconds: 5));
      }

      debugPrint('Driver update successful');
      _showSnackBar('更新司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Driver update error: $e');
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
          style: TextStyle(color: isError ? themeData.colorScheme.onError : themeData.colorScheme.onPrimary),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
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
            style: TextButton.styleFrom(foregroundColor: controller.currentBodyTheme.value.colorScheme.primary),
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
          return '请求错误: ${error.message.isNotEmpty ? error.message : "无效的请求数据"}';
        case 401:
          return '未授权: 请检查登录状态';
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(themeData, '姓名 *', Icons.person, _nameController, required: true),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '身份证号码 *', Icons.card_membership, _idCardNumberController,
                              keyboardType: TextInputType.number, required: true),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '联系电话 *', Icons.phone, _contactNumberController,
                              keyboardType: TextInputType.phone,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '联系电话不能为空';
                                }
                                if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                                  return '请输入有效的电话号码（例如 +8613812345678 或 13812345678）';
                                }
                                return null;
                              }),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '驾驶证号 *', Icons.drive_eta, _driverLicenseNumberController, required: true),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '性别', Icons.person_outline, _genderController),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '出生日期', Icons.calendar_today, _birthdateController,
                              readOnly: true, onTap: () => _selectDate(_birthdateController)),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '首次领证日期', Icons.calendar_today, _firstLicenseDateController,
                              readOnly: true, onTap: () => _selectDate(_firstLicenseDateController)),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '允许驾驶车辆类型', Icons.directions_car, _allowedVehicleTypeController),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '发证日期', Icons.calendar_today, _issueDateController,
                              readOnly: true, onTap: () => _selectDate(_issueDateController)),
                          const SizedBox(height: 16),
                          _buildTextField(themeData, '有效期截止日期', Icons.calendar_today, _expiryDateController,
                              readOnly: true, onTap: () => _selectDate(_expiryDateController)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _submitDriver,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.colorScheme.primary,
                              foregroundColor: themeData.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
                              elevation: 2,
                            ),
                            child: Text(
                              '保存',
                              style: themeData.textTheme.labelLarge?.copyWith(
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

  Widget _buildTextField(ThemeData themeData, String label, IconData icon, TextEditingController controller,
      {TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap, bool required = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        suffixIcon: readOnly ? Icon(Icons.calendar_today, color: themeData.colorScheme.primary) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainer,
        labelStyle: themeData.textTheme.bodyMedium?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      ),
      style: themeData.textTheme.bodyMedium?.copyWith(color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator ??
          (required
              ? (value) => value!.isEmpty ? '$label不能为空' : null
              : null),
    );
  }
}

class DriverDetailPage extends StatelessWidget {
  final DriverInformation driver;

  const DriverDetailPage({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              '司机详情',
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
            trailing: GestureDetector(
              onTap: () => Get.to(() => EditDriverPage(driver: driver))?.then((result) {
                if (result == true) {
                  Get.back(result: true);
                }
              }),
              child: Icon(
                CupertinoIcons.pencil,
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  color: themeData.colorScheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(themeData, '姓名', driver.name ?? '未知', Icons.person),
                        const SizedBox(height: 16),
                        _buildDetailRow(themeData, '身份证号码', driver.idCardNumber ?? '未提供', Icons.card_membership),
                        const SizedBox(height: 16),
                        _buildDetailRow(themeData, '联系电话', driver.contactNumber ?? '未提供', Icons.phone),
                        const SizedBox(height: 16),
                        _buildDetailRow(themeData, '驾驶证号', driver.driverLicenseNumber ?? '未提供', Icons.drive_eta),
                        const SizedBox(height: 16),
                        _buildDetailRow(themeData, '性别', driver.gender ?? '未提供', Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildDetailRow(themeData, '出生日期', formatDateTime(driver.birthdate), Icons.calendar_today),
                        const SizedBox(height: 16),
                        _buildDetailRow(themeData, '首次领证日期', formatDateTime(driver.firstLicenseDate), Icons.calendar_today),
                        const SizedBox(height: 16),
                        _buildDetailRow(themeData, '允许驾驶车辆类型', driver.allowedVehicleType ?? '未提供', Icons.directions_car),
                        const SizedBox(height: 16),
                        _buildDetailRow(themeData, '发证日期', formatDateTime(driver.issueDate), Icons.calendar_today),
                        const SizedBox(height: 16),
                        _buildDetailRow(themeData, '有效期截止日期', formatDateTime(driver.expiryDate), Icons.calendar_today),
                      ],
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

  Widget _buildDetailRow(ThemeData themeData, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: themeData.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: themeData.textTheme.bodyLarge?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}