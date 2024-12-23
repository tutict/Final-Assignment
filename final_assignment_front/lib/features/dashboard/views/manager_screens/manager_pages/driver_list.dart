import 'dart:developer' as developer;

import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:flutter/material.dart';

class DriverList extends StatefulWidget {
  const DriverList({super.key});

  @override
  State<DriverList> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverList>
    with AddDriverPage, DriverDetailPage {
  // 我们将使用这个Api来发起HTTP请求
  late DriverInformationControllerApi driverApi;

  // Future 用于异步加载司机列表
  late Future<List<DriverInformation>> _driversFuture;

  @override
  void initState() {
    super.initState();
    // 初始化 ApiClient
    driverApi = DriverInformationControllerApi();

    // 加载司机列表
    _driversFuture = _fetchDrivers();
  }

  /// 获取司机列表
  /// 如果 [query] 不为空，则按姓名搜索
  Future<List<DriverInformation>> _fetchDrivers({String? query}) async {
    try {
      if (query != null && query.isNotEmpty) {
        // 调用按姓名搜索: apiDriversNameNameGet({required String name})
        final result = await driverApi.apiDriversNameNameGet(name: query);
        if (result == null) {
          return [];
        }

        // result 可能是List<Object>或单个Object，具体看后端返回
        // 这里假设后端返回List<Object> (即多条记录)
        if (result is List) {
          // 将 List<dynamic> 转成 List<DriverInformation>
          return result.map((item) {
            return DriverInformation.fromJson(item as Map<String, dynamic>);
          }).toList();
        } else if (result is Map) {
          final typedMap = Map<String, dynamic>.from(result);
          return [DriverInformation.fromJson(typedMap)];
        } else {
          return [];
        }
      } else {
        // 否则获取所有司机: apiDriversGet()，返回 Future<List<Object>?>
        final listObj = await driverApi.apiDriversGet();
        if (listObj == null) return [];
        // 将 List<Object> -> List<DriverInformation>
        return listObj.map((item) {
          return DriverInformation.fromJson(item as Map<String, dynamic>);
        }).toList();
      }
    } catch (e) {
      developer.log('Error fetching drivers: $e');
      rethrow;
    }
  }

  /// 删除司机
  Future<void> _deleteDriver(int driverId) async {
    try {
      // 接口要求传 String driverId
      final responseObj = await driverApi.apiDriversDriverIdDelete(
        driverId: driverId.toString(),
      );
      // responseObj 可能是null或Object; 这里仅演示
      // 刷新列表
      setState(() {
        _driversFuture = _fetchDrivers();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除司机信息成功！')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除司机信息失败: $e')),
      );
    }
  }

  /// 按姓名搜索
  void _searchDrivers(String query) {
    setState(() {
      _driversFuture = _fetchDrivers(query: query);
    });
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
              // 跳转到添加司机页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => buildAddDriverPage(context),
                ),
              ).then((value) {
                if (value == true) {
                  // 如果添加成功，刷新列表
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
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchDrivers,
              decoration: const InputDecoration(
                labelText: '按姓名搜索',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // 列表
          Expanded(
            child: FutureBuilder<List<DriverInformation>>(
              future: _driversFuture,
              builder: (context, snapshot) {
                // 正在加载
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // 出错
                else if (snapshot.hasError) {
                  return Center(child: Text('加载司机信息时发生错误: ${snapshot.error}'));
                }
                // 没数据
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('没有找到司机信息'));
                }
                // 有数据
                else {
                  final drivers = snapshot.data!;
                  return ListView.builder(
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: ListTile(
                          // 司机姓名
                          title: Text('司机姓名: ${driver.name ?? "未知"}'),
                          // 驾驶证号 & 联系电话
                          subtitle: Text(
                            '驾驶证号: ${driver.driverLicenseNumber ?? ""}\n'
                            '联系电话: ${driver.contactNumber ?? ""}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // driverId 是 int?
                              final id = driver.driverId;
                              if (id != null) {
                                _deleteDriver(id);
                              }
                            },
                            tooltip: '删除此司机',
                          ),
                          onTap: () {
                            // 查看详情
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    buildDriverDetailPage(context, driver),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ============= 以下保留原示例中的 mixins 和 model ==============

mixin AddDriverPage {
  /// 演示：添加司机信息页面 (尚未实现具体提交逻辑)
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
  /// 演示：司机详情页
  /// 这里直接使用 DriverInformation，而不是原先的 Driver
  Widget buildDriverDetailPage(BuildContext context, DriverInformation driver) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('司机详细信息'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('姓名: ${driver.name ?? ""}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text('身份证号: ${driver.idCardNumber ?? ""}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('联系电话: ${driver.contactNumber ?? ""}',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8.0),
            Text('驾驶证号: ${driver.driverLicenseNumber ?? ""}',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
