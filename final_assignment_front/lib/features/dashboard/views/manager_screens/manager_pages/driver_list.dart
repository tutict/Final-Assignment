import 'dart:developer' as developer;
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
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

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();
    _loadDrivers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _driverLicenseNumberController.dispose();
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
        _errorMessage = '加载司机信息失败: $e';
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
        _errorMessage = '搜索失败: $e';
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
      final driver = await driverApi.apiDriversIdCardNumberIdCardNumberGet(
          idCardNumber: query);
      _driversFuture = Future.value(driver != null ? [driver] : []);
      final drivers = await _driversFuture;
      developer.log('Searched drivers by ID card: $drivers');
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error searching drivers by ID card: $e',
          stackTrace: StackTrace.current);
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
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
        _errorMessage = '搜索失败: $e';
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _deleteDriver(String driverId) async {
    try {
      await driverApi.initializeWithJwt();
      await driverApi.apiDriversDriverIdDelete(driverId: driverId);
      _showSuccessSnackBar('删除司机成功！');
      _loadDrivers();
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
    );
  }

  void _goToDetailPage(DriverInformation driver) {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DriverDetailPage(driver: driver)))
        .then((value) {
      if (value == true && mounted) _loadDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: Text('司机信息列表',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
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
                  const PopupMenuItem<String>(
                      value: 'name', child: Text('按姓名搜索')),
                  const PopupMenuItem<String>(
                      value: 'idCard', child: Text('按身份证号搜索')),
                  const PopupMenuItem<String>(
                      value: 'license', child: Text('按驾驶证号搜索')),
                ],
                icon:
                    Icon(Icons.filter_list, color: theme.colorScheme.onPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddDriverPage()))
                      .then((value) {
                    if (value == true && mounted) _loadDrivers();
                  });
                },
                tooltip: '添加新司机',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '姓名',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          labelStyle: theme.textTheme.bodyMedium,
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5))),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary)),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          _searchDriversByName(_nameController.text.trim()),
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idCardNumberController,
                        decoration: InputDecoration(
                          labelText: '身份证号',
                          prefixIcon: const Icon(Icons.card_membership),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          labelStyle: theme.textTheme.bodyMedium,
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5))),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary)),
                        ),
                        style: theme.textTheme.bodyMedium,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchDriversByIdCardNumber(
                          _idCardNumberController.text.trim()),
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _driverLicenseNumberController,
                        decoration: InputDecoration(
                          labelText: '驾驶证号',
                          prefixIcon: const Icon(Icons.drive_eta),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          labelStyle: theme.textTheme.bodyMedium,
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5))),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary)),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchDriversByDriverLicenseNumber(
                          _driverLicenseNumberController.text.trim()),
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else if (_errorMessage.isNotEmpty)
                  Expanded(
                      child: Center(
                          child: Text(_errorMessage,
                              style: theme.textTheme.bodyLarge)))
                else
                  Expanded(
                    child: FutureBuilder<List<DriverInformation>>(
                      future: _driversFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('加载司机信息失败: ${snapshot.error}',
                                  style: theme.textTheme.bodyLarge));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                              child: Text('暂无司机信息',
                                  style: theme.textTheme.bodyLarge));
                        } else {
                          final drivers = snapshot.data!;
                          return RefreshIndicator(
                            onRefresh: _loadDrivers,
                            child: ListView.builder(
                              itemCount: drivers.length,
                              itemBuilder: (context, index) {
                                final driver = drivers[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  elevation: 4,
                                  color: theme.colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: ListTile(
                                    title: Text('司机姓名: ${driver.name ?? "未知"}',
                                        style: theme.textTheme.bodyLarge),
                                    subtitle: Text(
                                      '驾驶证号: ${driver.driverLicenseNumber ?? "无"}\n联系电话: ${driver.contactNumber ?? "无"}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7)),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        final did = driver.driverId?.toString();
                                        if (did != null) {
                                          if (value == 'edit') {
                                            _goToDetailPage(driver);
                                          } else if (value == 'delete') {
                                            _deleteDriver(did);
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem<String>(
                                            value: 'edit', child: Text('编辑')),
                                        const PopupMenuItem<String>(
                                            value: 'delete', child: Text('删除')),
                                      ],
                                      icon: Icon(Icons.more_vert,
                                          color: theme.colorScheme.onSurface),
                                    ),
                                    onTap: () => _goToDetailPage(driver),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
        birthdate: _birthdateController.text.trim().isEmpty
            ? null
            : _birthdateController.text.trim(),
        firstLicenseDate: _firstLicenseDateController.text.trim().isEmpty
            ? null
            : _firstLicenseDateController.text.trim(),
        allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: _issueDateController.text.trim().isEmpty
            ? null
            : _issueDateController.text.trim(),
        expiryDate: _expiryDateController.text.trim().isEmpty
            ? null
            : _expiryDateController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
      );
      await driverApi.apiDriversPost(
          driverInformation: driver, idempotencyKey: driver.idempotencyKey!);
      _showSuccessSnackBar('创建司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('创建司机失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('添加新司机',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: _inputDecoration(theme, '姓名', Icons.person),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idCardNumberController,
                      decoration: _inputDecoration(
                          theme, '身份证号码', Icons.card_membership),
                      style: theme.textTheme.bodyMedium,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contactNumberController,
                      decoration: _inputDecoration(theme, '联系电话', Icons.phone),
                      style: theme.textTheme.bodyMedium,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _driverLicenseNumberController,
                      decoration:
                          _inputDecoration(theme, '驾驶证号', Icons.drive_eta),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _genderController,
                      decoration:
                          _inputDecoration(theme, '性别', Icons.person_outline),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _birthdateController,
                      decoration:
                          _inputDecoration(theme, '出生日期', Icons.calendar_today),
                      style: theme.textTheme.bodyMedium,
                      readOnly: true,
                      onTap: () => _selectDate(_birthdateController),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _firstLicenseDateController,
                      decoration: _inputDecoration(
                          theme, '首次领证日期', Icons.calendar_today),
                      style: theme.textTheme.bodyMedium,
                      readOnly: true,
                      onTap: () => _selectDate(_firstLicenseDateController),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _allowedVehicleTypeController,
                      decoration: _inputDecoration(
                          theme, '允许驾驶车辆类型', Icons.directions_car),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _issueDateController,
                      decoration:
                          _inputDecoration(theme, '发证日期', Icons.calendar_today),
                      style: theme.textTheme.bodyMedium,
                      readOnly: true,
                      onTap: () => _selectDate(_issueDateController),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _expiryDateController,
                      decoration: _inputDecoration(
                          theme, '有效期截止日期', Icons.calendar_today),
                      style: theme.textTheme.bodyMedium,
                      readOnly: true,
                      onTap: () => _selectDate(_expiryDateController),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitDriver,
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('提交'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: theme.elevatedButtonTheme.style?.copyWith(
                        backgroundColor: MaterialStateProperty.all(
                            theme.colorScheme.onSurface.withOpacity(0.2)),
                        foregroundColor: MaterialStateProperty.all(
                            theme.colorScheme.onSurface),
                      ),
                      child: const Text('返回上一级'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      ThemeData theme, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      labelStyle: theme.textTheme.bodyMedium,
      enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary)),
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
    _birthdateController.text = widget.driver.birthdate ?? '';
    _firstLicenseDateController.text = widget.driver.firstLicenseDate ?? '';
    _allowedVehicleTypeController.text = widget.driver.allowedVehicleType ?? '';
    _issueDateController.text = widget.driver.issueDate ?? '';
    _expiryDateController.text = widget.driver.expiryDate ?? '';
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
        birthdate: _birthdateController.text.trim().isEmpty
            ? null
            : _birthdateController.text.trim(),
        firstLicenseDate: _firstLicenseDateController.text.trim().isEmpty
            ? null
            : _firstLicenseDateController.text.trim(),
        allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: _issueDateController.text.trim().isEmpty
            ? null
            : _issueDateController.text.trim(),
        expiryDate: _expiryDateController.text.trim().isEmpty
            ? null
            : _expiryDateController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
      );
      await driverApi.apiDriversDriverIdPut(
        driverId: widget.driver.driverId?.toString() ?? '',
        driverInformation: driver,
        idempotencyKey: driver.idempotencyKey!,
      );
      _showSuccessSnackBar('更新司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('更新司机失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('编辑司机信息',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: _inputDecoration(theme, '姓名', Icons.person),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idCardNumberController,
                      decoration: _inputDecoration(
                          theme, '身份证号码', Icons.card_membership),
                      style: theme.textTheme.bodyMedium,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contactNumberController,
                      decoration: _inputDecoration(theme, '联系电话', Icons.phone),
                      style: theme.textTheme.bodyMedium,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _driverLicenseNumberController,
                      decoration:
                          _inputDecoration(theme, '驾驶证号', Icons.drive_eta),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _genderController,
                      decoration:
                          _inputDecoration(theme, '性别', Icons.person_outline),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _birthdateController,
                      decoration:
                          _inputDecoration(theme, '出生日期', Icons.calendar_today),
                      style: theme.textTheme.bodyMedium,
                      readOnly: true,
                      onTap: () => _selectDate(_birthdateController),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _firstLicenseDateController,
                      decoration: _inputDecoration(
                          theme, '首次领证日期', Icons.calendar_today),
                      style: theme.textTheme.bodyMedium,
                      readOnly: true,
                      onTap: () => _selectDate(_firstLicenseDateController),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _allowedVehicleTypeController,
                      decoration: _inputDecoration(
                          theme, '允许驾驶车辆类型', Icons.directions_car),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _issueDateController,
                      decoration:
                          _inputDecoration(theme, '发证日期', Icons.calendar_today),
                      style: theme.textTheme.bodyMedium,
                      readOnly: true,
                      onTap: () => _selectDate(_issueDateController),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _expiryDateController,
                      decoration: _inputDecoration(
                          theme, '有效期截止日期', Icons.calendar_today),
                      style: theme.textTheme.bodyMedium,
                      readOnly: true,
                      onTap: () => _selectDate(_expiryDateController),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitDriver,
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('保存'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: theme.elevatedButtonTheme.style?.copyWith(
                        backgroundColor: MaterialStateProperty.all(
                            theme.colorScheme.onSurface.withOpacity(0.2)),
                        foregroundColor: MaterialStateProperty.all(
                            theme.colorScheme.onSurface),
                      ),
                      child: const Text('返回上一级'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      ThemeData theme, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      labelStyle: theme.textTheme.bodyMedium,
      enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary)),
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
  bool _isLoading = false;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();

  Future<void> _deleteDriver(String driverId) async {
    setState(() => _isLoading = true);
    try {
      await driverApi.initializeWithJwt();
      await driverApi.apiDriversDriverIdDelete(driverId: driverId);
      _showSuccessSnackBar('删除司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.driver.name ?? '未知';
    final idCard = widget.driver.idCardNumber ?? '无';
    final contact = widget.driver.contactNumber ?? '无';
    final license = widget.driver.driverLicenseNumber ?? '无';
    final gender = widget.driver.gender ?? '未知';
    final birthdate = widget.driver.birthdate ?? '无';
    final firstLicenseDate = widget.driver.firstLicenseDate ?? '无';
    final allowedVehicleType = widget.driver.allowedVehicleType ?? '无';
    final issueDate = widget.driver.issueDate ?? '无';
    final expiryDate = widget.driver.expiryDate ?? '无';
    final driverId = widget.driver.driverId?.toString() ?? '0';

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: Text('司机详细信息',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EditDriverPage(driver: widget.driver)))
                      .then((value) {
                    if (value == true && mounted) setState(() {});
                  });
                },
                tooltip: '编辑司机信息',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteDriver(driverId),
                tooltip: '删除司机',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      _buildDetailRow(context, '司机 ID', driverId),
                      _buildDetailRow(context, '姓名', name),
                      _buildDetailRow(context, '身份证号', idCard),
                      _buildDetailRow(context, '联系电话', contact),
                      _buildDetailRow(context, '驾驶证号', license),
                      _buildDetailRow(context, '性别', gender),
                      _buildDetailRow(context, '出生日期', birthdate),
                      _buildDetailRow(context, '首次领证日期', firstLicenseDate),
                      _buildDetailRow(context, '允许驾驶车辆类型', allowedVehicleType),
                      _buildDetailRow(context, '发证日期', issueDate),
                      _buildDetailRow(context, '有效期截止日期', expiryDate),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }
}
