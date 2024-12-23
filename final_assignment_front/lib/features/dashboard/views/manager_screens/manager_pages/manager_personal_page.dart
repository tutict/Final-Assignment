import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManagerPersonalPage extends StatefulWidget {
  const ManagerPersonalPage({super.key});

  @override
  State<ManagerPersonalPage> createState() => _ManagerPersonalPageState();
}

class _ManagerPersonalPageState extends State<ManagerPersonalPage> {
  late Future<Manager> _managerFuture;

  @override
  void initState() {
    super.initState();
    _managerFuture = _fetchManagerInfo();
  }

  Future<Manager> _fetchManagerInfo() async {
    final url = Uri.parse('${AppConfig.baseUrl}/eventbus/manager/info');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return Manager.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load manager info');
      }
    } catch (e) {
      throw Exception('Failed to load manager info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理员个人页面'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<Manager>(
        future: _managerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('加载管理员信息时发生错误: ${snapshot.error}'));
          } else if (snapshot.hasData) {
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
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('姓名'),
                    subtitle: Text(manager.name),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('邮箱'),
                    subtitle: Text(manager.email),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('联系电话'),
                    subtitle: Text(manager.contactNumber),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // 处理修改个人信息的逻辑
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
          } else {
            return const Center(child: Text('未找到管理员信息'));
          }
        },
      ),
    );
  }
}

class Manager {
  final String name;
  final String email;
  final String contactNumber;

  Manager({
    required this.name,
    required this.email,
    required this.contactNumber,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      name: json['name'],
      email: json['email'],
      contactNumber: json['contactNumber'],
    );
  }
}
