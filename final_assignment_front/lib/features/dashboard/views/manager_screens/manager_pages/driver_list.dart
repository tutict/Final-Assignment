import 'dart:developer' as developer;
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// 司机信息列表页面
class DriverList extends StatefulWidget {
  const DriverList({super.key});

  @override
  State<DriverList> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverList> {
  late DriverInformationControllerApi driverApi;
  late Future<List<DriverInformation>> _driversFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  late ScrollController _scrollController;

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
      _driversFuture = driverApi.apiDriversGet();
      final drivers = await _driversFuture;
      developer.log('Loaded drivers: $drivers');
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error fetching drivers: $e',
          stackTrace: StackTrace.current);
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e);
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _searchDriversByName(String query) async {
    if (query.isEmpty) {
      _loadDrivers();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await driverApi.initializeWithJwt();
      _driversFuture = driverApi.apiDriversNameNameGet(name: query);
      final drivers = await _driversFuture;
      developer.log('Searched drivers by name: $drivers');
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error searching drivers by name: $e',
          stackTrace: StackTrace.current);
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e);
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _searchDriversByIdCardNumber(String query) async {
    if (query.isEmpty) {
      _loadDrivers();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await driverApi.initializeWithJwt();
      _driversFuture =
          driverApi.apiDriversIdCardNumberIdCardNumberGet(idCardNumber: query);
      final drivers = await _driversFuture;
      developer.log('Searched drivers by ID card: $drivers');
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error searching drivers by ID card: $e',
          stackTrace: StackTrace.current);
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e);
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _searchDriversByDriverLicenseNumber(String query) async {
    if (query.isEmpty) {
      _loadDrivers();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await driverApi.initializeWithJwt();
      final driver =
          await driverApi.apiDriversDriverLicenseNumberDriverLicenseNumberGet(
              driverLicenseNumber: query);
      _driversFuture = Future.value(driver != null ? [driver] : []);
      final drivers = await _driversFuture;
      developer.log('Searched drivers by license: $drivers');
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error searching drivers by license: $e',
          stackTrace: StackTrace.current);
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e);
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _deleteDriver(String driverId) async {
    final confirmed = await _showConfirmationDialog('确认删除', '您确定要删除此司机信息吗？');
    if (!confirmed) return;

    try {
      await driverApi.initializeWithJwt();
      await driverApi.apiDriversDriverIdDelete(driverId: driverId);
      _showSnackBar('删除司机成功！');
      _loadDrivers();
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
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
        content: Text(message,
            style: TextStyle(
                color: isError
                    ? themeData.colorScheme.onErrorContainer
                    : themeData.colorScheme.onPrimaryContainer)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _goToDetailPage(DriverInformation driver) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DriverDetailPage(driver: driver)),
    ).then((value) {
      if (value == true && mounted) _loadDrivers();
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '无';
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          appBar: AppBar(
            title: Text('司机信息列表',
                style: themeData.textTheme.headlineSmall?.copyWith(
                    color: themeData.colorScheme.onSurface,
                    fontWeight: FontWeight.bold)),
            backgroundColor: themeData.colorScheme.primaryContainer,
            foregroundColor: themeData.colorScheme.onPrimaryContainer,
            elevation: 2,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'name') {
                    _searchDriversByName(_nameController.text.trim());
                  } else if (value == 'idCard') {
                    _searchDriversByIdCardNumber(
                        _idCardNumberController.text.trim());
                  } else if (value == 'license') {
                    _searchDriversByDriverLicenseNumber(
                        _driverLicenseNumberController.text.trim());
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                      value: 'name',
                      child: Text('按姓名搜索',
                          style: TextStyle(
                              color: themeData.colorScheme.onSurface))),
                  PopupMenuItem<String>(
                      value: 'idCard',
                      child: Text('按身份证号搜索',
                          style: TextStyle(
                              color: themeData.colorScheme.onSurface))),
                  PopupMenuItem<String>(
                      value: 'license',
                      child: Text('按驾驶证号搜索',
                          style: TextStyle(
                              color: themeData.colorScheme.onSurface))),
                ],
                icon: Icon(Icons.filter_list,
                    color: themeData.colorScheme.onPrimaryContainer),
              ),
              IconButton(
                icon: Icon(Icons.add,
                    color: themeData.colorScheme.onPrimaryContainer),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddDriverPage()),
                  ).then((value) {
                    if (value == true && mounted) _loadDrivers();
                  });
                },
                tooltip: '添加新司机',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchField(themeData, '按姓名搜索', Icons.search,
                    _nameController, _searchDriversByName),
                const SizedBox(height: 16),
                _buildSearchField(themeData, '按身份证号搜索', Icons.card_membership,
                    _idCardNumberController, _searchDriversByIdCardNumber,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildSearchField(
                    themeData,
                    '按驾驶证号搜索',
                    Icons.drive_eta,
                    _driverLicenseNumberController,
                    _searchDriversByDriverLicenseNumber),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  themeData.colorScheme.primary)))
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Text(_errorMessage,
                                  style: themeData.textTheme.bodyLarge
                                      ?.copyWith(
                                          color:
                                              themeData.colorScheme.onSurface)))
                          : CupertinoScrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              thickness: 6.0,
                              thicknessWhileDragging: 10.0,
                              child: FutureBuilder<List<DriverInformation>>(
                                future: _driversFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child: Text(
                                            '加载司机信息失败: ${snapshot.error}',
                                            style: themeData.textTheme.bodyLarge
                                                ?.copyWith(
                                                    color: themeData.colorScheme
                                                        .onSurface)));
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                        child: Text('暂无司机信息',
                                            style: themeData.textTheme.bodyLarge
                                                ?.copyWith(
                                                    color: themeData.colorScheme
                                                        .onSurface)));
                                  } else {
                                    final drivers = snapshot.data!;
                                    return RefreshIndicator(
                                      onRefresh: _loadDrivers,
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        itemCount: drivers.length,
                                        itemBuilder: (context, index) {
                                          final driver = drivers[index];
                                          return Card(
                                            elevation: 3,
                                            color: themeData
                                                .colorScheme.surfaceContainer,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12.0)),
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: ListTile(
                                              title: Text(
                                                '司机姓名: ${driver.name ?? "未知"}',
                                                style: themeData
                                                    .textTheme.bodyLarge
                                                    ?.copyWith(
                                                        color: themeData
                                                            .colorScheme
                                                            .onSurface,
                                                        fontWeight:
                                                            FontWeight.w600),
                                              ),
                                              subtitle: Text(
                                                '驾驶证号: ${driver.driverLicenseNumber ?? "无"}\n联系电话: ${driver.contactNumber ?? "无"}',
                                                style: themeData
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: themeData
                                                            .colorScheme
                                                            .onSurfaceVariant),
                                              ),
                                              trailing: PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  final did = driver.driverId
                                                      ?.toString();
                                                  if (did != null) {
                                                    if (value == 'edit') {
                                                      _goToDetailPage(driver);
                                                    } else if (value ==
                                                        'delete') {
                                                      _deleteDriver(did);
                                                    }
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem<String>(
                                                      value: 'edit',
                                                      child: Text('编辑',
                                                          style: TextStyle(
                                                              color: themeData
                                                                  .colorScheme
                                                                  .onSurface))),
                                                  PopupMenuItem<String>(
                                                      value: 'delete',
                                                      child: Text('删除',
                                                          style: TextStyle(
                                                              color: themeData
                                                                  .colorScheme
                                                                  .onSurface))),
                                                ],
                                                icon: Icon(Icons.more_vert,
                                                    color: themeData
                                                        .colorScheme.onSurface),
                                              ),
                                              onTap: () =>
                                                  _goToDetailPage(driver),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDriverPage()),
              ).then((value) {
                if (value == true && mounted) _loadDrivers();
              });
            },
            backgroundColor: themeData.colorScheme.primary,
            foregroundColor: themeData.colorScheme.onPrimary,
            tooltip: '添加新司机',
            child: const Icon(Icons.add),
          ),
        ),
      );
    });
  }

  Widget _buildSearchField(ThemeData themeData, String label, IconData icon,
      TextEditingController controller, Function(String) onSearch,
      {TextInputType? keyboardType}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeData.colorScheme.outline.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12.0)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeData.colorScheme.primary, width: 2.0),
                  borderRadius: BorderRadius.circular(12.0)),
              labelStyle: TextStyle(color: themeData.colorScheme.onSurface),
              filled: true,
              fillColor: themeData.colorScheme.surfaceContainerLowest,
            ),
            style: TextStyle(color: themeData.colorScheme.onSurface),
            keyboardType: keyboardType,
            onSubmitted: (value) => onSearch(value.trim()),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => onSearch(controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.primary,
            foregroundColor: themeData.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
          ),
          child: const Text('搜索'),
        ),
      ],
    );
  }
}

