import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  const uuid = Uuid();
  return uuid.v4();
}

/// 用户申诉列表页面（创建、查询、搜索、实时更新）
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

  // WebSocket 频道
  WebSocketChannel? _wsChannel;

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    _loadAppealsAndCheckRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wsChannel?.sink.close();
    super.dispose();
  }

  Future<void> _loadAppealsAndCheckRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('未登录，请重新登录');
      }

      // 检查用户角色
      final roleResponse = await http.get(
        Uri.parse('http://localhost:8081/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (roleResponse.statusCode == 200) {
        final roleData = jsonDecode(roleResponse.body);
        _isUser = (roleData['roles'] as List<dynamic>).contains('USER');
        if (!_isUser) {
          throw Exception('权限不足：仅用户可访问此页面');
        }
      } else {
        throw Exception(
            '验证失败：${roleResponse.statusCode} - ${roleResponse.body}');
      }

      await _fetchUserAppeals();
      _connectWebSocket(jwtToken); // 建立 WebSocket 连接
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败: $e';
      });
    }
  }

  Future<void> _fetchUserAppeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('No JWT token found');

      // 后端根据 JWT 自动过滤当前用户的申诉
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/appeals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list =
            data.map((json) => AppealManagement.fromJson(json)).toList();
        setState(() {
          _appeals = list;
          _isLoading = false;
        });
      } else {
        throw Exception('加载用户申诉失败: ${response.statusCode} - ${response.body}');
      }
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
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('No JWT token found');

      if (name.isEmpty) {
        await _fetchUserAppeals();
        return;
      }
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/appeals/name/$name'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list =
            data.map((json) => AppealManagement.fromJson(json)).toList();
        setState(() {
          _appeals = list;
          _isLoading = false;
        });
      } else {
        throw Exception('搜索申诉失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索申诉失败: $e';
      });
    }
  }

  /// 建立 WebSocket 连接，监听服务器推送的申诉更新消息
  Future<void> _connectWebSocket(String jwtToken) async {
    // 假设后端 WebSocket 地址为 /ws/appeals
    final wsUrl = 'ws://localhost:8081/ws/appeals?token=$jwtToken';
    _wsChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
    _wsChannel?.stream.listen((message) {
      // 假设服务器发送的消息格式：{"action": "create/update/delete", "appeal": { ... }}
      final data = jsonDecode(message);
      if (data.containsKey('action') && data.containsKey('appeal')) {
        String action = data['action'];
        AppealManagement updated = AppealManagement.fromJson(data['appeal']);
        setState(() {
          if (action == 'create') {
            _appeals.add(updated);
          } else if (action == 'update') {
            int index =
                _appeals.indexWhere((a) => a.appealId == updated.appealId);
            if (index != -1) {
              _appeals[index] = updated;
            }
          } else if (action == 'delete') {
            _appeals.removeWhere((a) => a.appealId == updated.appealId);
          }
        });
      }
    }, onError: (error) {
      debugPrint("WebSocket error: $error");
    }, onDone: () {
      debugPrint("WebSocket connection closed");
    });
  }

  /// 调用 POST 创建申诉接口
  Future<void> _createAppeal(AppealManagement appeal) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('No JWT token found');

      final String idempotencyKey = generateIdempotencyKey();
      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/appeals?idempotencyKey=$idempotencyKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(appeal.toJson()),
      );
      if (response.statusCode == 201) {
        scaffoldMessenger
            .showSnackBar(const SnackBar(content: Text('创建申诉成功！')));
        _fetchUserAppeals(); // 刷新列表
      } else {
        throw Exception(
            '创建申诉失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('创建申诉失败: $e')));
    }
  }

  void _showCreateAppealDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idCardController = TextEditingController();
    final TextEditingController contactController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增申诉'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '申诉人姓名'),
              ),
              TextField(
                controller: idCardController,
                decoration: const InputDecoration(labelText: '身份证号码'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: '联系电话'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: '申诉原因'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
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
              final RegExp idCardRegExp = RegExp(r'^\d{15}|\d{18}$');
              final RegExp contactRegExp = RegExp(r'^\d{10,15}$');

              if (!idCardRegExp.hasMatch(idCard)) {
                _showSnackBar('身份证号码格式不正确');
                return;
              }
              if (!contactRegExp.hasMatch(contact)) {
                _showSnackBar('联系电话格式不正确');
                return;
              }
              final String idempotencyKey = generateIdempotencyKey();
              final AppealManagement newAppeal = AppealManagement(
                appealId: null,
                offenseId: null,
                appellantName: name,
                idCardNumber: idCard,
                contactNumber: contact,
                appealReason: reason,
                // 注意：申诉时间使用 DateTime 类型转换为 ISO 字符串
                appealTime: DateTime.now(),
                processStatus: 'Pending',
                processResult: '',
                idempotencyKey: idempotencyKey,
              );
              _createAppeal(newAppeal);
              Navigator.pop(ctx);
            },
            child: const Text('提交'),
          ),
        ],
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
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    if (!_isUser) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(color: isLight ? Colors.black : Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户申诉管理'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
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
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                          color: isLight ? Colors.black87 : Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: isLight ? Colors.grey : Colors.grey[500]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: isLight ? Colors.blue : Colors.blueGrey),
                      ),
                    ),
                    onSubmitted: (value) => _searchAppealsByName(value.trim()),
                    style:
                        TextStyle(color: isLight ? Colors.black : Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final query = _searchController.text.trim();
                    _searchAppealsByName(query);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage,
                    style:
                        TextStyle(color: isLight ? Colors.black : Colors.white),
                  ),
                ),
              )
            else
              Expanded(
                child: _appeals.isEmpty
                    ? Center(
                        child: Text(
                          '暂无申诉记录',
                          style: TextStyle(
                              color: isLight ? Colors.black : Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _appeals.length,
                        itemBuilder: (context, index) {
                          final appeal = _appeals[index];
                          return Card(
                            elevation: 4,
                            color: isLight ? Colors.white : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              title: Text(
                                '申诉人: ${appeal.appellantName ?? ""} (ID: ${appeal.appealId})',
                                style: TextStyle(
                                    color: isLight
                                        ? Colors.black87
                                        : Colors.white),
                              ),
                              subtitle: Text(
                                '原因: ${appeal.appealReason ?? ""}\n状态: ${appeal.processStatus ?? "Pending"}',
                                style: TextStyle(
                                    color: isLight
                                        ? Colors.black54
                                        : Colors.white70),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAppealDialog,
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        tooltip: '新增申诉',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 用户申诉详情页面（用于编辑和删除自己的申诉）
class UserAppealDetailPage extends StatefulWidget {
  final AppealManagement appeal;

  const UserAppealDetailPage({super.key, required this.appeal});

  @override
  State<UserAppealDetailPage> createState() => _UserAppealDetailPageState();
}

class _UserAppealDetailPageState extends State<UserAppealDetailPage> {
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _processResultController =
      TextEditingController();
  late AppealManagementControllerApi appealApi;

  @override
  void initState() {
    super.initState();
    appealApi = AppealManagementControllerApi();
    // 将原申诉原因加载到文本编辑器，便于修改
    _reasonController.text = widget.appeal.appealReason ?? '';
    _processResultController.text = widget.appeal.processResult ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _processResultController.dispose();
    super.dispose();
  }

  /// 更新申诉（用户仅允许修改自己的申诉内容，若状态为 Pending）
  Future<void> _updateAppeal() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
    });
    try {
      // 构造更新后的对象，更新申诉原因
      AppealManagement updatedAppeal = AppealManagement(
        appealId: widget.appeal.appealId,
        offenseId: widget.appeal.offenseId,
        appellantName: widget.appeal.appellantName,
        idCardNumber: widget.appeal.idCardNumber,
        contactNumber: widget.appeal.contactNumber,
        appealReason: _reasonController.text.trim(),
        appealTime: widget.appeal.appealTime,
        // 保持原时间
        processStatus: widget.appeal.processStatus,
        // 用户只能修改内容
        processResult: widget.appeal.processResult,
        idempotencyKey: generateIdempotencyKey(),
      );
      await appealApi.apiAppealsAppealIdPut(
          appealId: widget.appeal.appealId.toString(),
          appealManagement: updatedAppeal);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('申诉更新成功')));
      Navigator.pop(context, true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              Text('申诉更新失败: $e', style: const TextStyle(color: Colors.red))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 删除申诉
  Future<void> _deleteAppeal() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await appealApi.apiAppealsAppealIdDelete(
          appealId: widget.appeal.appealId.toString());
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('申诉已删除')));
      Navigator.pop(context, true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              Text('删除失败: $e', style: const TextStyle(color: Colors.red))));
    }
  }

  Widget _buildDetailRow(String label, String value) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLight ? Colors.black87 : Colors.white)),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: isLight ? Colors.black54 : Colors.white70))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('申诉详情'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildDetailRow(
                      '申诉ID', widget.appeal.appealId?.toString() ?? '无'),
                  _buildDetailRow('上诉人', widget.appeal.appellantName ?? '无'),
                  _buildDetailRow('身份证号码', widget.appeal.idCardNumber ?? '无'),
                  _buildDetailRow('联系电话', widget.appeal.contactNumber ?? '无'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: '申诉原因',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _updateAppeal,
                        child: const Text('更新申诉'),
                      ),
                      ElevatedButton(
                        onPressed: _deleteAppeal,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('删除申诉'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
