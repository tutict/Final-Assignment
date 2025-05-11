import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/deduction_information_controller_api.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'dart:developer' as developer;

import '../log_pages/operation_log_page.dart';

class DeductionManagement extends StatefulWidget {
  const DeductionManagement({super.key});

  @override
  State<DeductionManagement> createState() => _DeductionManagementState();
}

class _DeductionManagementState extends State<DeductionManagement> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final List<DeductionInformation> _deductions = [];
  List<DeductionInformation> _filteredDeductions = [];
  String _searchType = 'handler';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAdmin = false;
  DateTime? _startTime;
  DateTime? _endTime;
  final DashboardController controller = Get.find<DashboardController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(() {
      _applyFilters(_searchController.text);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadDeductions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        setState(() => _errorMessage = '登录已过期，请重新登录');
        return false;
      }
      return true;
    } catch (e) {
      setState(() => _errorMessage = '无效的登录信息，请重新登录');
      return false;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      await deductionApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken')!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      _isAdmin = decodedToken['roles'] == 'ADMIN' ||
          (decodedToken['roles'] is List &&
              decodedToken['roles'].contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = '权限不足：仅管理员可访问此页面');
        return;
      }
      await _loadDeductions(reset: true);
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDeductions({bool reset = false, String? query}) async {
    if (!_isAdmin || !_hasMore) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _deductions.clear();
      _filteredDeductions.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      List<DeductionInformation> deductions = [];
      final searchQuery = query?.trim() ?? '';
      if (searchQuery.isEmpty && _startTime == null && _endTime == null) {
        deductions = await deductionApi.apiDeductionsGet() ?? [];
        deductions.sort((a, b) {
          final aTime = a.deductionTime ?? DateTime(1970);
          final bTime = b.deductionTime ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
      } else if (_searchType == 'handler' && searchQuery.isNotEmpty) {
        deductions = await deductionApi.apiDeductionsByHandlerGet(
                handler: searchQuery) ??
            [];
      } else if (_searchType == 'driverLicenseNumber' &&
          searchQuery.isNotEmpty) {
        deductions = await deductionApi.apiDeductionsGet() ?? [];
        deductions = deductions
            .where((d) => (d.driverLicenseNumber ?? '')
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();
      } else if (_searchType == 'timeRange' &&
          _startTime != null &&
          _endTime != null) {
        deductions = await deductionApi.apiDeductionsByTimeRangeGet(
              startTime: _startTime!.toIso8601String(),
              endTime: _endTime!.add(const Duration(days: 1)).toIso8601String(),
            ) ??
            [];
      }

      setState(() {
        _deductions.addAll(deductions);
        _hasMore = deductions.length == _pageSize;
        _applyFilters(query ?? _searchController.text);
        if (_filteredDeductions.isEmpty) {
          _errorMessage =
              searchQuery.isNotEmpty || (_startTime != null && _endTime != null)
                  ? '未找到符合条件的扣分记录'
                  : '暂无扣分记录';
        }
        _currentPage++;
      });
      developer.log('Loaded deductions: ${_deductions.length}');
    } catch (e) {
      developer.log('Error fetching deductions: $e',
          stackTrace: StackTrace.current);
      setState(() {
        if (e is ApiException && e.code == 404) {
          _deductions.clear();
          _filteredDeductions.clear();
          _errorMessage = '未找到符合条件的扣分记录';
          _hasMore = false;
        } else if (e.toString().contains('403')) {
          _errorMessage = '未授权，请重新登录';
          Get.offAllNamed(AppPages.login);
        } else {
          _errorMessage = '获取扣分记录失败: ${_formatErrorMessage(e)}';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredDeductions.clear();
      _filteredDeductions = _deductions.where((deduction) {
        final handler = (deduction.handler ?? '').toLowerCase();
        final driverLicenseNumber =
            (deduction.driverLicenseNumber ?? '').toLowerCase();
        final deductionTime = deduction.deductionTime;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty) {
          if (_searchType == 'handler') {
            matchesQuery = handler.contains(searchQuery);
          } else if (_searchType == 'driverLicenseNumber') {
            matchesQuery = driverLicenseNumber.contains(searchQuery);
          }
        }

        bool matchesDateRange = true;
        if (_startTime != null && _endTime != null && deductionTime != null) {
          matchesDateRange = deductionTime.isAfter(_startTime!) &&
              deductionTime.isBefore(_endTime!.add(const Duration(days: 1)));
        } else if (_startTime != null &&
            _endTime != null &&
            deductionTime == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredDeductions.isEmpty && _deductions.isNotEmpty) {
        _errorMessage = '未找到符合条件的扣分记录';
      } else {
        _errorMessage =
            _filteredDeductions.isEmpty && _deductions.isEmpty ? '暂无扣分记录' : '';
      }
    });
  }

  void _createDeduction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDeductionPage()),
    ).then((value) {
      if (value == true) {
        _loadDeductions(reset: true);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.redAccent : themeData.colorScheme.onPrimary,
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

// 新增：显式构建无数据提示
  Widget _buildNoDataWidget(ThemeData themeData) {
    return Center(
      child: Text(
        _errorMessage.isNotEmpty ? _errorMessage : '暂无扣分记录',
        style: themeData.textTheme.bodyLarge?.copyWith(
          color: themeData.colorScheme.onSurface, // 优化：使用 onSurface 确保暗色模式可见
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '扣分管理',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimary,
            ),
          ),
          backgroundColor: themeData.colorScheme.primaryContainer,
          foregroundColor: themeData.colorScheme.onPrimaryContainer,
          elevation: 2,
          actions: [
            if (_isAdmin)
              IconButton(
                icon: Icon(Icons.add,
                    color: themeData.colorScheme.onPrimaryContainer),
                onPressed: _createDeduction,
                tooltip: '添加扣分记录',
              ),
            IconButton(
              icon: Icon(Icons.refresh,
                  color: themeData.colorScheme.onPrimaryContainer),
              onPressed: () => _loadDeductions(reset: true),
              tooltip: '刷新列表',
            ),
            IconButton(
              icon: Icon(
                themeData.brightness == Brightness.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
              onPressed: controller.toggleBodyTheme,
              tooltip: '切换主题',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadDeductions(reset: true),
          color: themeData.colorScheme.primary,
          backgroundColor: themeData.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: _isLoading && _currentPage == 1
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredDeductions.isEmpty
                          ? _buildNoDataWidget(themeData) // 优化：使用显式无数据组件
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _filteredDeductions.length +
                                  (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _filteredDeductions.length &&
                                    _hasMore) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                final deduction = _filteredDeductions[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      '驾驶证号: ${deduction.driverLicenseNumber ?? '未知'}',
                                      style: TextStyle(
                                        color: themeData.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '扣分: ${deduction.deductedPoints ?? 0}',
                                      style: TextStyle(
                                        color: themeData
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditDeductionPage(
                                                  deduction: deduction),
                                        ),
                                      ).then((value) {
                                        if (value == true) {
                                          _loadDeductions(reset: true);
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
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

class AddDeductionPage extends StatefulWidget {
  const AddDeductionPage({super.key});

  @override
  State<AddDeductionPage> createState() => _AddDeductionPageState();
}

class _AddDeductionPageState extends State<AddDeductionPage> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _approverController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  int? _selectedOffenseId;
  final DashboardController controller = Get.find<DashboardController>();

  String generateIdempotencyKey() => const Uuid().v4();

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      _showSnackBar('未授权，请重新登录', isError: true);
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        _showSnackBar('登录已过期，请重新登录', isError: true);
        return false;
      }
      return true;
    } catch (e) {
      _showSnackBar('无效的登录信息，请重新登录', isError: true);
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      await deductionApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await vehicleApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _driverLicenseNumberController.dispose();
    _deductedPointsController.dispose();
    _handlerController.dispose();
    _approverController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchLicensePlateSuggestions(
      String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return [];
      }
      final plates = await vehicleApi.apiVehiclesLicensePlateGloballyGet(
          licensePlate: prefix.trim());
      developer.log('Raw license plate response: $plates');
      final suggestions = plates
          .where((plate) => plate != null && plate.trim().isNotEmpty)
          .map((plate) => {'licensePlate': plate})
          .toList();
      developer.log('Filtered license plate suggestions: $suggestions');
      return suggestions;
    } catch (e) {
      developer.log('Error fetching license plate suggestions: $e',
          stackTrace: StackTrace.current);
      _showSnackBar('获取车牌号建议失败: $e', isError: true);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDriverLicenseSuggestions(
      String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return [];
      }
      if (prefix.trim().isEmpty) return [];
      final drivers = await driverApi.apiDriversByNameGet(
        query: prefix.trim(),
        page: 1,
        size: 10,
      );
      final suggestions = drivers
          .where((d) =>
              d.driverLicenseNumber != null &&
              d.driverLicenseNumber!.trim().isNotEmpty)
          .map((d) => {
                'driverLicenseNumber': d.driverLicenseNumber!,
                'name': d.name ?? '',
                'idCardNumber': d.idCardNumber ?? '',
              })
          .where((item) =>
              item['driverLicenseNumber']
                  .toString()
                  .toLowerCase()
                  .contains(prefix.toLowerCase()) ||
              item['name']
                  .toString()
                  .toLowerCase()
                  .contains(prefix.toLowerCase()))
          .toList();
      developer.log('Driver license suggestions: $suggestions');
      return suggestions;
    } catch (e) {
      if (e is ApiException && e.code == 400 && prefix.trim().isEmpty) {
        return [];
      }
      developer.log('Error fetching driver license suggestions: $e',
          stackTrace: StackTrace.current);
      _showSnackBar('获取驾驶证号建议失败: $e', isError: true);
      return [];
    }
  }

  Future<String?> _fetchDriverLicenseNumberFromOffense(
      String licensePlate) async {
    try {
      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: licensePlate,
        page: 1,
        size: 1,
      );
      if (offenses.isNotEmpty && offenses.first.licensePlate != null) {
        return offenses.first.licensePlate;
      }
      _showSnackBar('未找到与车牌号关联的驾驶证号，请手动输入', isError: true);
      return null;
    } catch (e) {
      developer.log('Error fetching driver license from offense: $e',
          stackTrace: StackTrace.current);
      _showSnackBar('获取驾驶证号失败: $e', isError: true);
      return null;
    }
  }

  Future<void> _onLicensePlateSelected(Map<String, dynamic> selection) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      final licensePlate = selection['licensePlate'] as String?;
      if (licensePlate == null || licensePlate.trim().isEmpty) {
        _showSnackBar('无效的车牌号选择', isError: true);
        return;
      }
      _licensePlateController.text = licensePlate;

      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: licensePlate,
        page: 1,
        size: 10,
      );
      if (offenses.isNotEmpty) {
        final latestOffense = offenses.first;
        final driverLicenseNumber =
            await _fetchDriverLicenseNumberFromOffense(licensePlate);
        setState(() {
          _selectedOffenseId = latestOffense.offenseId;
          _driverLicenseNumberController.text = driverLicenseNumber ?? '';
          _deductedPointsController.text =
              (latestOffense.deductedPoints ?? 0).toString();
          _dateController.text = formatDateTime(latestOffense.offenseTime);
        });
      } else {
        _showSnackBar('未找到与此车牌相关的违法记录', isError: true);
        setState(() {
          _selectedOffenseId = null;
          _driverLicenseNumberController.clear();
          _deductedPointsController.clear();
          _dateController.clear();
        });
      }
    } catch (e) {
      developer.log('Error processing license plate selection: $e',
          stackTrace: StackTrace.current);
      _showSnackBar('处理车牌号失败: $e', isError: true);
      setState(() {
        _selectedOffenseId = null;
        _driverLicenseNumberController.clear();
        _deductedPointsController.clear();
        _dateController.clear();
      });
    }
  }

  Future<void> _onDriverLicenseSelected(Map<String, dynamic> selection) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      final driverLicenseNumber = selection['driverLicenseNumber'] as String?;
      if (driverLicenseNumber == null || driverLicenseNumber.trim().isEmpty) {
        _showSnackBar('无效的驾驶证号选择', isError: true);
        return;
      }
      setState(() {
        _driverLicenseNumberController.text = driverLicenseNumber;
      });
    } catch (e) {
      developer.log('Error processing driver license selection: $e',
          stackTrace: StackTrace.current);
      _showSnackBar('加载驾驶证号信息失败: $e', isError: true);
    }
  }

  Future<void> _submitDeduction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOffenseId == null) {
      _showSnackBar('请先选择一个违法记录', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Get.offAllNamed(AppPages.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final idempotencyKey = generateIdempotencyKey();
      final deduction = DeductionInformation(
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints:
            int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: DateTime.parse('${_dateController.text}T00:00:00.000'),
        handler: _handlerController.text.trim().isEmpty
            ? null
            : _handlerController.text.trim(),
        approver: _approverController.text.trim().isEmpty
            ? null
            : _approverController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        idempotencyKey: idempotencyKey,
      );
      await deductionApi.apiDeductionsPost(
        deductionInformation: deduction,
        idempotencyKey: idempotencyKey,
      );
      _showSnackBar('创建扣分记录成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      developer.log('Error submitting deduction: $e',
          stackTrace: StackTrace.current);
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
            color: isError ? Colors.redAccent : themeData.colorScheme.onPrimary,
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

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    _showSnackBar('扣分时间不可编辑，必须与违法时间一致', isError: true);
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      int? maxLength,
      String? Function(String?)? validator,
      bool isAutocomplete = false,
      Future<List<Map<String, dynamic>>> Function(String)? fetchSuggestions,
      void Function(Map<String, dynamic>)? onSelected}) {
    if (isAutocomplete) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty || fetchSuggestions == null) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            return await fetchSuggestions(textEditingValue.text);
          },
          displayStringForOption: (Map<String, dynamic> option) {
            if (label == '车牌号') {
              return option['licensePlate']?.toString() ?? '';
            } else {
              return option['driverLicenseNumber']?.toString() ?? '';
            }
          },
          onSelected: onSelected,
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6.0,
                // 优化：增加阴影
                color: themeData.colorScheme.surfaceContainerHighest
                    .withOpacity(0.95),
                // 优化：高对比度背景
                borderRadius: BorderRadius.circular(12.0),
                borderOnForeground: true,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: themeData.colorScheme.outline.withOpacity(0.5),
                      // 优化：添加边框
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 200.0,
                    maxWidth: MediaQuery.of(context).size.width - 32.0,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: themeData.colorScheme.outline
                          .withOpacity(0.3), // 优化：添加分隔线
                    ),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          child: Text(
                            label == '车牌号'
                                ? option['licensePlate']?.toString() ?? ''
                                : option['driverLicenseNumber']?.toString() ??
                                    '',
                            style: themeData.textTheme.bodyMedium?.copyWith(
                              color: themeData.colorScheme.onSurface,
                              // 优化：高对比度文字
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            textEditingController.text = controller.text;
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              style: TextStyle(color: themeData.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: themeData.colorScheme.primary),
                helperText: label == '车牌号'
                    ? '请输入车牌号，例如：黑AWS34'
                    : label == '驾驶证号'
                        ? '自动填充或手动输入，与违法记录关联'
                        : null,
                helperStyle: TextStyle(
                    color: themeData.colorScheme.onSurfaceVariant
                        .withOpacity(0.6)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.primary, width: 1.5)),
                filled: true,
                fillColor: themeData.colorScheme.surfaceContainerLowest,
                suffixIcon: textEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: themeData.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          textEditingController.clear();
                          controller.clear();
                          if (label == '车牌号') {
                            setState(() {
                              _selectedOffenseId = null;
                              _driverLicenseNumberController.clear();
                              _deductedPointsController.clear();
                              _dateController.clear();
                            });
                          }
                        },
                      )
                    : null,
              ),
              keyboardType: keyboardType,
              maxLength: maxLength,
              validator: validator ??
                  (value) {
                    final trimmedValue = value?.trim() ?? '';
                    if (required && trimmedValue.isEmpty) return '$label不能为空';
                    if (label == '车牌号') {
                      if (trimmedValue.isEmpty) return '车牌号不能为空';
                      if (trimmedValue.length > 20) return '车牌号不能超过20个字符';
                      if (!RegExp(r'^[\u4e00-\u9fa5][A-Za-z0-9]{5,7}$')
                          .hasMatch(trimmedValue)) {
                        return '请输入有效车牌号，例如：黑AWS34';
                      }
                    }
                    if (label == '驾驶证号' && trimmedValue.length > 50) {
                      return '驾驶证号不能超过50个字符';
                    }
                    return null;
                  },
              onChanged: (value) {
                controller.text = value;
              },
            );
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.primary),
          helperText: label == '处理人' || label == '审批人'
              ? '请输入${label}姓名（选填）'
              : label == '扣分分数'
                  ? '自动填充，与违法记录关联'
                  : null,
          helperStyle: TextStyle(
              color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: readOnly
              ? themeData.colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: controller.text.isNotEmpty && !readOnly
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: themeData.colorScheme.onSurfaceVariant),
                  onPressed: () => controller.clear(),
                )
              : readOnly
                  ? Icon(Icons.lock,
                      size: 18, color: themeData.colorScheme.primary)
                  : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        validator: validator ??
            (value) {
              final trimmedValue = value?.trim() ?? '';
              if (required && trimmedValue.isEmpty) return '$label不能为空';
              if (label == '扣分分数' && trimmedValue.isNotEmpty) {
                final points = int.tryParse(trimmedValue);
                if (points == null) return '扣分分数必须是整数';
                if (points <= 0 || points > 12) return '扣分分数必须在1到12之间';
              }
              if (label == '处理人' || label == '审批人') {
                if (trimmedValue.length > 100) return '$label姓名不能超过100个字符';
              }
              if (label == '备注' && trimmedValue.length > 255) {
                return '备注不能超过255个字符';
              }
              if (label == '扣分时间' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) {
                  return '扣分时间不能晚于当前日期';
                }
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '添加扣分信息',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimary,
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
                                  '车牌号 *',
                                  _licensePlateController,
                                  themeData,
                                  required: true,
                                  maxLength: 20,
                                  isAutocomplete: true,
                                  fetchSuggestions:
                                      _fetchLicensePlateSuggestions,
                                  onSelected: _onLicensePlateSelected,
                                ),
                                _buildTextField(
                                  '驾驶证号 *',
                                  _driverLicenseNumberController,
                                  themeData,
                                  required: true,
                                  maxLength: 50,
                                  isAutocomplete: true,
                                  fetchSuggestions:
                                      _fetchDriverLicenseSuggestions,
                                  onSelected: _onDriverLicenseSelected,
                                ),
                                _buildTextField(
                                  '扣分分数 *',
                                  _deductedPointsController,
                                  themeData,
                                  keyboardType: TextInputType.number,
                                  required: true,
                                  readOnly: true,
                                ),
                                _buildTextField(
                                  '处理人',
                                  _handlerController,
                                  themeData,
                                  maxLength: 100,
                                ),
                                _buildTextField(
                                  '审批人',
                                  _approverController,
                                  themeData,
                                  maxLength: 100,
                                ),
                                _buildTextField(
                                  '备注',
                                  _remarksController,
                                  themeData,
                                  maxLength: 255,
                                ),
                                _buildTextField(
                                  '扣分时间 *',
                                  _dateController,
                                  themeData,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  required: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitDeduction,
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
    });
  }
}

