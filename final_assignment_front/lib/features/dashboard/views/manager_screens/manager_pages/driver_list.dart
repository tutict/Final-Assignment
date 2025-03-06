import 'dart:developer' as developer;
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

/// 唯一标识生成工具
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// 司机信息列表页面
class DriverList extends StatefulWidget {
  const DriverList({super.key});

  @override
  State<DriverList> createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverList> {
  late DriverInformationControllerApi driverApi;
  late Future<List<DriverInformation>> _driversFuture;
  final UserDashboardController controller = Get.find<UserDashboardController>();
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();
    _loadDrivers(); // 直接加载司机信息
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  /// 加载所有司机信息
  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await driverApi.initializeWithJwt(); // Set JWT before making the API call
      _driversFuture = driverApi.apiDriversGet(); // Assign future after JWT is set
      await _driversFuture; // Wait for the data
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching drivers: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '加载司机信息失败: $e';
        if (e.toString().contains('未登录')) {
          _redirectToLogin();
        }
      });
    }
  }

  /// 按姓名搜索司机信息
  Future<void> _searchDriversByName(String query) async {
    if (query.isEmpty) {
      _loadDrivers();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await driverApi.initializeWithJwt();
      _driversFuture = driverApi.apiDriversNameNameGet(name: query);
      await _driversFuture;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error searching drivers by name: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
        if (e.toString().contains('未登录')) {
          _redirectToLogin();
        }
      });
    }
  }

  /// 按身份证号搜索司机信息
  Future<void> _searchDriversByIdCardNumber(String query) async {
    if (query.isEmpty) {
      _loadDrivers();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await driverApi.initializeWithJwt();
      final driver = await driverApi.apiDriversIdCardNumberIdCardNumberGet(idCardNumber: query);
      _driversFuture = Future.value(driver != null ? [driver] : []);
      await _driversFuture;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error searching drivers by ID card: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
        if (e.toString().contains('未登录')) {
          _redirectToLogin();
        }
      });
    }
  }

  /// 按驾驶证号搜索司机信息
  Future<void> _searchDriversByDriverLicenseNumber(String query) async {
    if (query.isEmpty) {
      _loadDrivers();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await driverApi.initializeWithJwt();
      final driver = await driverApi.apiDriversDriverLicenseNumberDriverLicenseNumberGet(
          driverLicenseNumber: query);
      _driversFuture = Future.value(driver != null ? [driver] : []);
      await _driversFuture;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error searching drivers by license: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: $e';
        if (e.toString().contains('未登录')) {
          _redirectToLogin();
        }
      });
    }
  }

  /// 删除司机信息
  Future<void> _deleteDriver(String driverId) async {
    try {
      await driverApi.initializeWithJwt();
      await driverApi.apiDriversDriverIdDelete(driverId: driverId);
      _showSuccessSnackBar('删除司机成功！');
      _loadDrivers();
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login'); // Adjust route name as needed
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  void _goToDetailPage(DriverInformation driver) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DriverDetailPage(driver: driver)),
    ).then((value) {
      if (value == true && mounted) {
        _loadDrivers();
      }
    });
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
            title: const Text('司机信息列表'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'name') {
                    _searchDriversByName(_nameController.text.trim());
                  } else if (value == 'idCard') {
                    _searchDriversByIdCardNumber(_idCardNumberController.text.trim());
                  } else if (value == 'license') {
                    _searchDriversByDriverLicenseNumber(_driverLicenseNumberController.text.trim());
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(value: 'name', child: Text('按姓名搜索')),
                  const PopupMenuItem<String>(value: 'idCard', child: Text('按身份证号搜索')),
                  const PopupMenuItem<String>(value: 'license', child: Text('按驾驶证号搜索')),
                ],
                icon: const Icon(Icons.filter_list, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddDriverPage()),
                  ).then((value) {
                    if (value == true && mounted) {
                      _loadDrivers();
                    }
                  });
                },
                tooltip: '添加新司机',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '姓名',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                          ),
                        ),
                        style: TextStyle(color: isLight ? Colors.black : Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchDriversByName(_nameController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idCardNumberController,
                        decoration: InputDecoration(
                          labelText: '身份证号',
                          prefixIcon: const Icon(Icons.card_membership),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                          ),
                        ),
                        style: TextStyle(color: isLight ? Colors.black : Colors.white),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchDriversByIdCardNumber(_idCardNumberController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _driverLicenseNumberController,
                        decoration: InputDecoration(
                          labelText: '驾驶证号',
                          prefixIcon: const Icon(Icons.drive_eta),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                          ),
                        ),
                        style: TextStyle(color: isLight ? Colors.black : Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _searchDriversByDriverLicenseNumber(_driverLicenseNumberController.text.trim()),
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
                  Expanded(child: Center(child: Text(_errorMessage)))
                else
                  Expanded(
                    child: FutureBuilder<List<DriverInformation>>(
                      future: _driversFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '加载司机信息失败: ${snapshot.error}',
                              style: TextStyle(color: isLight ? Colors.black : Colors.white),
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              '暂无司机信息',
                              style: TextStyle(color: isLight ? Colors.black : Colors.white),
                            ),
                          );
                        } else {
                          final drivers = snapshot.data!;
                          return RefreshIndicator(
                            onRefresh: _loadDrivers,
                            child: ListView.builder(
                              itemCount: drivers.length,
                              itemBuilder: (context, index) {
                                final driver = drivers[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                  elevation: 4,
                                  color: isLight ? Colors.white : Colors.grey[800],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  child: ListTile(
                                    title: Text(
                                      '司机姓名: ${driver.name ?? "未知"}',
                                      style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                                    ),
                                    subtitle: Text(
                                      '驾驶证号: ${driver.driverLicenseNumber ?? ""}\n联系电话: ${driver.contactNumber ?? ""}',
                                      style: TextStyle(color: isLight ? Colors.black54 : Colors.white70),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        final did = driver.driverId?.toString();
                                        if (did != null) {
                                          if (value == 'edit') {
                                            _goToDetailPage(driver);
                                          } else if (value == 'delete') {
                                            _deleteDriver(did);
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem<String>(value: 'edit', child: Text('编辑')),
                                        const PopupMenuItem<String>(value: 'delete', child: Text('删除')),
                                      ],
                                      icon: Icon(Icons.more_vert, color: isLight ? Colors.black87 : Colors.white),
                                    ),
                                    onTap: () => _goToDetailPage(driver),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 添加司机信息页面
class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final driverApi = DriverInformationControllerApi();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitDriver() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await driverApi.initializeWithJwt();
      final driver = DriverInformation(
        name: _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
      );
      await driverApi.apiDriversPost(driverInformation: driver);
      _showSuccessSnackBar('创建司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('创建司机失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加新司机'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '姓名',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                  ),
                ),
                style: TextStyle(color: isLight ? Colors.black : Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _idCardNumberController,
                decoration: InputDecoration(
                  labelText: '身份证号码',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                  ),
                ),
                style: TextStyle(color: isLight ? Colors.black : Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactNumberController,
                decoration: InputDecoration(
                  labelText: '联系电话',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                  ),
                ),
                style: TextStyle(color: isLight ? Colors.black : Colors.white),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _driverLicenseNumberController,
                decoration: InputDecoration(
                  labelText: '驾驶证号',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                  ),
                ),
                style: TextStyle(color: isLight ? Colors.black : Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('提交'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.grey,
                  foregroundColor: isLight ? Colors.black87 : Colors.white,
                ),
                child: const Text('返回上一级'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 编辑司机信息页面
class EditDriverPage extends StatefulWidget {
  final DriverInformation driver;

  const EditDriverPage({super.key, required this.driver});

  @override
  State<EditDriverPage> createState() => _EditDriverPageState();
}

class _EditDriverPageState extends State<EditDriverPage> {
  final driverApi = DriverInformationControllerApi();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController.text = widget.driver.name ?? '';
    _idCardNumberController.text = widget.driver.idCardNumber ?? '';
    _contactNumberController.text = widget.driver.contactNumber ?? '';
    _driverLicenseNumberController.text = widget.driver.driverLicenseNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitDriver() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await driverApi.initializeWithJwt();
      final driver = DriverInformation(
        driverId: widget.driver.driverId,
        name: _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
      );
      await driverApi.apiDriversDriverIdPut(
        driverId: widget.driver.driverId?.toString() ?? '',
        driverInformation: driver,
      );
      _showSuccessSnackBar('更新司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('更新司机失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑司机信息'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '姓名',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                  ),
                ),
                style: TextStyle(color: isLight ? Colors.black : Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _idCardNumberController,
                decoration: InputDecoration(
                  labelText: '身份证号码',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                  ),
                ),
                style: TextStyle(color: isLight ? Colors.black : Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactNumberController,
                decoration: InputDecoration(
                  labelText: '联系电话',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                  ),
                ),
                style: TextStyle(color: isLight ? Colors.black : Colors.white),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _driverLicenseNumberController,
                decoration: InputDecoration(
                  labelText: '驾驶证号',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.grey : Colors.grey[500]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isLight ? Colors.blue : Colors.blueGrey),
                  ),
                ),
                style: TextStyle(color: isLight ? Colors.black : Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('保存'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.grey,
                  foregroundColor: isLight ? Colors.black87 : Colors.white,
                ),
                child: const Text('返回上一级'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 司机详细信息页面
class DriverDetailPage extends StatefulWidget {
  final DriverInformation driver;

  const DriverDetailPage({super.key, required this.driver});

  @override
  State<DriverDetailPage> createState() => _DriverDetailPageState();
}

class _DriverDetailPageState extends State<DriverDetailPage> {
  final driverApi = DriverInformationControllerApi();
  bool _isLoading = false; // Fixed: Changed to non-final to allow state updates
  final UserDashboardController controller = Get.find<UserDashboardController>();

  Future<void> _deleteDriver(String driverId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await driverApi.initializeWithJwt();
      await driverApi.apiDriversDriverIdDelete(driverId: driverId);
      _showSuccessSnackBar('删除司机成功！');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final name = widget.driver.name ?? '未知';
    final idCard = widget.driver.idCardNumber ?? '无';
    final contact = widget.driver.contactNumber ?? '无';
    final license = widget.driver.driverLicenseNumber ?? '无';
    final driverId = widget.driver.driverId?.toString() ?? '0';

    return Obx(
          () => Theme(
        data: controller.currentBodyTheme.value,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('司机详细信息'),
            backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditDriverPage(driver: widget.driver)),
                  ).then((value) {
                    if (value == true && mounted) {
                      setState(() {}); // 刷新页面
                    }
                  });
                },
                tooltip: '编辑司机信息',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteDriver(driverId),
                tooltip: '删除司机',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              children: [
                _buildDetailRow(context, '司机 ID', driverId),
                _buildDetailRow(context, '姓名', name),
                _buildDetailRow(context, '身份证号', idCard),
                _buildDetailRow(context, '联系电话', contact),
                _buildDetailRow(context, '驾驶证号', license),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: isLight ? Colors.black87 : Colors.white),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isLight ? Colors.black54 : Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}