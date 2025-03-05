import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:get/Get.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';

String generateIdempotencyKey() {
  const uuid = Uuid();
  return uuid.v4();
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

  Future<void> _submitAppeal(
      AppealManagement appeal, String idempotencyKey) async {
    try {
      await appealApi.apiAppealsPost(
          appealManagement: appeal, idempotencyKey: idempotencyKey);
      _showSnackBar('申诉提交成功！');
      await _fetchUserAppeals(); // 刷新列表
    } catch (e) {
      _showSnackBar('申诉提交失败: $e');
    }
  }

  void _showSubmitAppealDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idCardController = TextEditingController();
    final TextEditingController contactController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    final UserDashboardController dashboardController =
        Get.find<UserDashboardController>();
    final themeData = dashboardController.currentBodyTheme.value;
    final isLight = dashboardController.currentTheme.value == 'Light';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isLight
            ? themeData.colorScheme.surfaceContainer
            : themeData.colorScheme.surfaceContainerHigh,
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
                      color: isLight
                          ? themeData.colorScheme.onSurface
                          : themeData.colorScheme.onSurface.withOpacity(0.95),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '申诉人姓名',
                      labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                        color: isLight
                            ? themeData.colorScheme.onSurfaceVariant
                            : themeData.colorScheme.onSurfaceVariant
                                .withOpacity(0.85),
                      ),
                      filled: true,
                      fillColor: isLight
                          ? themeData.colorScheme.surfaceContainerLowest
                          : themeData.colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color: themeData.colorScheme.primary, width: 2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: idCardController,
                    decoration: InputDecoration(
                      labelText: '身份证号码',
                      labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                        color: isLight
                            ? themeData.colorScheme.onSurfaceVariant
                            : themeData.colorScheme.onSurfaceVariant
                                .withOpacity(0.85),
                      ),
                      filled: true,
                      fillColor: isLight
                          ? themeData.colorScheme.surfaceContainerLowest
                          : themeData.colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color: themeData.colorScheme.primary, width: 2.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: contactController,
                    decoration: InputDecoration(
                      labelText: '联系电话',
                      labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                        color: isLight
                            ? themeData.colorScheme.onSurfaceVariant
                            : themeData.colorScheme.onSurfaceVariant
                                .withOpacity(0.85),
                      ),
                      filled: true,
                      fillColor: isLight
                          ? themeData.colorScheme.surfaceContainerLowest
                          : themeData.colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color: themeData.colorScheme.primary, width: 2.0),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: '申诉原因',
                      labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                        color: isLight
                            ? themeData.colorScheme.onSurfaceVariant
                            : themeData.colorScheme.onSurfaceVariant
                                .withOpacity(0.85),
                      ),
                      filled: true,
                      fillColor: isLight
                          ? themeData.colorScheme.surfaceContainerLowest
                          : themeData.colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color: themeData.colorScheme.primary, width: 2.0),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: themeData.colorScheme.onSurface,
                        ),
                        child: Text(
                          '取消',
                          style: themeData.textTheme.labelMedium?.copyWith(
                            color: themeData.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String name = nameController.text.trim();
                          final String idCard = idCardController.text.trim();
                          final String contact = contactController.text.trim();
                          final String reason = reasonController.text.trim();

                          if (name.isEmpty ||
                              idCard.isEmpty ||
                              contact.isEmpty ||
                              reason.isEmpty) {
                            _showSnackBar('请填写所有必填字段');
                            return;
                          }
                          final RegExp idCardRegExp =
                              RegExp(r'^\d{15}|\d{18}$');
                          final RegExp contactRegExp = RegExp(r'^\d{10,15}$');

                          if (!idCardRegExp.hasMatch(idCard)) {
                            _showSnackBar('身份证号码格式不正确');
                            return;
                          }
                          if (!contactRegExp.hasMatch(contact)) {
                            _showSnackBar('联系电话格式不正确');
                            return;
                          }

                          final newAppeal = AppealManagement(
                            appealId: null,
                            // 由后端生成
                            offenseId: null,
                            // 可选字段
                            appellantName: name,
                            idCardNumber: idCard,
                            contactNumber: contact,
                            appealReason: reason,
                            appealTime: DateTime.now(),
                            // 前端设置，后端可能覆盖
                            processStatus: 'Pending',
                            // 默认值
                            processResult: '',
                            // 默认值
                            idempotencyKey: generateIdempotencyKey(), // 必须提供
                          );
                          _submitAppeal(newAppeal, newAppeal.idempotencyKey!);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10.0),
                        ),
                        child: Text(
                          '提交',
                          style: themeData.textTheme.labelMedium?.copyWith(
                            color: themeData.colorScheme.onPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final UserDashboardController dashboardController =
        Get.find<UserDashboardController>();
    final isLight = dashboardController.currentTheme.value == 'Light';
    final themeData = dashboardController.currentBodyTheme.value;

    if (!_isUser) {
      return Scaffold(
        backgroundColor: isLight
            ? themeData.colorScheme.surface.withOpacity(0.95)
            : themeData.colorScheme.surface.withOpacity(0.85),
        body: Center(
          child: Text(
            _errorMessage,
            style: themeData.textTheme.bodyLarge?.copyWith(
              color: isLight
                  ? themeData.colorScheme.onSurface
                  : themeData.colorScheme.onSurface.withOpacity(0.9),
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isLight
          ? themeData.colorScheme.surface.withOpacity(0.95)
          : themeData.colorScheme.surface.withOpacity(0.85),
      appBar: AppBar(
        title: Text(
          '用户申诉管理',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: isLight
                ? themeData.colorScheme.onSurface
                : themeData.colorScheme.onSurface.withOpacity(0.95),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isLight
            ? themeData.colorScheme.surfaceContainer.withOpacity(0.9)
            : themeData.colorScheme.surfaceContainer.withOpacity(0.7),
        elevation: 2,
        shadowColor: themeData.colorScheme.shadow.withOpacity(0.2),
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
                      prefixIcon: Icon(Icons.search,
                          color: themeData.colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            BorderSide(color: themeData.colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                            color:
                                themeData.colorScheme.outline.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                            color: themeData.colorScheme.primary, width: 2.0),
                      ),
                      labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                        color: isLight
                            ? themeData.colorScheme.onSurface
                            : themeData.colorScheme.onSurface.withOpacity(0.9),
                      ),
                      filled: true,
                      fillColor: isLight
                          ? themeData.colorScheme.surfaceContainerLowest
                          : themeData.colorScheme.surfaceContainerLow,
                    ),
                    onSubmitted: (value) => _searchAppealsByName(value.trim()),
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: isLight
                          ? themeData.colorScheme.onSurface
                          : themeData.colorScheme.onSurface.withOpacity(0.95),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final query = _searchController.text.trim();
                    _searchAppealsByName(query);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeData.colorScheme.primary,
                    foregroundColor: themeData.colorScheme.onPrimary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                  ),
                  child: Text(
                    '搜索',
                    style: themeData.textTheme.labelLarge?.copyWith(
                      color: themeData.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
                              color: isLight
                                  ? themeData.colorScheme.onSurface
                                  : themeData.colorScheme.onSurface
                                      .withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                        )
                      : _appeals.isEmpty
                          ? Center(
                              child: Text(
                                '暂无申诉记录',
                                style: themeData.textTheme.bodyLarge?.copyWith(
                                  color: isLight
                                      ? themeData.colorScheme.onSurface
                                      : themeData.colorScheme.onSurface
                                          .withOpacity(0.9),
                                  fontSize: 18,
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
                                    shadowColor: themeData.colorScheme.shadow
                                        .withOpacity(0.2),
                                    color: isLight
                                        ? themeData
                                            .colorScheme.surfaceContainerLow
                                        : themeData
                                            .colorScheme.surfaceContainerHigh,
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
                                          color: isLight
                                              ? themeData.colorScheme.onSurface
                                              : themeData.colorScheme.onSurface
                                                  .withOpacity(0.95),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '原因: ${appeal.appealReason ?? "无"}\n状态: ${appeal.processStatus ?? "Pending"}',
                                        style: themeData.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: isLight
                                              ? themeData
                                                  .colorScheme.onSurfaceVariant
                                              : themeData
                                                  .colorScheme.onSurfaceVariant
                                                  .withOpacity(0.85),
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

  Widget _buildDetailRow(
      String label, String value, ThemeData themeData, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isLight
                  ? themeData.colorScheme.onSurface
                  : themeData.colorScheme.onSurface.withOpacity(0.95),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: isLight
                    ? themeData.colorScheme.onSurfaceVariant
                    : themeData.colorScheme.onSurfaceVariant.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserDashboardController dashboardController =
        Get.find<UserDashboardController>();
    final isLight = dashboardController.currentTheme.value == 'Light';
    final themeData = dashboardController.currentBodyTheme.value;

    return Scaffold(
      backgroundColor: isLight
          ? themeData.colorScheme.surface.withOpacity(0.95)
          : themeData.colorScheme.surface.withOpacity(0.85),
      appBar: AppBar(
        title: Text(
          '申诉详情',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: isLight
                ? themeData.colorScheme.onSurface
                : themeData.colorScheme.onSurface.withOpacity(0.95),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isLight
            ? themeData.colorScheme.surfaceContainer.withOpacity(0.9)
            : themeData.colorScheme.surfaceContainer.withOpacity(0.7),
        elevation: 2,
        shadowColor: themeData.colorScheme.shadow.withOpacity(0.2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CupertinoScrollbar(
          thumbVisibility: true,
          thickness: 6.0,
          thicknessWhileDragging: 10.0,
          child: ListView(
            children: [
              _buildDetailRow('申诉ID', appeal.appealId?.toString() ?? '无',
                  themeData, isLight),
              _buildDetailRow(
                  '上诉人', appeal.appellantName ?? '无', themeData, isLight),
              _buildDetailRow(
                  '身份证号码', appeal.idCardNumber ?? '无', themeData, isLight),
              _buildDetailRow(
                  '联系电话', appeal.contactNumber ?? '无', themeData, isLight),
              _buildDetailRow(
                  '申诉原因', appeal.appealReason ?? '无', themeData, isLight),
              _buildDetailRow(
                  '申诉时间',
                  appeal.appealTime?.toIso8601String() ?? '无',
                  themeData,
                  isLight),
              _buildDetailRow('处理状态', appeal.processStatus ?? 'Pending',
                  themeData, isLight),
              _buildDetailRow(
                  '处理结果', appeal.processResult ?? '无', themeData, isLight),
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
