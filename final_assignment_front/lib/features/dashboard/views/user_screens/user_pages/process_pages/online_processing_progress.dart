import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/progress_controller_api.dart'; // 假设后端 API 控制器
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/progress_item.dart'; // 假设进度消息模型
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OnlineProcessingProgress extends StatefulWidget {
  const OnlineProcessingProgress({super.key});

  @override
  OnlineProcessingProgressState createState() =>
      OnlineProcessingProgressState();
}

class OnlineProcessingProgressState extends State<OnlineProcessingProgress>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final ProgressControllerApi progressApi =
      ProgressControllerApi(); // 假设后端 API 控制器
  late List<Future<List<ProgressItem>>> _progressFutures;
  bool _isLoading = false;
  bool _isAdmin = false; // 假设从状态管理或 SharedPreferences 获取

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkUserRole(); // 检查用户角色并加载进度
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://your-backend-api/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        setState(() {
          _isAdmin = (roleData['roles'] as List<dynamic>).contains('ADMIN');
        });
      }
    }
    _loadProgress(); // 加载进度
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final username = prefs.getString('userName'); // 假设存储了用户名
      if (jwtToken == null || username == null) {
        throw Exception('No JWT token or username found');
      }

      final response = await http.get(
        Uri.parse('http://your-backend-api/api/progress?username=$username'),
        // 用户查看自己的进度
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final progressItems =
            data.map((json) => ProgressItem.fromJson(json)).toList();
        _progressFutures = [
          Future.value(
              progressItems.where((item) => item.status == 'Pending').toList()),
          Future.value(progressItems
              .where((item) => item.status == 'Processing')
              .toList()),
          Future.value(progressItems
              .where((item) => item.status == 'Completed')
              .toList()),
          Future.value(progressItems
              .where((item) => item.status == 'Archived')
              .toList()),
        ];
      } else {
        throw Exception('加载进度失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('加载进度失败: $e');
      _progressFutures = [
        Future.value([]),
        Future.value([]),
        Future.value([]),
        Future.value([]),
      ];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitProgress(ProgressItem newItem) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final username = prefs.getString('userName');
      if (jwtToken == null || username == null) {
        throw Exception('No JWT token or username found');
      }

      final response = await http.post(
        Uri.parse('http://your-backend-api/api/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'title': newItem.title,
          'status': 'Pending', // 初始状态为待审批
          'submitTime': newItem.submitTime,
          'details': newItem.details,
          'username': username,
        }),
      );

      if (response.statusCode == 201) {
        // 201 Created 表示成功创建
        _showSuccessSnackBar('进度提交成功，等待管理员审批');
        _loadProgress(); // 刷新列表
      } else {
        throw Exception(
            '提交失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      _showErrorSnackBar('提交进度失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  void _goToDetailPage(ProgressItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgressDetailPage(item: item),
      ),
    );
  }

  void _showSubmitProgressDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提交新进度'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '进度标题'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: '详情'),
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
              final title = titleController.text.trim();
              final details = detailsController.text.trim();
              if (title.isEmpty) {
                _showErrorSnackBar('请填写进度标题');
                return;
              }
              final newItem = ProgressItem(
                id: 0,
                // 由后端生成
                title: title,
                status: 'Pending',
                submitTime: DateTime.now().toIso8601String(),
                details: details.isEmpty ? null : details,
              );
              _submitProgress(newItem);
              Navigator.pop(ctx);
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Obx(
      () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('进度消息'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: isLight ? Colors.white : Colors.white,
            bottom: TabBar(
              controller: _tabController,
              labelColor: currentTheme.colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: currentTheme.colorScheme.primary,
              tabs: const [
                Tab(text: '受理中'),
                Tab(text: '处理中'),
                Tab(text: '已完成'),
                Tab(text: '已归档'),
              ],
            ),
            actions: [
              if (!_isAdmin) // 仅 USER 可以提交新进度
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showSubmitProgressDialog,
                  tooltip: '提交新进度',
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProgressList(
                          context, 'Pending', _progressFutures[0]),
                      _buildProgressList(
                          context, 'Processing', _progressFutures[1]),
                      _buildProgressList(
                          context, 'Completed', _progressFutures[2]),
                      _buildProgressList(
                          context, 'Archived', _progressFutures[3]),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressList(
      BuildContext context, String status, Future<List<ProgressItem>> future) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return FutureBuilder<List<ProgressItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: currentTheme.colorScheme.primary));
        } else if (snapshot.hasError) {
          return Center(
              child: Text('加载失败: ${snapshot.error}',
                  style: TextStyle(color: currentTheme.colorScheme.error)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text('暂无记录',
                  style: TextStyle(color: currentTheme.colorScheme.onSurface)));
        } else {
          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                color: isLight ? Colors.white : Colors.grey[800],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(item.status),
                    child: Text(
                      item.title[0],
                      style: TextStyle(
                        color: currentTheme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(color: currentTheme.colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    '提交时间: ${item.submitTime}',
                    style: TextStyle(
                        color: currentTheme.colorScheme.onSurface
                            .withOpacity(0.7)),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () => _goToDetailPage(item),
                ),
              );
            },
          );
        }
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class ProgressDetailPage extends StatefulWidget {
  final ProgressItem item;

  const ProgressDetailPage({super.key, required this.item});

  @override
  State<ProgressDetailPage> createState() => _ProgressDetailPageState();
}

class _ProgressDetailPageState extends State<ProgressDetailPage> {
  late ProgressControllerApi progressApi;
  bool _isLoading = false;
  bool _isAdmin = false; // 假设从状态管理或 SharedPreferences 获取
  ProgressItem? _updatedItem;
  final TextEditingController _detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    progressApi = ProgressControllerApi();
    _updatedItem = widget.item;
    _detailsController.text = _updatedItem!.details ?? '';
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      final response = await http.get(
        Uri.parse('http://your-backend-api/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final roleData = jsonDecode(response.body);
        setState(() {
          _isAdmin = (roleData['roles'] as List<dynamic>).contains('ADMIN');
        });
      }
    }
  }

  Future<void> _updateProgressStatus(String progressId, String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.put(
        Uri.parse('http://your-backend-api/api/progress/$progressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
          'details': _detailsController.text.trim().isEmpty
              ? null
              : _detailsController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _updatedItem = ProgressItem(
            id: _updatedItem!.id,
            title: _updatedItem!.title,
            status: status,
            submitTime: _updatedItem!.submitTime,
            details: _detailsController.text.trim().isEmpty
                ? null
                : _detailsController.text.trim(),
          );
          _isLoading = false;
        });
        _showSuccessSnackBar('状态更新成功！');
      } else {
        throw Exception(
            '更新失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('更新状态失败: $e');
    }
  }

  Future<void> _deleteProgress(String progressId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.delete(
        Uri.parse('http://your-backend-api/api/progress/$progressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        Navigator.pop(context); // 返回上一页
        _showSuccessSnackBar('进度删除成功！');
      } else {
        throw Exception(
            '删除失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('删除失败: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('业务详情'),
        backgroundColor: currentTheme.colorScheme.primary,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  ListTile(
                    title: Text('业务ID',
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                    subtitle: Text(_updatedItem!.id.toString(),
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                  ),
                  ListTile(
                    title: Text('业务类型',
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                    subtitle: Text(_updatedItem!.title,
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                  ),
                  ListTile(
                    title: Text('状态',
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                    subtitle: Text(_updatedItem!.status,
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                  ),
                  ListTile(
                    title: Text('提交时间',
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                    subtitle: Text(_updatedItem!.submitTime,
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                  ),
                  ListTile(
                    title: Text('详情',
                        style: TextStyle(
                            color: currentTheme.colorScheme.onSurface)),
                    subtitle: TextField(
                      controller: _detailsController,
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
                      onSubmitted: (value) => _updateProgressStatus(
                          _updatedItem!.id.toString(), _updatedItem!.status),
                    ),
                  ),
                  if (_isAdmin) // 仅 ADMIN 可以更新状态和删除
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _updatedItem!.status,
                          decoration: InputDecoration(
                            labelText: '更新状态',
                            border: const OutlineInputBorder(),
                            labelStyle: TextStyle(
                              color: isLight ? Colors.black87 : Colors.white,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    isLight ? Colors.grey : Colors.grey[500]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isLight ? Colors.blue : Colors.blueGrey,
                              ),
                            ),
                          ),
                          items: [
                            'Pending',
                            'Processing',
                            'Completed',
                            'Archived'
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              _updateProgressStatus(
                                  _updatedItem!.id.toString(), newValue);
                            }
                          },
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              _deleteProgress(_updatedItem!.id.toString()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('删除进度'),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }
}

class ProgressManagementPage extends StatefulWidget {
  const ProgressManagementPage({super.key});

  @override
  State<ProgressManagementPage> createState() => _ProgressManagementPageState();
}

class _ProgressManagementPageState extends State<ProgressManagementPage> {
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  List<ProgressItem> _progressItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllProgress();
  }

  Future<void> _fetchAllProgress() async {
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
        Uri.parse('http://your-backend-api/api/progress'), // 管理员查看所有进度
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _progressItems =
              data.map((json) => ProgressItem.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('加载进度失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载进度失败: $e';
      });
    }
  }

  Future<void> _updateProgressStatus(int progressId, String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.put(
        Uri.parse('http://your-backend-api/api/progress/$progressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _fetchAllProgress(); // 刷新列表
        _showSuccessSnackBar('状态更新成功！');
      } else {
        throw Exception(
            '更新失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      _showErrorSnackBar('更新状态失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProgress(int progressId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        throw Exception('No JWT token found');
      }

      final response = await http.delete(
        Uri.parse('http://your-backend-api/api/progress/$progressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 204) {
        _fetchAllProgress(); // 刷新列表
        _showSuccessSnackBar('进度删除成功！');
      } else {
        throw Exception(
            '删除失败: ${response.statusCode} - ${jsonDecode(response.body)['error'] ?? '未知错误'}');
      }
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  void _goToDetailPage(ProgressItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgressDetailPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final bool isLight = currentTheme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('进度管理'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: isLight ? Colors.white : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: isLight ? Colors.black : Colors.white,
                      ),
                    ),
                  )
                : _progressItems.isEmpty
                    ? Center(
                        child: Text(
                          '暂无进度记录',
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _progressItems.length,
                        itemBuilder: (context, index) {
                          final item = _progressItems[index];
                          return Card(
                            elevation: 4,
                            color: isLight ? Colors.white : Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '状态: ${item.status}\n提交时间: ${item.submitTime}',
                                style: TextStyle(
                                  color:
                                      isLight ? Colors.black54 : Colors.white70,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _goToDetailPage(item);
                                  } else if (value == 'delete') {
                                    _deleteProgress(item.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text('编辑'),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('删除'),
                                  ),
                                ],
                                icon: Icon(
                                  Icons.more_vert,
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
                              ),
                              onTap: () => _goToDetailPage(item),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
