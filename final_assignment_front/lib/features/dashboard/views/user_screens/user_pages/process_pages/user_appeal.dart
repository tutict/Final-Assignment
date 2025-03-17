import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class UserAppealPage extends StatefulWidget {
  const UserAppealPage({super.key});

  @override
  State<UserAppealPage> createState() => _UserAppealPageState();
}

class _UserAppealPageState extends State<UserAppealPage> {
  late AppealManagementControllerApi appealApi;
  late DriverInformationControllerApi driverApi;
  final ApiClient apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  List<AppealManagement> _appeals = [];
  bool _isLoading = true;
  bool _isUser = false;
  String _errorMessage = '';
  late ScrollController _scrollController;
  bool _hasOffenses = false;
  List<dynamic> _userOffenses = [];

  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  // Filter options
  String? _selectedStatus;
  DateTime? _startTime;
  DateTime? _endTime;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    driverApi = DriverInformationControllerApi();
    _scrollController = ScrollController();
    _loadAppealsAndCheckRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadAppealsAndCheckRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      apiClient.setJwtToken(jwtToken);
      appealApi.apiClient.setJwtToken(jwtToken);
      driverApi.apiClient.setJwtToken(jwtToken);

      final decodedJwt = _decodeJwt(jwtToken);
      final roles = decodedJwt['roles']?.toString().split(',') ?? [];
      _isUser = roles.contains('USER');
      if (!_isUser) {
        throw Exception('权限不足：仅用户可访问此页面');
      }