class EditDeductionPage extends StatefulWidget {
  final DeductionInformation deduction;

  const EditDeductionPage({super.key, required this.deduction});

  @override
  State<EditDeductionPage> createState() => _EditDeductionPageState();
}

class _EditDeductionPageState extends State<EditDeductionPage> {
  final DeductionInformationControllerApi deductionApi =
      DeductionInformationControllerApi();
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();
  final TextEditingController _deductedPointsController =
      TextEditingController();
  final TextEditingController _handlerController = TextEditingController();
  final TextEditingController _approverController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  int? _selectedOffenseId;
  final DashboardController controller = Get.find<DashboardController>();

  String generateIdempotencyKey() => const Uuid().v4();

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      _showSnackBar('未授权，请重新登录', isError: true);
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        _showSnackBar('登录已过期，请重新登录', isError: true);
        return false;
      }
      return true;
    } catch (e) {
      _showSnackBar('无效的登录信息，请重新登录', isError: true);
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    _populateFields();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      await deductionApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await vehicleApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar('初始化失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFields() {
    _licensePlateController.text = '';
    _driverLicenseNumberController.text =
        widget.deduction.driverLicenseNumber ?? '';
    _deductedPointsController.text =
        widget.deduction.deductedPoints?.toString() ?? '';
    _handlerController.text = widget.deduction.handler ?? '';
    _approverController.text = widget.deduction.approver ?? '';
    _remarksController.text = widget.deduction.remarks ?? '';
    _dateController.text = formatDateTime(widget.deduction.deductionTime);
    _fetchOffenseForDeduction();
  }

  Future<void> _fetchOffenseForDeduction() async {
    try {
      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: widget.deduction.driverLicenseNumber ?? '',
        page: 1,
        size: 10,
      );
      if (offenses.isNotEmpty) {
        setState(() {
          _selectedOffenseId = offenses.first.offenseId;
          _licensePlateController.text = offenses.first.licensePlate ?? '';
        });
      }
    } catch (e) {
      _showSnackBar('无法加载违法记录: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _driverLicenseNumberController.dispose();
    _deductedPointsController.dispose();
    _handlerController.dispose();
    _approverController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchLicensePlateSuggestions(
      String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return [];
      }
      final plates = await vehicleApi.apiVehiclesLicensePlateGloballyGet(
          licensePlate: prefix.trim());
      return plates.map((plate) => {'licensePlate': plate}).toList();
    } catch (e) {
      _showSnackBar('获取车牌号建议失败: $e', isError: true);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDriverLicenseSuggestions(
      String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return [];
      }
      if (prefix.trim().isEmpty) return [];
      final drivers = await driverApi.apiDriversByNameGet(
        query: prefix.trim(),
        page: 1,
        size: 10,
      );
      return drivers
          .where((d) =>
              d.driverLicenseNumber != null &&
              d.driverLicenseNumber!.isNotEmpty)
          .map((d) => {
                'driverLicenseNumber': d.driverLicenseNumber!,
                'name': d.name ?? '',
                'idCardNumber': d.idCardNumber ?? '',
              })
          .where((item) =>
              item['driverLicenseNumber']
                  .toString()
                  .toLowerCase()
                  .contains(prefix.toLowerCase()) ||
              item['name']
                  .toString()
                  .toLowerCase()
                  .contains(prefix.toLowerCase()))
          .toList();
    } catch (e) {
      if (e is ApiException && e.code == 400 && prefix.trim().isEmpty) {
        return [];
      }
      _showSnackBar('获取驾驶证号建议失败: $e', isError: true);
      return [];
    }
  }

  Future<String?> _fetchDriverLicenseNumberFromOffense(
      String licensePlate) async {
    try {
      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: licensePlate,
        page: 1,
        size: 1,
      );
      if (offenses.isNotEmpty && offenses.first.licensePlate != null) {
        return offenses.first.licensePlate;
      }
      _showSnackBar('未找到与车牌号关联的驾驶证号，请手动输入', isError: true);
      return null;
    } catch (e) {
      _showSnackBar('获取驾驶证号失败: $e', isError: true);
      return null;
    }
  }

  Future<void> _onLicensePlateSelected(Map<String, dynamic> selection) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      final licensePlate = selection['licensePlate'] as String;
      _licensePlateController.text = licensePlate;

      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: licensePlate,
        page: 1,
        size: 10,
      );
      if (offenses.isNotEmpty) {
        final latestOffense = offenses.first;
        final driverLicenseNumber =
            await _fetchDriverLicenseNumberFromOffense(licensePlate);
        setState(() {
          _selectedOffenseId = latestOffense.offenseId;
          _driverLicenseNumberController.text = driverLicenseNumber ?? '';
          _deductedPointsController.text =
              (latestOffense.deductedPoints ?? 0).toString();
          _dateController.text = formatDateTime(latestOffense.offenseTime);
        });
      } else {
        _showSnackBar('未找到与此车牌相关的违法记录', isError: true);
        setState(() {
          _selectedOffenseId = null;
          _driverLicenseNumberController.clear();
          _deductedPointsController.clear();
          _dateController.clear();
        });
      }
    } catch (e) {
      _showSnackBar('处理车牌号失败: $e', isError: true);
      setState(() {
        _selectedOffenseId = null;
        _driverLicenseNumberController.clear();
        _deductedPointsController.clear();
        _dateController.clear();
      });
    }
  }

  Future<void> _onDriverLicenseSelected(Map<String, dynamic> selection) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      setState(() {
        _driverLicenseNumberController.text = selection['driverLicenseNumber'];
      });
    } catch (e) {
      _showSnackBar('加载驾驶证号信息失败: $e', isError: true);
    }
  }

  Future<void> _submitDeduction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOffenseId == null) {
      _showSnackBar('请先选择一个违法记录', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Get.offAllNamed(AppPages.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final idempotencyKey = generateIdempotencyKey();
      final deduction = DeductionInformation(
        deductionId: widget.deduction.deductionId,
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        deductedPoints:
            int.tryParse(_deductedPointsController.text.trim()) ?? 0,
        deductionTime: DateTime.parse('${_dateController.text}T00:00:00.000'),
        handler: _handlerController.text.trim().isEmpty
            ? null
            : _handlerController.text.trim(),
        approver: _approverController.text.trim().isEmpty
            ? null
            : _approverController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        idempotencyKey: idempotencyKey,
      );
      await deductionApi.apiDeductionsDeductionIdPut(
        deductionId: widget.deduction.deductionId!,
        deductionInformation: deduction,
        idempotencyKey: idempotencyKey,
      );
      _showSnackBar('更新扣分记录成功！');
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
            color: isError ? Colors.redAccent : themeData.colorScheme.onPrimary,
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

  Future<void> _pickDate() async {
    _showSnackBar('扣分时间不可编辑，必须与违法时间一致', isError: true);
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      int? maxLength,
      String? Function(String?)? validator,
      bool isAutocomplete = false,
      Future<List<Map<String, dynamic>>> Function(String)? fetchSuggestions,
      void Function(Map<String, dynamic>)? onSelected}) {
    if (isAutocomplete) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty || fetchSuggestions == null) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            return await fetchSuggestions(textEditingValue.text);
          },
          displayStringForOption: (Map<String, dynamic> option) =>
              label == '车牌号'
                  ? option['licensePlate']
                  : option['driverLicenseNumber'],
          onSelected: onSelected,
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6.0,
                // 优化：增加阴影
                color: themeData.colorScheme.surfaceContainerHighest
                    .withOpacity(0.95),
                // 优化：高对比度背景
                borderRadius: BorderRadius.circular(12.0),
                borderOnForeground: true,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: themeData.colorScheme.outline.withOpacity(0.5),
                      // 优化：添加边框
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 200.0,
                    maxWidth: MediaQuery.of(context).size.width - 32.0,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: themeData.colorScheme.outline
                          .withOpacity(0.3), // 优化：添加分隔线
                    ),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          child: Text(
                            label == '车牌号'
                                ? option['licensePlate']?.toString() ?? ''
                                : option['driverLicenseNumber']?.toString() ??
                                    '',
                            style: themeData.textTheme.bodyMedium?.copyWith(
                              color: themeData.colorScheme.onSurface,
                              // 优化：高对比度文字
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            textEditingController.text = controller.text;
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              style: TextStyle(color: themeData.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: themeData.colorScheme.primary),
                helperText: label == '车牌号'
                    ? '请输入车牌号，例如：黑AWS34'
                    : label == '驾驶证号'
                        ? '自动填充或手动输入，与违法记录关联'
                        : null,
                helperStyle: TextStyle(
                    color: themeData.colorScheme.onSurfaceVariant
                        .withOpacity(0.6)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.primary, width: 1.5)),
                filled: true,
                fillColor: themeData.colorScheme.surfaceContainerLowest,
                suffixIcon: textEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: themeData.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          textEditingController.clear();
                          controller.clear();
                          if (label == '车牌号') {
                            setState(() {
                              _selectedOffenseId = null;
                              _driverLicenseNumberController.clear();
                              _deductedPointsController.clear();
                              _dateController.clear();
                            });
                          }
                        },
                      )
                    : null,
              ),
              keyboardType: keyboardType,
              maxLength: maxLength,
              validator: validator ??
                  (value) {
                    final trimmedValue = value?.trim() ?? '';
                    if (required && trimmedValue.isEmpty) return '$label不能为空';
                    if (label == '车牌号') {
                      if (trimmedValue.isEmpty) return '车牌号不能为空';
                      if (trimmedValue.length > 20) return '车牌号不能超过20个字符';
                      if (!RegExp(r'^[\u4e00-\u9fa5][A-Za-z0-9]{5,7}$')
                          .hasMatch(trimmedValue)) {
                        return '请输入有效车牌号，例如：黑AWS34';
                      }
                    }
                    if (label == '驾驶证号' && trimmedValue.length > 50) {
                      return '驾驶证号不能超过50个字符';
                    }
                    return null;
                  },
              onChanged: (value) {
                controller.text = value;
              },
            );
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.primary),
          helperText: label == '处理人' || label == '审批人'
              ? '请输入${label}姓名（选填）'
              : label == '扣分分数'
                  ? '自动填充，与违法记录关联'
                  : null,
          helperStyle: TextStyle(
              color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: readOnly
              ? themeData.colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: controller.text.isNotEmpty && !readOnly
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: themeData.colorScheme.onSurfaceVariant),
                  onPressed: () => controller.clear(),
                )
              : readOnly
                  ? Icon(Icons.lock,
                      size: 18, color: themeData.colorScheme.primary)
                  : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        validator: validator ??
            (value) {
              final trimmedValue = value?.trim() ?? '';
              if (required && trimmedValue.isEmpty) return '$label不能为空';
              if (label == '扣分分数' && trimmedValue.isNotEmpty) {
                final points = int.tryParse(trimmedValue);
                if (points == null) return '扣分分数必须是整数';
                if (points <= 0 || points > 12) return '扣分分数必须在1到12之间';
              }
              if (label == '处理人' || label == '审批人') {
                if (trimmedValue.length > 100) return '$label姓名不能超过100个字符';
              }
              if (label == '备注' && trimmedValue.length > 255) {
                return '备注不能超过255个字符';
              }
              if (label == '扣分时间' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return '无效的日期格式';
                if (date.isAfter(DateTime.now())) {
                  return '扣分时间不能晚于当前日期';
                }
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '编辑扣分信息',
            style: themeData.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onPrimary,
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
                                  '车牌号 *',
                                  _licensePlateController,
                                  themeData,
                                  required: true,
                                  maxLength: 20,
                                  isAutocomplete: true,
                                  fetchSuggestions:
                                      _fetchLicensePlateSuggestions,
                                  onSelected: _onLicensePlateSelected,
                                ),
                                _buildTextField(
                                  '驾驶证号 *',
                                  _driverLicenseNumberController,
                                  themeData,
                                  required: true,
                                  maxLength: 50,
                                  isAutocomplete: true,
                                  fetchSuggestions:
                                      _fetchDriverLicenseSuggestions,
                                  onSelected: _onDriverLicenseSelected,
                                ),
                                _buildTextField(
                                  '扣分分数 *',
                                  _deductedPointsController,
                                  themeData,
                                  keyboardType: TextInputType.number,
                                  required: true,
                                  readOnly: true,
                                ),
                                _buildTextField(
                                  '处理人',
                                  _handlerController,
                                  themeData,
                                  maxLength: 100,
                                ),
                                _buildTextField(
                                  '审批人',
                                  _approverController,
                                  themeData,
                                  maxLength: 100,
                                ),
                                _buildTextField(
                                  '备注',
                                  _remarksController,
                                  themeData,
                                  maxLength: 255,
                                ),
                                _buildTextField(
                                  '扣分时间 *',
                                  _dateController,
                                  themeData,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  required: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitDeduction,
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
    });
  }
}
