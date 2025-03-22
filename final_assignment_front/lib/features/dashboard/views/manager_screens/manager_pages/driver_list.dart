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
  return DateTime
      .now()
      .millisecondsSinceEpoch
      .toString();
}

class DriverList extends StatefulWidget {
  const DriverList({super.key});

  @override
  State<DriverList> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverList> {
  late DriverInformationControllerApi driverApi;
  List<DriverInformation> _drivers = [];
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
      _drivers = await driverApi.apiDriversGet() ?? [];
      developer.log('Loaded drivers: $_drivers');
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

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await driverApi.initializeWithJwt();
      if (_nameController.text.isNotEmpty) {
        _drivers = await driverApi.apiDriversNameNameGet(
            name: _nameController.text.trim()) ??
            [];
      } else if (_idCardNumberController.text.isNotEmpty) {
        _drivers = await driverApi.apiDriversIdCardNumberIdCardNumberGet(
            idCardNumber: _idCardNumberController.text.trim()) ??
            [];
      } else if (_driverLicenseNumberController.text.isNotEmpty) {
        final driver =
        await driverApi.apiDriversDriverLicenseNumberDriverLicenseNumberGet(
            driverLicenseNumber:
            _driverLicenseNumberController.text.trim());
        _drivers = driver != null ? [driver] : [];
      } else {
        _drivers = await driverApi.apiDriversGet() ?? [];
      }
      developer.log('Filtered drivers: $_drivers');
      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('Error applying filters: $e',
          stackTrace: StackTrace.current);
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e);
        if (e.toString().contains('未登录')) _redirectToLogin();
      });
    }
  }

  Future<void> _deleteDriver(String driverId) async {
    final confirmed = await _showConfirmationDialog(
        '确认删除', '您确定要删除此司机信息吗？');
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
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    if (!mounted) return false;
    final themeData = controller.currentBodyTheme.value;
    return await showDialog<bool>(
      context: context,
      builder: (context) =>
          Theme(
            data: themeData,
            child: AlertDialog(
              backgroundColor: themeData.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: Text(title,
                  style: themeData.textTheme.titleMedium
                      ?.copyWith(color: themeData.colorScheme.onSurface)),
              content: Text(content,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('取消',
                      style: themeData.textTheme.labelMedium
                          ?.copyWith(color: themeData.colorScheme.onSurface)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('确定',
                      style: themeData.textTheme.labelMedium
                          ?.copyWith(color: themeData.colorScheme.primary)),
                ),
              ],
            ),
          ),
    ) ??
        false;
  }

  void _goToDetailPage(DriverInformation driver) {
    Get.to(() => DriverDetailPage(driver: driver))?.then((value) {
      if (value == true && mounted) _loadDrivers();
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '无';
    return "${dateTime.year}-${dateTime.month.toString().padLeft(
        2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
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
              ),
            ),
            trailing: GestureDetector(
              onTap: () =>
                  Get.to(() => const AddDriverPage())?.then((value) {
                    if (value == true && mounted) _loadDrivers();
                  }),
              child: Icon(
                CupertinoIcons.add,
                color: themeData.colorScheme.onPrimaryContainer,
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
              child: Column(
                children: [
                  _buildSearchBar(themeData),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? Center(
                      child: CupertinoActivityIndicator(
                        color: themeData.colorScheme.primary,
                        radius: 16.0,
                      ),
                    )
                        : _errorMessage.isNotEmpty
                        ? Center(
                      child: Text(
                        _errorMessage,
                        style:
                        themeData.textTheme.bodyLarge?.copyWith(
                          color: themeData.colorScheme.error,
                          fontSize: 18,
                        ),
                      ),
                    )
                        : _drivers.isEmpty
                        ? Center(
                      child: Text(
                        '暂无司机信息',
                        style: themeData.textTheme.bodyLarge
                            ?.copyWith(
                          color: themeData
                              .colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                        : CupertinoScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 6.0,
                      thicknessWhileDragging: 10.0,
                      child: RefreshIndicator(
                        onRefresh: _applyFilters,
                        color: themeData.colorScheme.primary,
                        backgroundColor: themeData
                            .colorScheme.surfaceContainer,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _drivers.length,
                          itemBuilder: (context, index) {
                            final driver = _drivers[index];
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

  Widget _buildSearchBar(ThemeData themeData) {
    return Card(
      elevation: 2,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: '按姓名搜索',
                      labelStyle: TextStyle(
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
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLow,
                    ),
                    onSubmitted: (value) => _applyFilters(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idCardNumberController,
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: '按身份证号搜索',
                      labelStyle: TextStyle(
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
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLow,
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (value) => _applyFilters(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _driverLicenseNumberController,
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: '按驾驶证号搜索',
                      labelStyle: TextStyle(
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
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLow,
                    ),
                    onSubmitted: (value) => _applyFilters(),
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
      elevation: 3,
      color: themeData.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          '司机姓名: ${driver.name ?? "未知"} (ID: ${driver.driverId ?? "无"})',
          style: themeData.textTheme.bodyLarge?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '驾驶证号: ${driver.driverLicenseNumber ?? "无"}\n联系电话: ${driver
              .contactNumber ?? "无"}',
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          CupertinoIcons.forward,
          color: themeData.colorScheme.primary,
          size: 16,
        ),
        onTap: () => _goToDetailPage(driver),
      ),
    );
  }
}

class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final driverApi = DriverInformationControllerApi();
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

      DateTime? birthdate = _birthdateController.text
          .trim()
          .isEmpty
          ? null
          : DateTime.parse("${_birthdateController.text.trim()}T00:00:00");
      DateTime? firstLicenseDate = _firstLicenseDateController.text
          .trim()
          .isEmpty
          ? null
          : DateTime.parse(
          "${_firstLicenseDateController.text.trim()}T00:00:00");
      DateTime? issueDate = _issueDateController.text
          .trim()
          .isEmpty
          ? null
          : DateTime.parse("${_issueDateController.text.trim()}T00:00:00");
      DateTime? expiryDate = _expiryDateController.text
          .trim()
          .isEmpty
          ? null
          : DateTime.parse("${_expiryDateController.text.trim()}T00:00:00");

      final driver = DriverInformation(
        name: _nameController.text
            .trim()
            .isEmpty ? null : _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text
            .trim()
            .isEmpty
            ? null
            : _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text
            .trim()
            .isEmpty
            ? null
            : _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text
            .trim()
            .isEmpty
            ? null
            : _driverLicenseNumberController.text.trim(),
        gender: _genderController.text
            .trim()
            .isEmpty ? null : _genderController.text.trim(),
        birthdate: birthdate,
        firstLicenseDate: firstLicenseDate,
        allowedVehicleType: _allowedVehicleTypeController.text
            .trim()
            .isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: issueDate,
        expiryDate: expiryDate,
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
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
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
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        textController.text =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(
            2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
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
            title: Text(
              '添加新司机',
              style: themeData.textTheme.headlineSmall?.copyWith(
                color: themeData.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
              onPressed: () => Get.back(),
            ),
            backgroundColor: themeData.colorScheme.primaryContainer,
            elevation: 1,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: themeData.colorScheme.primary,
                ),
              )
                  : SingleChildScrollView(child: _buildDriverForm(themeData)),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDriverForm(ThemeData themeData) {
    return Column(
      children: [
        _buildTextField(themeData, '姓名', Icons.person, _nameController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '身份证号码', Icons.card_membership,
            _idCardNumberController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '联系电话', Icons.phone, _contactNumberController,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '驾驶证号', Icons.drive_eta,
            _driverLicenseNumberController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '性别', Icons.person_outline, _genderController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '出生日期', Icons.calendar_today, _birthdateController,
            readOnly: true, onTap: () => _selectDate(_birthdateController)),
        const SizedBox(height: 12),
        _buildTextField(themeData, '首次领证日期', Icons.calendar_today,
            _firstLicenseDateController,
            readOnly: true,
            onTap: () => _selectDate(_firstLicenseDateController)),
        const SizedBox(height: 12),
        _buildTextField(themeData, '允许驾驶车辆类型', Icons.directions_car,
            _allowedVehicleTypeController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '发证日期', Icons.calendar_today, _issueDateController,
            readOnly: true, onTap: () => _selectDate(_issueDateController)),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '有效期截止日期', Icons.calendar_today,
            _expiryDateController,
            readOnly: true, onTap: () => _selectDate(_expiryDateController)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitDriver,
          style: themeData.elevatedButtonTheme.style,
          child: const Text('提交'),
        ),
      ],
    );
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainerLow,
        labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
      ),
      style: TextStyle(color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  String generateIdempotencyKey() {
    // Replace with your actual implementation for generating an idempotency key
    return DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
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
  }

  void _initializeFields() {
    _nameController.text = widget.driver.name ?? '';
    _idCardNumberController.text = widget.driver.idCardNumber ?? '';
    _contactNumberController.text = widget.driver.contactNumber ?? '';
    _driverLicenseNumberController.text =
        widget.driver.driverLicenseNumber ?? '';
    _genderController.text = widget.driver.gender ?? '';
    _birthdateController.text = widget.driver.birthdate != null
        ? "${widget.driver.birthdate!.year}-${widget.driver.birthdate!.month
        .toString().padLeft(2, '0')}-${widget.driver.birthdate!
        .day
        .toString()
        .padLeft(2, '0')}"
        : '';
    _firstLicenseDateController.text = widget.driver.firstLicenseDate != null
        ? "${widget.driver.firstLicenseDate!.year}-${widget.driver
        .firstLicenseDate!.month.toString().padLeft(2, '0')}-${widget.driver
        .firstLicenseDate!.day.toString().padLeft(2, '0')}"
        : '';
    _allowedVehicleTypeController.text = widget.driver.allowedVehicleType ?? '';
    _issueDateController.text = widget.driver.issueDate != null
        ? "${widget.driver.issueDate!.year}-${widget.driver.issueDate!.month
        .toString().padLeft(2, '0')}-${widget.driver.issueDate!
        .day
        .toString()
        .padLeft(2, '0')}"
        : '';
    _expiryDateController.text = widget.driver.expiryDate != null
        ? "${widget.driver.expiryDate!.year}-${widget.driver.expiryDate!.month
        .toString().padLeft(2, '0')}-${widget.driver.expiryDate!
        .day
        .toString()
        .padLeft(2, '0')}"
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

      DateTime? birthdate = _birthdateController.text
          .trim()
          .isEmpty
          ? null
          : DateTime.parse("${_birthdateController.text.trim()}T00:00:00");
      DateTime? firstLicenseDate =
      _firstLicenseDateController.text
          .trim()
          .isEmpty
          ? null
          : DateTime.parse(
          "${_firstLicenseDateController.text.trim()}T00:00:00");
      DateTime? issueDate = _issueDateController.text
          .trim()
          .isEmpty
          ? null
          : DateTime.parse("${_issueDateController.text.trim()}T00:00:00");
      DateTime? expiryDate = _expiryDateController.text
          .trim()
          .isEmpty
          ? null
          : DateTime.parse("${_expiryDateController.text.trim()}T00:00:00");

      final driver = DriverInformation(
        driverId: widget.driver.driverId,
        name: _nameController.text
            .trim()
            .isEmpty
            ? null
            : _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text
            .trim()
            .isEmpty
            ? null
            : _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text
            .trim()
            .isEmpty
            ? null
            : _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text
            .trim()
            .isEmpty
            ? null
            : _driverLicenseNumberController.text.trim(),
        gender: _genderController.text
            .trim()
            .isEmpty
            ? null
            : _genderController.text.trim(),
        birthdate: birthdate,
        firstLicenseDate: firstLicenseDate,
        allowedVehicleType: _allowedVehicleTypeController.text
            .trim()
            .isEmpty
            ? null
            : _allowedVehicleTypeController.text.trim(),
        issueDate: issueDate,
        expiryDate: expiryDate,
      );
      await driverApi.apiDriversDriverIdPut(
        driverId: widget.driver.driverId?.toString() ?? '',
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
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
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
      builder: (context, child) =>
          Theme(data: controller.currentBodyTheme.value, child: child!),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        textController.text =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(
            2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
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
                  : SingleChildScrollView(child: _buildDriverForm(themeData)),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDriverForm(ThemeData themeData) {
    return Column(
      children: [
        _buildTextField(themeData, '姓名', Icons.person, _nameController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '身份证号码', Icons.card_membership,
            _idCardNumberController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '联系电话', Icons.phone, _contactNumberController,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '驾驶证号', Icons.drive_eta,
            _driverLicenseNumberController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '性别', Icons.person_outline, _genderController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '出生日期', Icons.calendar_today, _birthdateController,
            readOnly: true, onTap: () => _selectDate(_birthdateController)),
        const SizedBox(height: 12),
        _buildTextField(themeData, '首次领证日期', Icons.calendar_today,
            _firstLicenseDateController,
            readOnly: true,
            onTap: () => _selectDate(_firstLicenseDateController)),
        const SizedBox(height: 12),
        _buildTextField(themeData, '允许驾驶车辆类型', Icons.directions_car,
            _allowedVehicleTypeController),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '发证日期', Icons.calendar_today, _issueDateController,
            readOnly: true, onTap: () => _selectDate(_issueDateController)),
        const SizedBox(height: 12),
        _buildTextField(
            themeData, '有效期截止日期', Icons.calendar_today,
            _expiryDateController,
            readOnly: true, onTap: () => _selectDate(_expiryDateController)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitDriver,
          style: themeData.elevatedButtonTheme.style,
          child: const Text('保存'),
        ),
      ],
    );
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none),
        filled: true,
        fillColor: themeData.colorScheme.surfaceContainerLow,
        labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
      ),
      style: TextStyle(color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
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
  }

  Future<void> _deleteDriver(String driverId) async {
    final confirmed = await _showConfirmationDialog(
        '确认删除', '您确定要删除此司机信息吗？');
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
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    if (!mounted) return false;
    final themeData = controller.currentBodyTheme.value;
    return await showDialog<bool>(
      context: context,
      builder: (context) =>
          Theme(
            data: themeData,
            child: AlertDialog(
              backgroundColor: themeData.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: Text(title,
                  style: themeData.textTheme.titleMedium
                      ?.copyWith(color: themeData.colorScheme.onSurface)),
              content: Text(content,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('取消',
                      style: themeData.textTheme.labelMedium
                          ?.copyWith(color: themeData.colorScheme.onSurface)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('确定',
                      style: themeData.textTheme.labelMedium
                          ?.copyWith(color: themeData.colorScheme.primary)),
                ),
              ],
            ),
          ),
    ) ??
        false;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '无';
    return "${dateTime.year}-${dateTime.month.toString().padLeft(
        2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
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
      final driverId = _driver.driverId?.toString() ?? '未提供';
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
              ),
            ),
            trailing: GestureDetector(
              onTap: () =>
                  Get.to(() => EditDriverPage(driver: _driver))?.then((value) {
                    if (value == true && mounted) _loadDriverDetails();
                  }),
              child: Icon(
                CupertinoIcons.pencil,
                color: themeData.colorScheme.onPrimaryContainer,
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
                  : CupertinoScrollbar(
                controller: ScrollController(),
                thumbVisibility: true,
                thickness: 6.0,
                thicknessWhileDragging: 10.0,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 2,
                        color: themeData.colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                  '司机 ID', driverId, themeData),
                              _buildDetailRow('姓名', name, themeData),
                              _buildDetailRow('身份证号', idCard, themeData),
                              _buildDetailRow('联系电话', contact, themeData),
                              _buildDetailRow('驾驶证号', license, themeData),
                              _buildDetailRow('性别', gender, themeData),
                              _buildDetailRow(
                                  '出生日期', birthdate, themeData),
                              _buildDetailRow(
                                  '首次领证日期', firstLicenseDate, themeData),
                              _buildDetailRow('允许驾驶车辆类型',
                                  allowedVehicleType, themeData),
                              _buildDetailRow(
                                  '发证日期', issueDate, themeData),
                              _buildDetailRow(
                                  '有效期截止日期', expiryDate, themeData),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteDriver(driverId),
                          icon: const Icon(CupertinoIcons.trash),
                          label: const Text('删除'),
                          style: themeData.elevatedButtonTheme.style
                              ?.copyWith(
                            backgroundColor: WidgetStatePropertyAll(
                                themeData.colorScheme.error),
                            foregroundColor: WidgetStatePropertyAll(
                                themeData.colorScheme.onError),
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

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