      await _checkUserOffenses();
      await _fetchUserAppeals();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT format');
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JWT Decode Error: $e');
      return {};
    }
  }

  Future<void> _checkUserOffenses() async {
    try {
      final response = await apiClient.invokeAPI(
        '/api/offenses/user/me',
        // Hypothetical endpoint for user-specific offenses
        'GET',
        [],
        null,
        await _getHeaders(),
        {},
        'application/json',
        ['bearerAuth'],
      );
      if (response.statusCode == 200) {
        final List<dynamic> offenses =
            jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _userOffenses = offenses;
          _hasOffenses = offenses.isNotEmpty;
        });
      } else {
        throw Exception('检查违法信息失败: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '无法检查违法信息: $e';
      });
    }
  }

  Future<UserManagement?> _fetchUserManagement() async {
    try {
      final response = await apiClient.invokeAPI(
        '/api/users/me',
        'GET',
        [],
        null,
        await _getHeaders(),
        {},
        'application/json',
        ['bearerAuth'],
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserManagement.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to fetch UserManagement: $e');
      return null;
    }
  }

  Future<DriverInformation?> _fetchDriverInformation(int userId) async {
    try {
      return await driverApi.apiDriversDriverIdGet(driverId: userId.toString());
    } catch (e) {
      debugPrint('Failed to fetch DriverInformation: $e');
      return null;
    }
  }

  Future<void> _fetchUserAppeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final appeals = await appealApi.apiAppealsGet();
      setState(() {
        _appeals = appeals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载申诉记录失败: $e';
      });
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (_selectedStatus != null && _startTime != null && _endTime != null) {
        final appeals = await appealApi.apiAppealsStatusAndTimeGet(
          processStatus: _selectedStatus!,
          startTime: _startTime!.toIso8601String(),
          endTime: _endTime!.toIso8601String(),
        );
        setState(() {
          _appeals = appeals;
        });
      } else if (_selectedStatus != null) {
        final appeals = await appealApi.apiAppealsStatusProcessStatusGet(
            processStatus: _selectedStatus!);
        setState(() {
          _appeals = appeals;
        });
      } else if (_startTime != null && _endTime != null) {
        final appeals = await appealApi.apiAppealsTimeRangeGet(
          startTime: _startTime!.toIso8601String(),
          endTime: _endTime!.toIso8601String(),
        );
        setState(() {
          _appeals = appeals;
        });
      } else if (_reasonController.text.isNotEmpty) {
        final appeals = await appealApi.apiAppealsReasonReasonGet(
            reason: _reasonController.text.trim());
        setState(() {
          _appeals = appeals;
        });
      } else if (_searchController.text.isNotEmpty) {
        final appeals = await appealApi.apiAppealsNameAppellantNameGet(
            appellantName:
                _searchController.text.trim()); // Fixed parameter name
        setState(() {
          _appeals = appeals;
        });
      } else {
        await _fetchUserAppeals();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '过滤申诉失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAppeal(
      AppealManagement appeal, String idempotencyKey) async {
    try {
      await appealApi.apiAppealsPost(
          appealManagement: appeal, idempotencyKey: idempotencyKey);
      _showSnackBar('申诉提交成功！');
      await _applyFilters();
    } catch (e) {
      _showSnackBar('申诉提交失败: $e', isError: true);
    }
  }

  void _showSubmitAppealDialog() async {
    if (!_hasOffenses) {
      _showSnackBar('您当前没有违法记录，无法提交申诉', isError: true);
      return;
    }

    final user = await _fetchUserManagement();
    final driverInfo = user != null && user.userId != null
        ? await _fetchDriverInformation(user.userId!)
        : null;

    final TextEditingController nameController =
        TextEditingController(text: driverInfo?.name ?? user?.username ?? '');
    final TextEditingController idCardController =
        TextEditingController(text: driverInfo?.idCardNumber ?? '');
    final TextEditingController contactController = TextEditingController(
        text: driverInfo?.contactNumber ?? user?.contactNumber ?? '');
    final TextEditingController reasonController = TextEditingController();
    int? selectedOffenseId;

    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: themeData.colorScheme.surfaceContainer,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300.0, minHeight: 200.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '提交申诉',
                    style: themeData.textTheme.titleMedium?.copyWith(
                      color: themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: '选择违法记录',
                      labelStyle: TextStyle(
                          color: themeData.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                    ),
                    items: _userOffenses.map((offense) {
                      return DropdownMenuItem<int>(
                        value: offense['offenseId'],
                        child: Text(
                            'ID: ${offense['offenseId']} - ${offense['description'] ?? '无描述'}'),
                      );
                    }).toList(),
                    onChanged: (value) => selectedOffenseId = value,
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '申诉人姓名',
                      labelStyle: TextStyle(
                          color: themeData.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                    ),
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: idCardController,
                    decoration: InputDecoration(
                      labelText: '身份证号码',
                      labelStyle: TextStyle(
                          color: themeData.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: contactController,
                    decoration: InputDecoration(
                      labelText: '联系电话',
                      labelStyle: TextStyle(
                          color: themeData.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: '申诉原因',
                      labelStyle: TextStyle(
                          color: themeData.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                    ),
                    maxLines: 3,
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          '取消',
                          style: themeData.textTheme.labelMedium?.copyWith(
                            color: themeData.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String name = nameController.text.trim();
                          final String idCard = idCardController.text.trim();
                          final String contact = contactController.text.trim();
                          final String reason = reasonController.text.trim();

                          if (selectedOffenseId == null ||
                              name.isEmpty ||
                              idCard.isEmpty ||
                              contact.isEmpty ||
                              reason.isEmpty) {
                            _showSnackBar('请填写所有必填字段', isError: true);
                            return;
                          }
                          final RegExp idCardRegExp =
                              RegExp(r'^\d{15}|\d{18}$');
                          final RegExp contactRegExp = RegExp(r'^\d{10,15}$');

                          if (!idCardRegExp.hasMatch(idCard)) {
                            _showSnackBar('身份证号码格式不正确', isError: true);
                            return;
                          }
                          if (!contactRegExp.hasMatch(contact)) {
                            _showSnackBar('联系电话格式不正确', isError: true);
                            return;
                          }

                          final newAppeal = AppealManagement(
                            appealId: null,
                            offenseId: selectedOffenseId,
                            appellantName: name,
                            idCardNumber: idCard,
                            contactNumber: contact,
                            appealReason: reason,
                            appealTime: DateTime.now(),
                            processStatus: 'Pending',
                            processResult: '',
                          );
                          _submitAppeal(newAppeal, generateIdempotencyKey());
                          Navigator.pop(ctx);
                        },
                        style: themeData.elevatedButtonTheme.style?.copyWith(
                          backgroundColor: WidgetStateProperty.all(
                              themeData.colorScheme.primary),
                          foregroundColor: WidgetStateProperty.all(
                              themeData.colorScheme.onPrimary),
                        ),
                        child: const Text('提交'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();

    if (!_isUser) {
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        body: Center(
          child: Text(
            _errorMessage,
            style: themeData.textTheme.bodyLarge?.copyWith(
              color: themeData.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '用户申诉管理',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              color: themeData.colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: '按姓名搜索',
                              prefixIcon: Icon(Icons.search,
                                  color: themeData.colorScheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            onSubmitted: (value) => _applyFilters(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          hint: const Text('状态'),
                          value: _selectedStatus,
                          items: ['Pending', 'Approved', 'Rejected']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _reasonController,
                            decoration: InputDecoration(
                              labelText: '按原因搜索',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            onSubmitted: (value) => _applyFilters(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.date_range),
                          onPressed: () async {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (range != null) {
                              setState(() {
                                _startTime = range.start;
                                _endTime = range.end;
                              });
                              _applyFilters();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            themeData.colorScheme.primary),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            style: themeData.textTheme.bodyLarge?.copyWith(
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        )
                      : _appeals.isEmpty
                          ? Center(
                              child: Text(
                                '暂无申诉记录',
                                style: themeData.textTheme.bodyLarge?.copyWith(
                                  color: themeData.colorScheme.onSurface,
                                ),
                              ),
                            )
                          : CupertinoScrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: _appeals.length,
                                itemBuilder: (context, index) {
                                  final appeal = _appeals[index];
                                  return Card(
                                    elevation: 3,
                                    color:
                                        themeData.colorScheme.surfaceContainer,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0)),
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 6.0),
                                    child: ListTile(
                                      title: Text(
                                        '申诉人: ${appeal.appellantName ?? "未知"} (ID: ${appeal.appealId ?? "无"})',
                                        style: themeData.textTheme.bodyLarge
                                            ?.copyWith(
                                          color:
                                              themeData.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '原因: ${appeal.appealReason ?? "无"}\n状态: ${appeal.processStatus ?? "Pending"}',
                                        style: themeData.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: themeData
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                UserAppealDetailPage(
                                                    appeal: appeal),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSubmitAppealDialog,
        backgroundColor: _hasOffenses
            ? themeData.colorScheme.primary
            : themeData.colorScheme.onSurface.withOpacity(0.3),
        foregroundColor: _hasOffenses
            ? themeData.colorScheme.onPrimary
            : themeData.colorScheme.onSurface.withOpacity(0.5),
        tooltip: _hasOffenses ? '提交申诉' : '无违法记录，无法申诉',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class UserAppealDetailPage extends StatelessWidget {
  final AppealManagement appeal;

  const UserAppealDetailPage({super.key, required this.appeal});

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

  @override
  Widget build(BuildContext context) {
    final themeData =
        Get.find<UserDashboardController>().currentBodyTheme.value;

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '申诉详情',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CupertinoScrollbar(
          thumbVisibility: true,
          child: ListView(
            children: [
              _buildDetailRow(
                  '申诉ID', appeal.appealId?.toString() ?? '无', themeData),
              _buildDetailRow(
                  '违法ID', appeal.offenseId?.toString() ?? '无', themeData),
              _buildDetailRow('上诉人', appeal.appellantName ?? '无', themeData),
              _buildDetailRow('身份证号码', appeal.idCardNumber ?? '无', themeData),
              _buildDetailRow('联系电话', appeal.contactNumber ?? '无', themeData),
              _buildDetailRow('申诉原因', appeal.appealReason ?? '无', themeData),
              _buildDetailRow('申诉时间',
                  appeal.appealTime?.toIso8601String() ?? '无', themeData),
              _buildDetailRow(
                  '处理状态', appeal.processStatus ?? 'Pending', themeData),
              _buildDetailRow('处理结果', appeal.processResult ?? '无', themeData),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '注意：用户无法修改或删除申诉，请联系管理员进行操作。',
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.error,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
