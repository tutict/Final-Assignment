import 'dart:convert';
import 'dart:developer' as develop;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DriverList extends StatefulWidget {
  const DriverList({super.key});

  @override
  State<DriverList> createState() => _DriverListPage();
}

class _DriverListPage extends State<DriverList>
    with AddDriverPage, DriverDetailPage {
  late Future<List<Driver>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _driversFuture = _fetchDrivers();
  }

  Future<List<Driver>> _fetchDrivers() async {
    final url = Uri.parse(
        '\${AppConfig.baseUrl}\${AppConfig.driverInformationEndpoint}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> driversJson = jsonDecode(response.body);
        return driversJson.map((json) => Driver.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load drivers');
      }
    } catch (e) {
      develop.log('Error: \$e');
      throw Exception('Failed to load drivers: \$e');
    }
  }

  Future<void> _deleteDriver(int driverId) async {
    final url = Uri.parse(
        '\${AppConfig.baseUrl}\${AppConfig.driverInformationEndpoint}/\$driverId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除司机信息成功！')),
        );
        setState(() {
          _driversFuture = _fetchDrivers(); // 刷新司机信息列表
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除司机信息失败，请稍后重试。')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发生错误，请检查网络连接。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('司机信息列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => buildAddDriverPage(context)),
              ).then((value) {
                if (value == true) {
                  setState(() {
                    _driversFuture = _fetchDrivers();
                  });
                }
              });
            },
            tooltip: '添加新司机',
          ),
        ],
      ),
      body: FutureBuilder<List<Driver>>(
        future: _driversFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('加载司机信息时发生错误: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('没有找到司机信息'));
          } else {
            final drivers = snapshot.data!;
            return ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: const Text('司机姓名: \${driver.name}'),
                    subtitle: const Text(
                        '驾驶证号: \${driver.driverLicenseNumber}\n联系电话: \${driver.contactNumber}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteDriver(driver.driverId),
                      tooltip: '删除此司机',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                buildDriverDetailPage(context, driver)),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

mixin AddDriverPage {
  Widget buildAddDriverPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加新司机'),
      ),
      body: const Center(
        child: Text('此页面用于添加新司机信息（尚未实现）'),
      ),
    );
  }
}

mixin DriverDetailPage {
  Widget buildDriverDetailPage(BuildContext context, Driver driver) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('司机详细信息'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('姓名: \${driver.name}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text('身份证号: \${driver.idCardNumber}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('联系电话: \${driver.contactNumber}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('驾驶证号: \${driver.driverLicenseNumber}',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class Driver {
  final int driverId;
  final String name;
  final String idCardNumber;
  final String contactNumber;
  final String driverLicenseNumber;

  Driver({
    required this.driverId,
    required this.name,
    required this.idCardNumber,
    required this.contactNumber,
    required this.driverLicenseNumber,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverId: json['driverId'],
      name: json['name'],
      idCardNumber: json['idCardNumber'],
      contactNumber: json['contactNumber'],
      driverLicenseNumber: json['driverLicenseNumber'],
    );
  }
}