/// 添加司机信息页面
class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final driverApi = DriverInformationControllerApi();
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
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

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
    setState(() => _isLoading = true);
    try {
      await driverApi.initializeWithJwt();

      DateTime? birthdate = _birthdateController.text.trim().isEmpty
          ? null
          : DateTime.parse(_birthdateController.text.trim());
      DateTime? firstLicenseDate =
          _firstLicenseDateController.text.trim().isEmpty
              ? null
              : DateTime.parse(_firstLicenseDateController.text.trim());
      DateTime? issueDate = _issueDateController.text.trim().isEmpty
          ? null
          : DateTime.parse(_issueDateController.text.trim());
      DateTime? expiryDate = _expiryDateController.text.trim().isEmpty
          ? null
          : DateTime.parse(_expiryDateController.text.trim());

      final driver = DriverInformation(
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim().isEmpty
            ? null
            : _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim().isEmpty
            ? null
            : _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim().isEmpty
            ? null
            : _driverLicenseNumberController.text.trim(),
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
        birthdate: birthdate,
        firstLicenseDate: firstLicenseDate,
        allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: issueDate,
        expiryDate: expiryDate,
      );
      final idempotencyKey = generateIdempotencyKey();
      await driverApi.apiDriversPost(
        driverInformation: driver,
        idempotencyKey: idempotencyKey,
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
        content: Text(message,
            style: TextStyle(
                color: isError
                    ? themeData.colorScheme.onErrorContainer
                    : themeData.colorScheme.onPrimaryContainer)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        controller.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
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
        child: Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          appBar: AppBar(
            title: Text('添加新司机',
                style: themeData.textTheme.headlineSmall?.copyWith(
                    color: themeData.colorScheme.onSurface,
                    fontWeight: FontWeight.bold)),
            backgroundColor: themeData.colorScheme.primaryContainer,
            foregroundColor: themeData.colorScheme.onPrimaryContainer,
            elevation: 2,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            themeData.colorScheme.primary)))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTextField(
                            themeData, '姓名', Icons.person, _nameController),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '身份证号码',
                            Icons.card_membership, _idCardNumberController,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '联系电话', Icons.phone,
                            _contactNumberController,
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '驾驶证号', Icons.drive_eta,
                            _driverLicenseNumberController),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '性别', Icons.person_outline,
                            _genderController),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '出生日期', Icons.calendar_today,
                            _birthdateController,
                            readOnly: true,
                            onTap: () => _selectDate(_birthdateController)),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '首次领证日期',
                            Icons.calendar_today, _firstLicenseDateController,
                            readOnly: true,
                            onTap: () =>
                                _selectDate(_firstLicenseDateController)),
                        const SizedBox(height: 12),
                        _buildTextField(
                            themeData,
                            '允许驾驶车辆类型',
                            Icons.directions_car,
                            _allowedVehicleTypeController),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '发证日期', Icons.calendar_today,
                            _issueDateController,
                            readOnly: true,
                            onTap: () => _selectDate(_issueDateController)),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '有效期截止日期',
                            Icons.calendar_today, _expiryDateController,
                            readOnly: true,
                            onTap: () => _selectDate(_expiryDateController)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitDriver,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeData.colorScheme.primary,
                            foregroundColor: themeData.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                          ),
                          child: const Text('提交'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeData.colorScheme.onSurface
                                .withOpacity(0.2),
                            foregroundColor: themeData.colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                          ),
                          child: const Text('返回上一级'),
                        ),
                      ],
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
      VoidCallback? onTap}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: themeData.colorScheme.primary, width: 2.0),
            borderRadius: BorderRadius.circular(8.0)),
        labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainerLowest,
      ),
      style: TextStyle(color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}

