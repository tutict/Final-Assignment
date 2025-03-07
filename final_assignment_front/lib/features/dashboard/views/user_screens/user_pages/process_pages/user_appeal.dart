import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:get/Get.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';

String generateIdempotencyKey() {
  /// 生成幂等性键的全局方法
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class UserAppealPage extends StatefulWidget {
  const UserAppealPage({super.key});

  @override
  State<UserAppealPage> createState() => _UserAppealPageState();
}

class _UserAppealPageState extends State<UserAppealPage> {
  late AppealManagementControllerApi appealApi;
  final TextEditingController _searchController = TextEditingController();
  List<AppealManagement> _appeals = [];
  bool _isLoading = true;
  bool _isUser = false;
  String _errorMessage = '';
  late ScrollController _scrollController;

  final UserDashboardController? controller =
  Get.isRegistered<UserDashboardController>()
      ? Get.find<UserDashboardController>()
      : null;

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    _scrollController = ScrollController();
    _loadAppealsAndCheckRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAppealsAndCheckRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      appealApi.apiClient.setJwtToken(jwtToken);

      final decodedJwt = _decodeJwt(jwtToken);
      final roles = decodedJwt['roles']?.toString().split(',') ?? [];
      _isUser = roles.contains('USER');
      if (!_isUser) {
        throw Exception('权限不足：仅用户可访问此页面');
      }

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

  Future<void> _searchAppealsByName(String name) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (name.isEmpty) {
        await _fetchUserAppeals();
        return;
      }
      final appeals =
      await appealApi.apiAppealsNameAppealNameGet(appealName: name);
      setState(() {
        _appeals = appeals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索申诉失败: $e';
      });
    }
  }

  Future<void> _submitAppeal(AppealManagement appeal, String idempotencyKey) async {
    try {
      await appealApi.apiAppealsPost(
          appealManagement: appeal, idempotencyKey: idempotencyKey);
      _showSnackBar('申诉提交成功！');
      await _fetchUserAppeals();
    } catch (e) {
      _showSnackBar('申诉提交失败: $e', isError: true);
    }
  }

  void _showSubmitAppealDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idCardController = TextEditingController();
    final TextEditingController contactController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    final themeData = controller?.currentBodyTheme.value ?? ThemeData.light();
    final isLight = controller?.currentTheme.value == 'Light' ?? true;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: themeData.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '申诉人姓名',
                      labelStyle:
                      TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2.0),
                      ),
                    ),
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: idCardController,
                    decoration: InputDecoration(
                      labelText: '身份证号码',
                      labelStyle:
                      TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2.0),
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
                      labelStyle:
                      TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2.0),
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
                      labelStyle:
                      TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2.0),
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

                          if (name.isEmpty || idCard.isEmpty || contact.isEmpty || reason.isEmpty) {
                            _showSnackBar('请填写所有必填字段', isError: true);
                            return;
                          }
                          final RegExp idCardRegExp = RegExp(r'^\d{15}|\d{18}$');
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
                            offenseId: null,
                            appellantName: name,
                            idCardNumber: idCard,
                            contactNumber: contact,
                            appealReason: reason,
                            appealTime: DateTime.now(),
                            processStatus: 'Pending',
                            processResult: '',
                            idempotencyKey: generateIdempotencyKey(),
                          );
                          _submitAppeal(newAppeal, newAppeal.idempotencyKey!);
                          Navigator.pop(ctx);
                        },
                        style: themeData.elevatedButtonTheme.style?.copyWith(
                          backgroundColor: WidgetStateProperty.all(themeData.colorScheme.primary),
                          foregroundColor: WidgetStateProperty.all(themeData.colorScheme.onPrimary),
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
    final isLight = controller?.currentTheme.value == 'Light' ?? true;

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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '按姓名搜索申诉',
                      prefixIcon: Icon(Icons.search, color: themeData.colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: themeData.colorScheme.outline.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2.0),
                      ),
                      labelStyle: TextStyle(color: themeData.colorScheme.onSurface),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainerLowest,
                    ),
                    onSubmitted: (value) => _searchAppealsByName(value.trim()),
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final query = _searchController.text.trim();
                    _searchAppealsByName(query);
                  },
                  style: themeData.elevatedButtonTheme.style?.copyWith(
                    backgroundColor: WidgetStateProperty.all(themeData.colorScheme.primary),
                    foregroundColor: WidgetStateProperty.all(themeData.colorScheme.onPrimary),
                  ),
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeData.colorScheme.primary),
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
                thickness: 6.0,
                thicknessWhileDragging: 10.0,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _appeals.length,
                  itemBuilder: (context, index) {
                    final appeal = _appeals[index];
                    return Card(
                      elevation: 3,
                      color: themeData.colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        title: Text(
                          '申诉人: ${appeal.appellantName ?? "未知"} (ID: ${appeal.appealId ?? "无"})',
                          style: themeData.textTheme.bodyLarge?.copyWith(
                            color: themeData.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '原因: ${appeal.appealReason ?? "无"}\n状态: ${appeal.processStatus ?? "Pending"}',
                          style: themeData.textTheme.bodyMedium?.copyWith(
                            color: themeData.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UserAppealDetailPage(appeal: appeal),
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
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        tooltip: '提交申诉',
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
    final themeData = Get.find<UserDashboardController>().currentBodyTheme.value;

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
          thickness: 6.0,
          thicknessWhileDragging: 10.0,
          child: ListView(
            children: [
              _buildDetailRow('申诉ID', appeal.appealId?.toString() ?? '无', themeData),
              _buildDetailRow('上诉人', appeal.appellantName ?? '无', themeData),
              _buildDetailRow('身份证号码', appeal.idCardNumber ?? '无', themeData),
              _buildDetailRow('联系电话', appeal.contactNumber ?? '无', themeData),
              _buildDetailRow('申诉原因', appeal.appealReason ?? '无', themeData),
              _buildDetailRow(
                  '申诉时间', appeal.appealTime?.toIso8601String() ?? '无', themeData),
              _buildDetailRow('处理状态', appeal.processStatus ?? 'Pending', themeData),
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