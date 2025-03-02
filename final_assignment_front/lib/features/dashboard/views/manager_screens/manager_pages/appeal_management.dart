import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  const uuid = Uuid();
  return uuid.v4();
}

/// 管理员端申诉管理页面
class AppealManagementAdmin extends StatefulWidget {
  const AppealManagementAdmin({super.key});

  @override
  State<AppealManagementAdmin> createState() => _AppealManagementAdminState();
}

class _AppealManagementAdminState extends State<AppealManagementAdmin> {
  late AppealManagementControllerApi appealApi;
  late Future<List<AppealManagement>> _appealsFuture;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  bool _isLoading = true;
  bool _isAdmin = false; // 确保是管理员
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    _checkUserRole(); // 检查用户角色并加载申诉
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
      Uri.parse('http://localhost:8081/api/auth/me'), // 后端地址
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
        if (_isAdmin) {
          _loadAppeals(); // 仅管理员加载所有申诉
        } else {
          _errorMessage = '权限不足：仅管理员可访问此页面';
          _isLoading = false;
        }
      });
    } else {
      setState(() {
        _errorMessage = '验证失败：${response.statusCode} - ${response.body}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAppeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8081/api/appeals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final appeals =
            data.map((json) => AppealManagement.fromJson(json)).toList();
        setState(() {
          _appealsFuture = Future.value(appeals);
          _isLoading = false;
        });
      } else {
        throw Exception('加载申诉信息失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载申诉信息失败: $e';
      });
    }
  }

  Future<void> _fetchAppealsByStatus(String status) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      Uri uri;
      if (status == '全部') {
        uri = Uri.parse('http://localhost:8081/api/appeals');
      } else {
        uri = Uri.parse('http://localhost:8081/api/appeals/status/$status');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final appeals =
            data.map((json) => AppealManagement.fromJson(json)).toList();
        setState(() {
          _appealsFuture = Future.value(appeals);
          _isLoading = false;
        });
      } else {
        throw Exception('获取申诉记录失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '获取申诉记录失败: $e';
      });
    }
  }

  Future<void> _updateAppealStatus(
      int appealId, String newStatus, String? processResult) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/appeals/$appealId?idempotencyKey=$idempotencyKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'processStatus': newStatus,
          'processResult': processResult ?? '', // 使用 processResult 作为处理结果
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('申诉状态已更新为: $newStatus')),
        );
        _loadAppeals(); // 刷新列表
      } else {
        throw Exception('更新状态失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('更新状态失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAppeal(int appealId) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final response = await http.delete(
        Uri.parse('http://localhost:8081/api/appeals/$appealId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
        _loadAppeals(); // 刷新列表
      } else {
        throw Exception('删除失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('删除失败: $e', style: const TextStyle(color: Colors.red))),
      );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goToDetailPage(AppealManagement appeal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppealDetailAdminPage(appeal: appeal),
      ),
    ).then((value) {
      if (value == true && mounted) {
        _loadAppeals(); // 详情页更新后刷新列表
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('管理员端申诉管理'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  _fetchAppealsByStatus(value);
                },
                itemBuilder: (context) {
                  return ['全部', 'Pending', 'Processed', 'Rejected']
                      .map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(
                        choice,
                        style: TextStyle(
                          color: isLight ? Colors.black87 : Colors.white,
                        ),
                      ),
                    );
                  }).toList();
                },
                icon: Icon(
                  Icons.filter_list,
                  color: isLight ? Colors.white : Colors.white,
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : FutureBuilder<List<AppealManagement>>(
                        future: _appealsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '加载失败: ${snapshot.error}',
                                style: TextStyle(
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                            );
                          }
                          final data = snapshot.data;
                          if (data == null || data.isEmpty) {
                            return Center(
                              child: Text(
                                '暂无申诉记录',
                                style: TextStyle(
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: () async {
                              _loadAppeals();
                            },
                            child: ListView.builder(
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final appeal = data[index];
                                final aid = appeal.appealId ?? 0;
                                final status =
                                    appeal.processStatus ?? 'Pending';

                                return Card(
                                  margin: const EdgeInsets.all(8.0),
                                  elevation: 4,
                                  color:
                                      isLight ? Colors.white : Colors.grey[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      '申诉人: ${appeal.appellantName ?? ""}',
                                      style: TextStyle(
                                        color: isLight
                                            ? Colors.black87
                                            : Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '原因: ${appeal.appealReason ?? ""}\n状态: $status',
                                      style: TextStyle(
                                        color: isLight
                                            ? Colors.black54
                                            : Colors.white70,
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (choice) {
                                        if (choice == '批准' &&
                                            status == 'Pending') {
                                          _updateAppealStatus(
                                              aid, 'Processed', null);
                                        } else if (choice == '拒绝' &&
                                            status == 'Pending') {
                                          _updateAppealStatus(
                                              aid, 'Rejected', null);
                                        } else if (choice == '删除') {
                                          _deleteAppeal(aid);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
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
                                        color: isLight
                                            ? Colors.black87
                                            : Colors.white,
                                      ),
                                    ),
                                    onTap: () => _goToDetailPage(appeal),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}

/// 申诉详情页面（管理员端）
class AppealDetailAdminPage extends StatefulWidget {
  final AppealManagement appeal;

  const AppealDetailAdminPage({super.key, required this.appeal});

  @override
  State<AppealDetailAdminPage> createState() => _AppealDetailAdminPageState();
}

class _AppealDetailAdminPageState extends State<AppealDetailAdminPage> {
  bool _isLoading = false;
  bool _isAdmin = false; // 管理员权限标识
  String _errorMessage = ''; // 错误消息
  final TextEditingController _processResultController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _processResultController.text = widget.appeal.processResult ?? '';
    _checkUserRole(); // 检查用户角色
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
      Uri.parse('http://localhost:8081/api/auth/me'), // 后端地址
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

  Future<void> _updateAppealStatus(
      int appealId, String newStatus, String? processResult) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null || !_isAdmin) {
        throw Exception('No JWT token found or insufficient permissions');
      }

      final String idempotencyKey = generateIdempotencyKey();
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/appeals/$appealId?idempotencyKey=$idempotencyKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'processStatus': newStatus,
          'processResult': processResult ??
              _processResultController.text.trim(), // 使用 processResult 作为处理结果
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('申诉状态已更新为: $newStatus')),
        );
        setState(() {
          widget.appeal.processStatus = newStatus;
          widget.appeal.processResult = _processResultController.text.trim();
        });
        if (mounted) {
          Navigator.pop(context, true); // 返回并刷新列表
        }
      } else {
        throw Exception('更新状态失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('更新状态失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAppeal(int appealId) async {
    if (!mounted) return; // 确保 widget 仍然挂载

    final scaffoldMessenger = ScaffoldMessenger.of(context); // 保存 context
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
        Uri.parse('http://localhost:8081/api/appeals/$appealId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        // 204 No Content
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
        if (mounted) {
          Navigator.pop(context, true); // 返回并刷新列表
        }
      } else {
        throw Exception('删除失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text('删除失败: $e', style: const TextStyle(color: Colors.red))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // 确保 widget 仍然挂载
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        body: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('申诉详情'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
        actions: [
          if (_isAdmin) // 仅 ADMIN 显示操作按钮
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == '批准' && status == 'Pending') {
                  _updateAppealStatus(
                      widget.appeal.appealId ?? 0, 'Processed', null);
                } else if (value == '拒绝' && status == 'Pending') {
                  _updateAppealStatus(
                      widget.appeal.appealId ?? 0, 'Rejected', null);
                } else if (value == '删除') {
                  _deleteAppeal(widget.appeal.appealId ?? 0);
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
                      context, '原因', widget.appeal.appealReason ?? '无'),
                  _buildDetailRow(
                      context, '时间', widget.appeal.appealTime ?? '无'),
                  _buildDetailRow(context, '状态', status),
                  _buildDetailRow(context, '处理结果',
                      widget.appeal.processResult ?? '无'), // 使用 processResult
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
                      onSubmitted: (value) => _updateAppealStatus(
                          widget.appeal.appealId ?? 0, status, value.trim()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