/// 编辑司机信息页面
class EditDriverPage extends StatefulWidget {
  final DriverInformation driver;

  const EditDriverPage({super.key, required this.driver});

  @override
  State<EditDriverPage> createState() => _EditDriverPageState();
}

class _EditDriverPageState extends State<EditDriverPage> {
  final driverApi = DriverInformationControllerApi();
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
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController.text = widget.driver.name ?? '';
    _idCardNumberController.text = widget.driver.idCardNumber ?? '';
    _contactNumberController.text = widget.driver.contactNumber ?? '';
    _driverLicenseNumberController.text =
        widget.driver.driverLicenseNumber ?? '';
    _genderController.text = widget.driver.gender ?? '';
    _birthdateController.text = widget.driver.birthdate != null
        ? "${widget.driver.birthdate!.year}-${widget.driver.birthdate!.month.toString().padLeft(2, '0')}-${widget.driver.birthdate!.day.toString().padLeft(2, '0')}"
        : '';
    _firstLicenseDateController.text = widget.driver.firstLicenseDate != null
        ? "${widget.driver.firstLicenseDate!.year}-${widget.driver.firstLicenseDate!.month.toString().padLeft(2, '0')}-${widget.driver.firstLicenseDate!.day.toString().padLeft(2, '0')}"
        : '';
    _allowedVehicleTypeController.text = widget.driver.allowedVehicleType ?? '';
    _issueDateController.text = widget.driver.issueDate != null
        ? "${widget.driver.issueDate!.year}-${widget.driver.issueDate!.month.toString().padLeft(2, '0')}-${widget.driver.issueDate!.day.toString().padLeft(2, '0')}"
        : '';
    _expiryDateController.text = widget.driver.expiryDate != null
        ? "${widget.driver.expiryDate!.year}-${widget.driver.expiryDate!.month.toString().padLeft(2, '0')}-${widget.driver.expiryDate!.day.toString().padLeft(2, '0')}"
        : '';
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
    setState(() => _isLoading = true);
    try {
      await driverApi.initializeWithJwt();

      DateTime? birthdate = _birthdateController.text.trim().isEmpty
          ? null
          : DateTime.parse(_birthdateController.text.trim());
      DateTime? firstLicenseDate =
          _firstLicenseDateController.text.trim().isEmpty
              ? null
              : DateTime.parse(_firstLicenseDateController.text.trim());
      DateTime? issueDate = _issueDateController.text.trim().isEmpty
          ? null
          : DateTime.parse(_issueDateController.text.trim());
      DateTime? expiryDate = _expiryDateController.text.trim().isEmpty
          ? null
          : DateTime.parse(_expiryDateController.text.trim());

      final driver = DriverInformation(
        driverId: widget.driver.driverId,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim().isEmpty
            ? null
            : _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim().isEmpty
            ? null
            : _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim().isEmpty
            ? null
            : _driverLicenseNumberController.text.trim(),
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
        birthdate: birthdate,
        firstLicenseDate: firstLicenseDate,
        allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: issueDate,
        expiryDate: expiryDate,
      );
      final idempotencyKey = generateIdempotencyKey();
      await driverApi.apiDriversDriverIdPut(
        driverId: widget.driver.driverId?.toString() ?? '',
        driverInformation: driver,
        idempotencyKey: idempotencyKey,
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
        content: Text(message,
            style: TextStyle(
                color: isError
                    ? themeData.colorScheme.onErrorContainer
                    : themeData.colorScheme.onPrimaryContainer)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        controller.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
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
        child: Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          appBar: AppBar(
            title: Text('编辑司机信息',
                style: themeData.textTheme.headlineSmall?.copyWith(
                    color: themeData.colorScheme.onSurface,
                    fontWeight: FontWeight.bold)),
            backgroundColor: themeData.colorScheme.primaryContainer,
            foregroundColor: themeData.colorScheme.onPrimaryContainer,
            elevation: 2,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            themeData.colorScheme.primary)))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTextField(
                            themeData, '姓名', Icons.person, _nameController),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '身份证号码',
                            Icons.card_membership, _idCardNumberController,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '联系电话', Icons.phone,
                            _contactNumberController,
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '驾驶证号', Icons.drive_eta,
                            _driverLicenseNumberController),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '性别', Icons.person_outline,
                            _genderController),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '出生日期', Icons.calendar_today,
                            _birthdateController,
                            readOnly: true,
                            onTap: () => _selectDate(_birthdateController)),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '首次领证日期',
                            Icons.calendar_today, _firstLicenseDateController,
                            readOnly: true,
                            onTap: () =>
                                _selectDate(_firstLicenseDateController)),
                        const SizedBox(height: 12),
                        _buildTextField(
                            themeData,
                            '允许驾驶车辆类型',
                            Icons.directions_car,
                            _allowedVehicleTypeController),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '发证日期', Icons.calendar_today,
                            _issueDateController,
                            readOnly: true,
                            onTap: () => _selectDate(_issueDateController)),
                        const SizedBox(height: 12),
                        _buildTextField(themeData, '有效期截止日期',
                            Icons.calendar_today, _expiryDateController,
                            readOnly: true,
                            onTap: () => _selectDate(_expiryDateController)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitDriver,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeData.colorScheme.primary,
                            foregroundColor: themeData.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                          ),
                          child: const Text('保存'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeData.colorScheme.onSurface
                                .withOpacity(0.2),
                            foregroundColor: themeData.colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                          ),
                          child: const Text('返回上一级'),
                        ),
                      ],
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
      VoidCallback? onTap}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: themeData.colorScheme.outline.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: themeData.colorScheme.primary, width: 2.0),
            borderRadius: BorderRadius.circular(8.0)),
        labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainerLowest,
      ),
      style: TextStyle(color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}

