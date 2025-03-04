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
  bool _isAdmin = false; // 管理员权限标识
  String _errorMessage = '';
  final TextEditingController _processResultController =
      TextEditingController();
  late AppealManagementControllerApi appealApi;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    appealApi = AppealManagementControllerApi();
    // 初始化处理结果输入框
    _processResultController.text = widget.appeal.processResult ?? '';
    _checkUserRole(); // 检查管理员角色
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      setState(() {
        _errorMessage = '未登录，请重新登录';
        _isLoading = false;
      });
      return;
    }
    final response = await http.get(
      Uri.parse('http://localhost:8081/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );
    if (response.statusCode == 200) {
      final roleData = jsonDecode(response.body);
      final userRole = (roleData['roles'] as List<dynamic>).firstWhere(
        (role) => role == 'ADMIN',
        orElse: () => 'USER',
      );
      setState(() {
        _isAdmin = userRole == 'ADMIN';
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
        _isLoading = false;
      });
    }
  }

  /// 更新申诉状态，直接使用 widget.appeal 内的信息
  Future<void> _updateAppealStatus(
      String newStatus, String? processResult) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
    });
    try {
      // 构造更新后的对象，注意 appealTime 为 DateTime 类型
      AppealManagement updatedAppeal = AppealManagement(
        appealId: widget.appeal.appealId,
        offenseId: widget.appeal.offenseId,
        appellantName: widget.appeal.appellantName,
        idCardNumber: widget.appeal.idCardNumber,
        contactNumber: widget.appeal.contactNumber,
        appealReason: widget.appeal.appealReason,
        appealTime: widget.appeal.appealTime,
        // 此处保持原时间
        processStatus: newStatus,
        processResult: processResult ?? _processResultController.text.trim(),
        idempotencyKey: generateIdempotencyKey(),
      );
      // 调用 API 更新接口，传入字符串形式的 appealId
      await appealApi.apiAppealsAppealIdPut(
          appealId: widget.appeal.appealId.toString(),
          appealManagement: updatedAppeal);
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('申诉状态已更新为: $newStatus')));
      setState(() {
        widget.appeal.processStatus = newStatus;
        widget.appeal.processResult =
            processResult ?? _processResultController.text.trim();
      });
      Navigator.pop(context, true); // 返回并刷新列表
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              Text('更新状态失败: $e', style: const TextStyle(color: Colors.red))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAppeal() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }
      setState(() {
        _isLoading = true;
      });
      final response = await http.delete(
        Uri.parse(
            'http://localhost:8081/api/appeals/${widget.appeal.appealId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 204) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('删除成功')));
        Navigator.pop(context, true);
      } else {
        throw Exception('删除失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              Text('删除失败: $e', style: const TextStyle(color: Colors.red))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('申诉详情'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
        actions: [
          if (_isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == '批准' && status == 'Pending') {
                  _updateAppealStatus('Processed', null);
                } else if (value == '拒绝' && status == 'Pending') {
                  _updateAppealStatus('Rejected', null);
                } else if (value == '删除') {
                  _deleteAppeal();
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
              icon: Icon(
                Icons.more_vert,
                color: isLight ? Colors.black87 : Colors.white,
              ),
            ),
        ],
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
                  ListTile(
                    title: Text('处理结果',
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                    subtitle: TextField(
                      controller: _processResultController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          color: isLight ? Colors.black87 : Colors.white,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isLight ? Colors.grey : Colors.grey[500]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isLight ? Colors.blue : Colors.blueGrey,
                          ),
                        ),
                      ),
                      maxLines: 3,
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                      ),
                      onSubmitted: (value) =>
                          _updateAppealStatus(status, value.trim()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
