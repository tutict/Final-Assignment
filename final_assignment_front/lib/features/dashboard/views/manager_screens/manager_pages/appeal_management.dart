import 'dart:convert';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  const uuid = Uuid();
  return uuid.v4();
}

/// 管理员端申诉详情页面
class AppealManagementAdmin extends StatefulWidget {
  final AppealManagement appeal;

  const AppealManagementAdmin({super.key, required this.appeal});

  @override
  State<AppealManagementAdmin> createState() => _AppealManagementPageState();
}

class _AppealManagementPageState extends State<AppealManagementAdmin> {
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  final TextEditingController _processResultController =
      TextEditingController();
  late AppealManagementControllerApi appealApi;

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    _processResultController.text = widget.appeal.processResult ?? '';
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }
      appealApi.apiClient.setJwtToken(jwtToken); // 设置 JWT 到 ApiClient

      final response = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        final roles = (roleData['roles'] as List<dynamic>);
        _isAdmin = roles.contains('ADMIN');
        if (!_isAdmin) {
          throw Exception('权限不足：仅管理员可访问此页面');
        }
      } else {
        throw Exception('验证失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 更新申诉状态
  Future<void> _updateAppealStatus(
      String newStatus, String? processResult) async {
    if (!mounted || !_isAdmin) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      final updatedAppeal = AppealManagement(
        appealId: widget.appeal.appealId,
        offenseId: widget.appeal.offenseId,
        appellantName: widget.appeal.appellantName,
        idCardNumber: widget.appeal.idCardNumber,
        contactNumber: widget.appeal.contactNumber,
        appealReason: widget.appeal.appealReason,
        appealTime: widget.appeal.appealTime,
        processStatus: newStatus,
        processResult: processResult ?? _processResultController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
      );

      await appealApi.apiAppealsAppealIdPut(
        appealId: widget.appeal.appealId.toString(),
        appealManagement: updatedAppeal,
        idempotencyKey: updatedAppeal.idempotencyKey!,
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('申诉状态已更新为: $newStatus')),
      );

      setState(() {
        widget.appeal.processStatus = newStatus;
        widget.appeal.processResult = updatedAppeal.processResult;
      });

      Navigator.pop(context, true); // 返回并刷新列表
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('更新状态失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 删除申诉
  Future<void> _deleteAppeal() async {
    if (!mounted || !_isAdmin) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      await appealApi.apiAppealsAppealIdDelete(
          appealId: widget.appeal.appealId.toString());
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('删除成功')));
      Navigator.pop(context, true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('删除失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLight ? Colors.black87 : Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;
    final status = widget.appeal.processStatus ?? 'Pending';

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('申诉详情'),
          backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(_errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('申诉详情'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: _isAdmin && !_isLoading
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == '批准' && status == 'Pending') {
                      await _updateAppealStatus('Processed', '申诉已通过');
                    } else if (value == '拒绝' && status == 'Pending') {
                      if (_processResultController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请填写拒绝理由')),
                        );
                        return;
                      }
                      await _updateAppealStatus(
                          'Rejected', _processResultController.text.trim());
                    } else if (value == '删除') {
                      await _deleteAppeal();
                    }
                  },
                  itemBuilder: (context) => [
                    if (status == 'Pending')
                      const PopupMenuItem<String>(
                        value: '批准',
                        child: Text('批准'),
                      ),
                    if (status == 'Pending')
                      const PopupMenuItem<String>(
                        value: '拒绝',
                        child: Text('拒绝'),
                      ),
                    const PopupMenuItem<String>(
                      value: '删除',
                      child: Text('删除'),
                    ),
                  ],
                  icon: Icon(Icons.more_vert, color: Colors.white),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildDetailRow(context, '申诉 ID',
                      widget.appeal.appealId?.toString() ?? '无'),
                  _buildDetailRow(
                      context, '上诉人', widget.appeal.appellantName ?? '无'),
                  _buildDetailRow(
                      context, '身份证号码', widget.appeal.idCardNumber ?? '无'),
                  _buildDetailRow(
                      context, '联系电话', widget.appeal.contactNumber ?? '无'),
                  _buildDetailRow(
                      context, '申诉原因', widget.appeal.appealReason ?? '无'),
                  _buildDetailRow(
                    context,
                    '提交时间',
                    widget.appeal.appealTime != null
                        ? widget.appeal.appealTime!.toLocal().toString()
                        : '无',
                  ),
                  _buildDetailRow(context, '状态', status),
                  _buildDetailRow(
                      context, '处理结果', widget.appeal.processResult ?? '无'),
                  if (_isAdmin && status == 'Pending')
                    ListTile(
                      title: Text(
                        '处理结果',
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface),
                      ),
                      subtitle: TextField(
                        controller: _processResultController,
                        decoration: InputDecoration(
                          hintText: '请输入处理结果（如拒绝理由）',
                          border: const OutlineInputBorder(),
                          labelStyle: TextStyle(
                              color: isLight ? Colors.black87 : Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    isLight ? Colors.grey : Colors.grey[500]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: isLight ? Colors.blue : Colors.blueGrey),
                          ),
                        ),
                        maxLines: 3,
                        style: TextStyle(
                            color: isLight ? Colors.black : Colors.white),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
