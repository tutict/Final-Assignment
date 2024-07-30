import 'package:flutter/material.dart';

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  _VehicleManagementPageState createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  // 假设的车辆列表
  final List<Vehicle> _vehicles = [
    Vehicle(name: '奔驰C200', model: 'C-Class', brand: 'Mercedes-Benz', color: '黑色'),
    Vehicle(name: '宝马320i', model: '3 Series', brand: 'BMW', color: '白色'),
    // ... 更多车辆
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('5G 车辆管理'),
        actions: [
          // 添加车辆按钮
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddVehicleDialog();
            },
          ),
        ],
      ),
      body: VehiclesList(vehicles: _vehicles),
    );
  }

  // 显示添加车辆对话框
  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // 返回添加车辆的表单
        return AlertDialog(
          title: const Text('添加车辆'),
          content: const _VehicleForm(),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () {
                // 从表单获取数据并保存
                // 这里仅作为示例，实际应用中需要处理表单验证和数据保存逻辑
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// 车辆列表
class VehiclesList extends StatelessWidget {
  final List<Vehicle> vehicles;

  const VehiclesList({super.key, required this.vehicles});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(vehicle.brand[0]),
          ),
          title: Text(vehicle.name),
          subtitle: Text('型号: ${vehicle.model}, 品牌: ${vehicle.brand}, 颜色: ${vehicle.color}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // 编辑车辆信息
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('编辑车辆信息'),
                    content: _VehicleForm(
                      initialName: vehicle.name,
                      initialModel: vehicle.model,
                      initialBrand: vehicle.brand,
                      initialColor: vehicle.color,
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('取消'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('保存'),
                        onPressed: () {
                          // 从表单获取数据并更新车辆信息
                          // 这里仅作为示例，实际应用中需要处理表单验证和数据更新逻辑
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// 车辆表单
class _VehicleForm extends StatefulWidget {
  final String initialName;
  final String initialModel;
  final String initialBrand;
  final String initialColor;

  const _VehicleForm({
    this.initialName = '',
    this.initialModel = '',
    this.initialBrand = '',
    this.initialColor = '',
  });

  @override
  __VehicleFormState createState() => __VehicleFormState();
}

class __VehicleFormState extends State<_VehicleForm> {
  late String _name;
  late String _model;
  late String _brand;
  late String _color;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName;
    _model = widget.initialModel;
    _brand = widget.initialBrand;
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextFormField(
          decoration: const InputDecoration(labelText: '车辆名称'),
          initialValue: _name,
          onChanged: (value) {
            setState(() {
              _name = value;
            });
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: '车辆型号'),
          initialValue: _model,
          onChanged: (value) {
            setState(() {
              _model = value;
            });
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: '车辆品牌'),
          initialValue: _brand,
          onChanged: (value) {
            setState(() {
              _brand = value;
            });
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: '车辆颜色'),
          initialValue: _color,
          onChanged: (value) {
            setState(() {
              _color = value;
            });
          },
        ),
      ],
    );
  }
}

// 车辆模型
class Vehicle {
  String name;
  String model;
  String brand;
  String color;

  Vehicle({
    required this.name,
    required this.model,
    required this.brand,
    required this.color,
  });
}