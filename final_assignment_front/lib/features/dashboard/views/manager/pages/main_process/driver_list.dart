// ignore_for_file: use_build_context_synchronously
import 'dart:developer' as developer;
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';

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
  final driverApi = DriverInformationControllerApi();
  final DashboardController controller = Get.find<DashboardController>();
  List<DriverInformation> _drivers = [];
  List<DriverInformation> _filteredDrivers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = '';
    _initialize();
    _loadDrivers();
    _searchController.addListener(_filterDrivers);
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await driverApi.initializeWithJwt();
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, AppUtils.formatErrorMessage(e),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);
    try {
      developer.log('Loading driver list', name: 'DriverList');
      final drivers = await driverApi.apiDriversGet();
      if (mounted) {
        setState(() {
          _drivers = drivers;
          _filterDrivers();
          developer.log('Loaded ${_drivers.length} drivers',
              name: 'DriverList');
        });
      }
    } catch (e) {
      developer.log('Error loading drivers: $e', name: 'DriverList');
      if (mounted) {
        AppUtils.showSnackBar(context, AppUtils.formatErrorMessage(e),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterDrivers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredDrivers = _drivers.where((driver) {
        final name = driver.name?.toLowerCase() ?? '';
        final id = driver.driverId?.toString() ?? '';
        final contact = driver.contactNumber?.toLowerCase() ?? '';
        final idCard = driver.idCardNumber?.toLowerCase() ?? '';
        return name.contains(query) ||
            id.contains(query) ||
            contact.contains(query) ||
            idCard.contains(query);
      }).toList();
    });
    developer.log(
        'Filtered ${_filteredDrivers.length} drivers for query: $query',
        name: 'DriverList');
  }

  String _mapGenderToDisplay(String? gender) {
    if (gender == 'Male') return '男';
    if (gender == 'Female') return '女';
    return gender ?? '未知';
  }

  void _navigateToAddDriver() {
    Get.to(() => const AddDriverPage())?.then((value) {
      if (value == true && mounted) {
        developer.log('AddDriverPage returned true, refreshing list',
            name: 'DriverList');
        _loadDrivers();
      }
    });
  }

  void _navigateToDriverDetail(DriverInformation driver) {
    Get.to(() => DriverDetailPage(driver: driver))?.then((value) {
      if (value == true && mounted) {
        developer.log('DriverDetailPage returned true, refreshing list',
            name: 'DriverList');
        _loadDrivers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDrivers);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return DashboardPageTemplate(
        theme: themeData,
        title: '司机列表',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          DashboardPageBarAction(
            icon: Icons.add,
            onPressed: _navigateToAddDriver,
            tooltip: '添加司机',
          ),
        ],
        onThemeToggle: controller.toggleBodyTheme,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: '搜索司机（姓名、ID、电话、身份证号）',
                    prefixIcon: Icon(Icons.search,
                        color: themeData.colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: themeData.colorScheme.surfaceContainer,
                  ),
                  onChanged: (value) => _filterDrivers(),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDrivers,
                      color: themeData.colorScheme.primary,
                      child: _filteredDrivers.isEmpty
                          ? Center(
                              child: Text(
                                _searchController.text.isEmpty
                                    ? '暂无司机信息'
                                    : '无匹配的司机记录',
                                style:
                                    themeData.textTheme.bodyLarge?.copyWith(
                                  color: themeData
                                      .colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredDrivers.length,
                              itemBuilder: (context, index) {
                                final driver = _filteredDrivers[index];
                                final name = driver.name ?? '未知';
                                final id =
                                    driver.driverId?.toString() ?? '无';
                                final gender =
                                    _mapGenderToDisplay(driver.gender);
                                final contact = driver.contactNumber ?? '无';

                                return Card(
                                  elevation: 2,
                                  color: themeData
                                      .colorScheme.surfaceContainerLowest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12.0),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.all(16.0),
                                    leading: CircleAvatar(
                                      backgroundColor: themeData
                                          .colorScheme.primaryContainer,
                                      child: Text(
                                        name.isNotEmpty ? name[0] : '?',
                                        style: TextStyle(
                                          color: themeData.colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            themeData.colorScheme.onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: $id | 性别: $gender | 电话: $contact',
                                      style: themeData.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: themeData
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Icon(
                                      CupertinoIcons.right_chevron,
                                      color: themeData
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                    onTap: () =>
                                        _navigateToDriverDetail(driver),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
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
      if (mounted) {
        AppUtils.showSnackBar(context, AppUtils.formatErrorMessage(e),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _mapGenderToBackend(String gender) {
    if (gender.isEmpty) return null;
    if (gender == '男') return 'Male';
    if (gender == '女') return 'Female';
    return null;
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
      AppUtils.showSnackBar(context, '请修正表单中的错误', isError: true);
      return;
    }

    if (_isLoading) return; // Prevent double submission

    setState(() => _isLoading = true);
    try {
      final driver = DriverInformation(
        name: _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        gender: _mapGenderToBackend(_genderController.text.trim()),
        birthdate: _birthdateController.text.trim().isEmpty
            ? null
            : DateTime.tryParse('${_birthdateController.text.trim()}T00:00:00'),
        firstLicenseDate: _firstLicenseDateController.text.trim().isEmpty
            ? null
            : DateTime.tryParse(
                '${_firstLicenseDateController.text.trim()}T00:00:00'),
        allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: _issueDateController.text.trim().isEmpty
            ? null
            : DateTime.tryParse('${_issueDateController.text.trim()}T00:00:00'),
        expiryDate: _expiryDateController.text.trim().isEmpty
            ? null
            : DateTime.tryParse(
                '${_expiryDateController.text.trim()}T00:00:00'),
      );

      developer.log('Submitting new driver: ${driver.toJson()}',
          name: 'AddDriverPage');

      const maxRetries = 3;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final idempotencyKey = generateIdempotencyKey();
          developer.log('Attempt $attempt with idempotencyKey: $idempotencyKey',
              name: 'AddDriverPage');
          await driverApi.apiDriversPost(
            driverInformation: driver,
            idempotencyKey: idempotencyKey,
          );
          if (mounted) {
            AppUtils.showSnackBar(context, '添加司机成功！');
            // 延迟 1 秒后返回，确保 Elasticsearch 索引完成
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pop(context, true);
          }
          return;
        } catch (e) {
          developer.log('Attempt $attempt failed: $e', name: 'AddDriverPage');
          if (attempt == maxRetries) {
            rethrow;
          }
          await Future.delayed(
              const Duration(milliseconds: 500)); // Delay before retry
        }
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          '添加失败：${AppUtils.formatErrorMessage(e)}. 请确保性别为“男”或“女”，或联系管理员。',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(TextEditingController textController) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => Theme(
        data: controller.currentBodyTheme.value,
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        textController.text = formatDateTime(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return DashboardPageTemplate(
        theme: themeData,
        title: '添加司机',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        onThemeToggle: controller.toggleBodyTheme,
        body: Padding(
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
                            AppUtils.buildTextField(
                              themeData,
                              '姓名 *',
                              Icons.person,
                              _nameController,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '姓名不能为空';
                                }
                                if (value.length < 2 || value.length > 50) {
                                  return '姓名长度必须在2到50个字符之间';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '身份证号码 *',
                              Icons.card_membership,
                              _idCardNumberController,
                              keyboardType: TextInputType.number,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '身份证号码不能为空';
                                }
                                if (!RegExp(r'^(\d{17}[\dX]|\d{15})$')
                                    .hasMatch(value)) {
                                  return '请输入有效的身份证号码（15或18位）';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '联系电话 *',
                              Icons.phone,
                              _contactNumberController,
                              keyboardType: TextInputType.phone,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '联系电话不能为空';
                                }
                                if (!RegExp(r'^1[3-9]\d{9}$')
                                    .hasMatch(value)) {
                                  return '请输入有效的11位手机号码';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '驾驶证号 *',
                              Icons.drive_eta,
                              _driverLicenseNumberController,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '驾驶证号不能为空';
                                }
                                if (!RegExp(r'^\d{12}$').hasMatch(value)) {
                                  return '请输入有效的12位驾驶证号';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '性别',
                              Icons.person_outline,
                              _genderController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                if (!['男', '女'].contains(value)) {
                                  return '性别必须为“男”或“女”';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '出生日期',
                              Icons.calendar_today,
                              _birthdateController,
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(_birthdateController),
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '首次领证日期',
                              Icons.calendar_today,
                              _firstLicenseDateController,
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(_firstLicenseDateController),
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '允许驾驶车辆类型',
                              Icons.directions_car,
                              _allowedVehicleTypeController,
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '发证日期',
                              Icons.calendar_today,
                              _issueDateController,
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(_issueDateController),
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '有效期截止日期',
                              Icons.calendar_today,
                              _expiryDateController,
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(_expiryDateController),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submitDriver,
                              // Disable button when loading
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    themeData.colorScheme.primary,
                                foregroundColor:
                                    themeData.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12.0)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16.0, horizontal: 24.0),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? CupertinoActivityIndicator(
                                      color:
                                          themeData.colorScheme.onPrimary,
                                      radius: 12.0,
                                    )
                                  : Text(
                                      '添加',
                                      style: themeData.textTheme.labelLarge
                                          ?.copyWith(
                                        color:
                                            themeData.colorScheme.onPrimary,
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
      );
    });
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
      if (mounted) {
        AppUtils.showSnackBar(context, AppUtils.formatErrorMessage(e),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeFields() {
    _nameController.text = widget.driver.name ?? '';
    _idCardNumberController.text = widget.driver.idCardNumber ?? '';
    _contactNumberController.text = widget.driver.contactNumber ?? '';
    _driverLicenseNumberController.text =
        widget.driver.driverLicenseNumber ?? '';
    _genderController.text = _mapGenderToDisplay(widget.driver.gender);
    _birthdateController.text = formatDateTime(widget.driver.birthdate);
    _firstLicenseDateController.text =
        formatDateTime(widget.driver.firstLicenseDate);
    _allowedVehicleTypeController.text = widget.driver.allowedVehicleType ?? '';
    _issueDateController.text = formatDateTime(widget.driver.issueDate);
    _expiryDateController.text = formatDateTime(widget.driver.expiryDate);
  }

  String _mapGenderToDisplay(String? gender) {
    if (gender == 'Male') return '男';
    if (gender == 'Female') return '女';
    return '';
  }

  String? _mapGenderToBackend(String gender) {
    if (gender.isEmpty) return null;
    if (gender == '男') return 'Male';
    if (gender == '女') return 'Female';
    return null;
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
      AppUtils.showSnackBar(context, '请修正表单中的错误', isError: true);
      return;
    }
    if (widget.driver.driverId == null) {
      AppUtils.showSnackBar(context, '司机ID无效，无法更新', isError: true);
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
        gender: _mapGenderToBackend(_genderController.text.trim()),
        birthdate: _birthdateController.text.trim().isEmpty ||
                _birthdateController.text == '无'
            ? null
            : DateTime.tryParse('${_birthdateController.text.trim()}T00:00:00'),
        firstLicenseDate: _firstLicenseDateController.text.trim().isEmpty ||
                _firstLicenseDateController.text == '无'
            ? null
            : DateTime.tryParse(
                '${_firstLicenseDateController.text.trim()}T00:00:00'),
        allowedVehicleType: _allowedVehicleTypeController.text.trim().isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: _issueDateController.text.trim().isEmpty ||
                _issueDateController.text == '无'
            ? null
            : DateTime.tryParse('${_issueDateController.text.trim()}T00:00:00'),
        expiryDate: _expiryDateController.text.trim().isEmpty ||
                _expiryDateController.text == '无'
            ? null
            : DateTime.tryParse(
                '${_expiryDateController.text.trim()}T00:00:00'),
      );

      developer.log('Submitting driver update: ${driver.toJson()}',
          name: 'EditDriverPage');

      const maxRetries = 3;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final idempotencyKey = generateIdempotencyKey();
          developer.log('Attempt $attempt with idempotencyKey: $idempotencyKey',
              name: 'EditDriverPage');
          await driverApi.apiDriversDriverIdPut(
            driverId: widget.driver.driverId!,
            driverInformation: driver,
            idempotencyKey: idempotencyKey,
          );
          if (mounted) {
            AppUtils.showSnackBar(context, '更新司机成功！');
            Navigator.pop(context, true);
          }
          return;
        } catch (e) {
          developer.log('Attempt $attempt failed: $e', name: 'EditDriverPage');
          if (attempt == maxRetries) {
            rethrow;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          '更新失败：${AppUtils.formatErrorMessage(e)}. 请确保性别为“男”或“女”，或联系管理员。',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(TextEditingController textController) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(textController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => Theme(
        data: controller.currentBodyTheme.value,
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        textController.text = formatDateTime(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return DashboardPageTemplate(
        theme: themeData,
        title: '编辑司机信息',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        onThemeToggle: controller.toggleBodyTheme,
        body: Padding(
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
                            AppUtils.buildTextField(
                              themeData,
                              '姓名 *',
                              Icons.person,
                              _nameController,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '姓名不能为空';
                                }
                                if (value.length < 2 || value.length > 50) {
                                  return '姓名长度必须在2到50个字符之间';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '身份证号码 *',
                              Icons.card_membership,
                              _idCardNumberController,
                              keyboardType: TextInputType.number,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '身份证号码不能为空';
                                }
                                if (!RegExp(r'^(\d{17}[\dX]|\d{15})$')
                                    .hasMatch(value)) {
                                  return '请输入有效的身份证号码（15或18位）';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '联系电话 *',
                              Icons.phone,
                              _contactNumberController,
                              keyboardType: TextInputType.phone,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '联系电话不能为空';
                                }
                                if (!RegExp(r'^1[3-9]\d{9}$')
                                    .hasMatch(value)) {
                                  return '请输入有效的11位手机号码';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '驾驶证号 *',
                              Icons.drive_eta,
                              _driverLicenseNumberController,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '驾驶证号不能为空';
                                }
                                if (!RegExp(r'^\d{12}$').hasMatch(value)) {
                                  return '请输入有效的12位驾驶证号';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '性别',
                              Icons.person_outline,
                              _genderController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                if (!['男', '女'].contains(value)) {
                                  return '性别必须为“男”或“女”';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '出生日期',
                              Icons.calendar_today,
                              _birthdateController,
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(_birthdateController),
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '首次领证日期',
                              Icons.calendar_today,
                              _firstLicenseDateController,
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(_firstLicenseDateController),
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '允许驾驶车辆类型',
                              Icons.directions_car,
                              _allowedVehicleTypeController,
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '发证日期',
                              Icons.calendar_today,
                              _issueDateController,
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(_issueDateController),
                            ),
                            const SizedBox(height: 16),
                            AppUtils.buildTextField(
                              themeData,
                              '有效期截止日期',
                              Icons.calendar_today,
                              _expiryDateController,
                              readOnly: true,
                              onTap: () =>
                                  _selectDate(_expiryDateController),
                            ),
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
      );
    });
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
  final ScrollController _scrollController = ScrollController();

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
      if (mounted) {
        AppUtils.showSnackBar(context, AppUtils.formatErrorMessage(e),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDriver(int? driverId) async {
    if (driverId == null) {
      AppUtils.showSnackBar(context, '司机ID无效，无法删除', isError: true);
      return;
    }
    final confirmed =
        await AppUtils.showConfirmationDialog(context, '确认删除', '您确定要删除此司机信息吗？');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      const maxRetries = 3;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          developer.log('Attempt $attempt to delete driver ID: $driverId',
              name: 'DriverDetailPage');
          await driverApi.apiDriversDriverIdDelete(driverId: driverId);
          if (mounted) {
            AppUtils.showSnackBar(context, '删除司机成功！');
            Navigator.pop(context, true);
          }
          return;
        } catch (e) {
          developer.log('Delete attempt $attempt failed: $e',
              name: 'DriverDetailPage');
          if (attempt == maxRetries) {
            rethrow;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, AppUtils.formatErrorMessage(e),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDriverDetails() async {
    if (_driver.driverId == null) {
      AppUtils.showSnackBar(context, '司机ID无效，无法加载详情', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      developer.log('Loading driver details for ID: ${_driver.driverId}',
          name: 'DriverDetailPage');
      final updatedDriver =
          await driverApi.apiDriversDriverIdGet(driverId: _driver.driverId!);
      if (updatedDriver != null && mounted) {
        setState(() {
          _driver = updatedDriver;
          developer.log('Driver details updated: ${updatedDriver.toJson()}',
              name: 'DriverDetailPage');
        });
      } else {
        AppUtils.showSnackBar(context, '无法加载司机信息', isError: true);
      }
    } catch (e) {
      developer.log('Error loading driver details: $e',
          name: 'DriverDetailPage');
      if (mounted) {
        AppUtils.showSnackBar(context, AppUtils.formatErrorMessage(e),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapGenderToDisplay(String? gender) {
    if (gender == 'Male') return '男';
    if (gender == 'Female') return '女';
    return gender ?? '未知';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      final gender = _mapGenderToDisplay(_driver.gender);
      final birthdate = formatDateTime(_driver.birthdate);
      final firstLicenseDate = formatDateTime(_driver.firstLicenseDate);
      final allowedVehicleType = _driver.allowedVehicleType ?? '无';
      final issueDate = formatDateTime(_driver.issueDate);
      final expiryDate = formatDateTime(_driver.expiryDate);

      return DashboardPageTemplate(
        theme: themeData,
        title: '司机详细信息',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          DashboardPageBarAction(
            icon: Icons.edit,
            onPressed: () => Get.to(() => EditDriverPage(driver: _driver))
                ?.then((value) {
              if (value == true && mounted) {
                developer.log(
                    'EditDriverPage returned true, refreshing details',
                    name: 'DriverDetailPage');
                _loadDriverDetails();
              }
            }),
            tooltip: '编辑司机',
          ),
          DashboardPageBarAction(
            icon: Icons.delete,
            onPressed: () => _deleteDriver(_driver.driverId),
            tooltip: '删除司机',
            color: themeData.colorScheme.error,
          ),
        ],
        onThemeToggle: controller.toggleBodyTheme,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(
                  child: CupertinoActivityIndicator(
                    color: themeData.colorScheme.primary,
                    radius: 16.0,
                  ),
                )
              : CupertinoScrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6.0,
                  thicknessWhileDragging: 10.0,
                  child: SingleChildScrollView(
                    controller: _scrollController,
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
}

class AppUtils {
  static String formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 401:
          return '未授权: 请重新登录';
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        case 500:
          return '服务器错误: 请稍后重试';
        default:
          return '未知错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }

  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    final themeData = Get.find<DashboardController>().currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
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

  static Widget buildTextField(
    ThemeData themeData,
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    bool required = false,
    String? Function(String?)? validator,
    VoidCallback? onClear,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        suffixIcon: readOnly
            ? Icon(Icons.calendar_today, color: themeData.colorScheme.primary)
            : controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: themeData.colorScheme.onSurfaceVariant),
                    onPressed: onClear ?? () => controller.clear(),
                  )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
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
      validator: validator ??
          (required ? (value) => value!.isEmpty ? '$label不能为空' : null : null),
    );
  }

  static Future<bool> showConfirmationDialog(
      BuildContext context, String title, String content) async {
    final themeData = Get.find<DashboardController>().currentBodyTheme.value;
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
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                content,
                style: themeData.textTheme.bodyMedium
                    ?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
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
}
