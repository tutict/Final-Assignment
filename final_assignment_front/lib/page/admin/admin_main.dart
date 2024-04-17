import 'package:flutter/material.dart';

class PersonalAdminPage extends StatefulWidget {
  @override
  _PersonalAdminPageState createState() => _PersonalAdminPageState();
}

class _PersonalAdminPageState extends State<PersonalAdminPage> {
  // 假设的用户信息
  final UserInfo _userInfo = UserInfo(
    username: '张三',
    email: 'zhangsan@example.com',
    phone: '13800138000',
  );

  // 当前选中的选项卡索引
  int _selectedIndex = 0;

  // 选项卡列表
  final List<Widget> _tabPages = [
    PersonalInfoTab(userInfo: _userInfo), // 个人信息
    VehicleManagementTab(), // 车辆管理
    SettingsTab(), // 系统设置
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('5G 个人/管理员'),
        // 底部的选项卡
        bottom: TabBar(
          controller: TabController(length: _tabPages.length, vsync: this),
          tabs: [
            Tab(text: '个人信息'),
            Tab(text: '车辆管理'),
            Tab(text: '系统设置'),
          ],
        ),
      ),
      body: TabBarView(
        controller: TabController(length: _tabPages.length, vsync: this),
        children: _tabPages,
      ),
    );
  }
}

// 个人信息选项卡
class PersonalInfoTab extends StatelessWidget {
  final UserInfo userInfo;

  PersonalInfoTab({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          UserCard(userInfo: userInfo),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // 处理修改密码点击事件
            },
            child: Text('修改密码'),
          ),
        ],
      ),
    );
  }
}

// 用户信息卡片
class UserCard extends StatelessWidget {
  final UserInfo userInfo;

  UserCard({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(userInfo.username),
            SizedBox(height: 8),
            Text(userInfo.email),
            SizedBox(height: 8),
            Text(userInfo.phone),
          ],
        ),
      ),
    );
  }
}

// 车辆管理选项卡
class VehicleManagementTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('车辆管理'),
    );
  }
}

// 系统设置选项卡
class SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('系统设置'),
    );
  }
}

// 用户信息模型
class UserInfo {
  String username;
  String email;
  String phone;

  UserInfo({
    required this.username,
    required this.email,
    required this.phone,
  });
}