import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FineInformationPage extends StatefulWidget {
  const FineInformationPage({super.key});

  @override
  State<FineInformationPage> createState() => _FineInformationPageState();
}

class _FineInformationPageState extends State<FineInformationPage> {
  late FineInformationControllerApi fineApi;
  late Future<List<FineInformation>> _finesFuture;
  final UserDashboardController controller =
  Get.find<UserDashboardController>();
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentUsername; // 用于筛选当前用户的罚款记录

  @override
  void initState() {
    super.initState();
    fineApi = FineInformationControllerApi();
    _initializeFines();
  }

  Future<void> _initializeFines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      _currentUsername = prefs.getString('userName'); // 假定用户名已存储
      if (jwtToken == null || _currentUsername == null) {
        throw Exception('No JWT token or username found');
      }
      // 初始化 jwt 到 ApiClient
      await fineApi.initializeWithJwt();
      _finesFuture = _loadUserFines();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '初始化失败: $e';
      });
    }
  }

  Future<List<FineInformation>> _loadUserFines() async {
    try {
      final allFines = await fineApi.apiFinesGet();
      return allFines.where((fine) => fine.payee == _currentUsername).toList();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载罚款信息失败: $e';
      });
      return [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(color: isError ? Colors.red : Colors.white)),
        backgroundColor: isError ? Colors.grey[800] : Colors.green,
      ),
    );
  }

  Future<void> _refreshFines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _finesFuture = _loadUserFines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('交通违法罚款记录'),
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        foregroundColor: Colors.white,
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
                color: isLight ? Colors.black : Colors.white),
          ),
        )
            : Column(
          children: [
            Expanded(
              child: FutureBuilder<List<FineInformation>>(
                future: _finesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '加载罚款信息失败: ${snapshot.error}',
                        style: TextStyle(
                            color: isLight
                                ? Colors.black
                                : Colors.white),
                      ),
                    );
                  } else if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无罚款记录',
                        style: TextStyle(
                            color: isLight
                                ? Colors.black
                                : Colors.white),
                      ),
                    );
                  } else {
                    final fines = snapshot.data!;
                    return ListView.builder(
                      itemCount: fines.length,
                      itemBuilder: (context, index) {
                        final record = fines[index];
                        final amount = record.fineAmount ?? 0.0;
                        final payee = record.payee ?? '未知';
                        final date = record.fineTime ?? '未知';
                        final status = record.status ?? 'Pending';
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0),
                          color: isLight
                              ? Colors.white
                              : Colors.grey[800],
                          child: ListTile(
                            title: Text(
                              '罚款金额: \$${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: isLight
                                      ? Colors.black87
                                      : Colors.white),
                            ),
                            subtitle: Text(
                              '缴款人: $payee\n时间: $date\n状态: $status',
                              style: TextStyle(
                                  color: isLight
                                      ? Colors.black54
                                      : Colors.white70),
                            ),
                            trailing: Icon(
                              Icons.info,
                              color: isLight
                                  ? Colors.grey
                                  : Colors.white70,
                            ),
                            onTap: () {
                              _showFineDetailsDialog(record);
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshFines,
        backgroundColor: isLight ? Colors.blue : Colors.blueGrey,
        tooltip: '刷新罚款记录',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showFineDetailsDialog(FineInformation fine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('罚款详情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  '罚款金额', '\$${fine.fineAmount?.toStringAsFixed(2) ?? "0.00"}'),
              _buildDetailRow('缴款人', fine.payee ?? '未知'),
              _buildDetailRow('银行账号', fine.accountNumber ?? '未知'),
              _buildDetailRow('银行名称', fine.bank ?? '未知'),
              _buildDetailRow('收据编号', fine.receiptNumber ?? '未知'),
              _buildDetailRow('罚款时间', fine.fineTime ?? '未知'),
              _buildDetailRow('状态', fine.status ?? 'Pending'),
              _buildDetailRow('备注', fine.remarks ?? '无'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
