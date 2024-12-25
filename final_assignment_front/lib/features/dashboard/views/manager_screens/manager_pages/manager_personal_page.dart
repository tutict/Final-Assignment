import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/model/user_management.dart';

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

  @override
  void initState() {
    super.initState();
    userApi = UserManagementControllerApi();

    // 假设: 我们要获取 userId=1 的管理员信息，仅作演示
    // 如果你有当前用户ID，可以在实际项目中使用真正的 userId 或 username
    _managerFuture = _fetchManagerInfo("1");
  }

  /// 获取管理员信息 (这里示例用 userId=1)
  Future<UserManagement?> _fetchManagerInfo(String userId) async {
    try {
      final result = await userApi.apiUsersUserIdGet(userId: userId);
      // 返回类型是 `Object?`，通常是一个Map或null
      if (result is Map<String, dynamic>) {
        return UserManagement.fromJson(result);
      }
      return null;
    } catch (e) {
      throw Exception('获取管理员信息失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理员个人页面'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<UserManagement?>(
        future: _managerFuture,
        builder: (context, snapshot) {
          // 加载中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 出错
          else if (snapshot.hasError) {
            return Center(
              child: Text('加载管理员信息时发生错误: ${snapshot.error}'),
            );
          }
          // 数据为空
          else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('未找到管理员信息'),
            );
          }
          // 加载成功
          else {
            final manager = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '管理员信息',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 展示信息: name, email, contactNumber 等
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('姓名'),
                    subtitle: Text(manager.name ?? '无'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('邮箱'),
                    subtitle: Text(manager.email ?? '无'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('联系电话'),
                    subtitle: Text(manager.contactNumber ?? '无'),
                  ),

                  // 其他字段: userType, status, ...
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // 处理修改个人信息的逻辑
                      // 可调用 userApi.apiUsersUserIdPut(...) 等方法更新
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('修改个人信息'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // 处理退出登录的逻辑
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text('退出登录'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