/// 司机详细信息页面
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
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  @override
  void initState() {
    super.initState();
    _driver = widget.driver;
  }

  Future<void> _deleteDriver(String driverId) async {
    final confirmed = await _showConfirmationDialog('确认删除', '您确定要删除此司机信息吗？');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await driverApi.initializeWithJwt();
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
        content: Text(message,
            style: TextStyle(
                color: isError
                    ? themeData.colorScheme.onErrorContainer
                    : themeData.colorScheme.onPrimaryContainer)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '无';
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      final name = _driver.name ?? '未知';
      final idCard = _driver.idCardNumber ?? '无';
      final contact = _driver.contactNumber ?? '无';
      final license = _driver.driverLicenseNumber ?? '无';
      final gender = _driver.gender ?? '未知';
      final birthdate = _formatDateTime(_driver.birthdate);
      final firstLicenseDate = _formatDateTime(_driver.firstLicenseDate);
      final allowedVehicleType = _driver.allowedVehicleType ?? '无';
      final issueDate = _formatDateTime(_driver.issueDate);
      final expiryDate = _formatDateTime(_driver.expiryDate);
      final driverId = _driver.driverId?.toString() ?? '0';

      return Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: themeData.colorScheme.surface,
          appBar: AppBar(
            title: Text('司机详细信息',
                style: themeData.textTheme.headlineSmall?.copyWith(
                    color: themeData.colorScheme.onSurface,
                    fontWeight: FontWeight.bold)),
            backgroundColor: themeData.colorScheme.primaryContainer,
            foregroundColor: themeData.colorScheme.onPrimaryContainer,
            elevation: 2,
            actions: [
              IconButton(
                icon: Icon(Icons.edit,
                    color: themeData.colorScheme.onPrimaryContainer),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditDriverPage(driver: _driver)),
                  ).then((value) {
                    if (value == true && mounted) {
                      setState(() {
                        _driver =
                            widget.driver; // Refresh driver data if needed
                      });
                      _loadDriverDetails();
                    }
                  });
                },
                tooltip: '编辑司机信息',
              ),
              IconButton(
                icon: Icon(Icons.delete,
                    color: themeData.colorScheme.onPrimaryContainer),
                onPressed: () => _deleteDriver(driverId),
                tooltip: '删除司机',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            themeData.colorScheme.primary)))
                : CupertinoScrollbar(
                    thumbVisibility: true,
                    thickness: 6.0,
                    thicknessWhileDragging: 10.0,
                    child: ListView(
                      children: [
                        _buildDetailRow(themeData, '司机 ID', driverId),
                        _buildDetailRow(themeData, '姓名', name),
                        _buildDetailRow(themeData, '身份证号', idCard),
                        _buildDetailRow(themeData, '联系电话', contact),
                        _buildDetailRow(themeData, '驾驶证号', license),
                        _buildDetailRow(themeData, '性别', gender),
                        _buildDetailRow(themeData, '出生日期', birthdate),
                        _buildDetailRow(themeData, '首次领证日期', firstLicenseDate),
                        _buildDetailRow(
                            themeData, '允许驾驶车辆类型', allowedVehicleType),
                        _buildDetailRow(themeData, '发证日期', issueDate),
                        _buildDetailRow(themeData, '有效期截止日期', expiryDate),
                      ],
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Future<void> _loadDriverDetails() async {
    try {
      await driverApi.initializeWithJwt();
      final updatedDriver = await driverApi.apiDriversDriverIdGet(
          driverId: _driver.driverId.toString());
      if (updatedDriver != null && mounted) {
        setState(() {
          _driver = updatedDriver;
        });
      }
    } catch (e) {
      _showSnackBar(_formatErrorMessage(e), isError: true);
    }
  }

  Widget _buildDetailRow(ThemeData themeData, String label, String value) {
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
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
