import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerPersonalPage extends StatefulWidget {
  const ManagerPersonalPage({super.key});

  @override
  State<ManagerPersonalPage> createState() => _ManagerPersonalPageState();
}

class _ManagerPersonalPageState extends State<ManagerPersonalPage> {
  // 用于与后端交互的 API
  late UserManagementControllerApi userApi;

  // Future 用于异步加载管理员信息
  late Future<UserManagement?> _managerFuture;

  // 获取 UserDashboardController 以支持动态主题
  final UserDashboardController? controller =
      Get.isRegistered<UserDashboardController>()
          ? Get.find<UserDashboardController>()
          : null;

  @override
  void initState() {
    super.initState();
    userApi = UserManagementControllerApi();
    // 示例使用 userId=1，实际项目中应替换为当前用户ID
    _managerFuture = _fetchManagerInfo("1");
  }

  /// 获取管理员信息 (示例使用 userId=1)
  Future<UserManagement?> _fetchManagerInfo(String userId) async {
    try {
      final result = await userApi.apiUsersUserIdGet(userId: userId);
      if (result is Map<String, dynamic>) {
        return UserManagement.fromJson(result);
      }
      return null;
    } catch (e) {
      throw Exception('获取管理员信息失败: $e');
    }
  }

  /// 示例退出登录逻辑，与 SettingPage.dart 一致
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    if (Get.isRegistered<ChatController>()) {
      final chatController = Get.find<ChatController>();
      chatController.clearMessages();
    }
    Get.offAllNamed(AppPages.login);
  }

  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    inherit: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理员个人页面'),
      ),
      body: controller != null
          ? Obx(
              () => Theme(
                data: controller!.currentBodyTheme.value,
                child: _buildBody(context),
              ),
            )
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<UserManagement?>(
        future: _managerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('未找到管理员信息'));
          } else {
            final manager = snapshot.data!;
            return ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(
                    '姓名',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    manager.name ?? '无',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: Text(
                    '邮箱',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    manager.email ?? '无',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.blue),
                  title: Text(
                    '联系电话',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    manager.contactNumber ?? '无',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 20.0),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // 处理修改个人信息的逻辑（未实现）
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('修改个人信息功能待实现')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('修改个人信息', style: _buttonTextStyle),
                  ),
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('登出'),
                            content: const Text('确定要登出吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _logout();
                                  Navigator.pop(context);
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('退出登录', style: _buttonTextStyle),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
