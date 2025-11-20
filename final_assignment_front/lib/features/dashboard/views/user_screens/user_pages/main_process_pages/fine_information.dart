import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

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
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final UserManagementControllerApi userApi =
      UserManagementControllerApi();
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentDriverName;
  final Map<String, Widget> _qrCodes = {};

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
      _currentDriverName = prefs.getString('driverName');
      if (_currentDriverName == null && jwtToken != null) {
        _currentDriverName = await _fetchDriverName(jwtToken);
        if (_currentDriverName != null) {
          await prefs.setString('driverName', _currentDriverName!);
        } else {
          _currentDriverName = '黄广龙'; // Fallback, avoid in production
        }
        developer.log('Fetched and stored driver name: $_currentDriverName');
      }
      developer.log('Current Driver Name: $_currentDriverName');
      if (jwtToken == null || _currentDriverName == null) {
        throw Exception('未登录或未找到驾驶员信息');
      }
      await fineApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      await userApi.initializeWithJwt();
      _finesFuture = _loadUserFines();
      final fines = await _finesFuture;
      developer.log('Loaded Fines: $fines');
      for (var fine in fines) {
        if (fine.status != 'Paid') await _generateQRCode(fine);
      }
    } catch (e) {
      developer.log('Initialization error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '初始化失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _fetchDriverName(String jwtToken) async {
    try {
      await userApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('userName');
      Map<String, dynamic>? decoded;
      try {
        decoded = JwtDecoder.decode(jwtToken);
      } catch (_) {}
      final username = storedUsername?.isNotEmpty == true
          ? storedUsername!
          : decoded?['sub']?.toString();
      if (username == null || username.isEmpty) {
        throw Exception('无法确定当前用户名');
      }

      final user =
          await userApi.apiUsersSearchUsernameGet(username: username);
      if (user?.userId == null) {
        throw Exception('User data does not contain userId');
      }

      await driverApi.initializeWithJwt();
      final driverInfo =
          await driverApi.apiDriversDriverIdGet(driverId: user!.userId!);
      if (driverInfo != null && driverInfo.name != null) {
        final driverName = driverInfo.name!;
        developer.log('Driver name from API: $driverName');
        return driverName;
      } else {
        developer.log('No driver info found for userId: ${user.userId}');
        return null;
      }
    } catch (e) {
      developer.log('Error fetching driver name: $e');
      return null;
    }
  }

  Future<List<FineInformation>> _loadUserFines() async {
    try {
      final allFines = await fineApi.apiFinesGet();
      developer.log('All Fines: $allFines');
      final filteredFines =
          allFines.where((fine) => fine.payee == _currentDriverName).toList();
      developer.log('Filtered Fines for $_currentDriverName: $filteredFines');
      return filteredFines;
    } catch (e) {
      developer.log('Error loading fines: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '加载罚款信息失败: $e';
      });
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateQRCode(FineInformation fine) async {
    try {
      // 使用支付宝支付链接（如果需要调整为支付宝格式，请提供具体 URL 模板）
      final paymentUrl =
          'weixin://pay?amount=${fine.fineAmount}&payee=${fine.payee}&receipt=${fine.receiptNumber}';
      // 示例支付宝支付链接（待确认）：'alipays://platformapi/startapp?appId=xxx&amount=${fine.fineAmount}&payee=${fine.payee}&receipt=${fine.receiptNumber}';

      final qrWidget = QrImageView(
        data: paymentUrl,
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color(0xFF7CB342),
        // 绿色，与支付宝主题相近
        // embeddedImage: const AssetImage('assets/images/ic_logo.jpg'),
        // 支付宝 logo
        embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(60, 60)),
      );
      final qrKey = fine.receiptNumber ?? fine.fineTime ?? 'unknown';
      setState(() {
        _qrCodes[qrKey] = qrWidget;
      });
      developer.log('Generated QR code for fine ${fine.receiptNumber}');
    } catch (e) {
      debugPrint(
          'Failed to generate QR code for fine ${fine.receiptNumber}: $e');
      _showSnackBar('生成付款码失败: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _refreshFines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _qrCodes.clear();
    });
    try {
      _finesFuture = _loadUserFines();
      final fines = await _finesFuture;
      developer.log('Refreshed Fines: $fines');
      for (var fine in fines) {
        if (fine.status != 'Paid') await _generateQRCode(fine);
      }
    } catch (e) {
      developer.log('Error refreshing fines: $e');
      setState(() {
        _errorMessage = '刷新罚款信息失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFineDetailsDialog(FineInformation fine) {
    final themeData = controller.currentBodyTheme.value;
    final qrKey = fine.receiptNumber ?? fine.fineTime ?? 'unknown';
    final hasQRCode = _qrCodes.containsKey(qrKey) && fine.status != 'Paid';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeData.colorScheme.surfaceContainer,
        title: Text(
          '罚款详情',
          style: themeData.textTheme.titleLarge?.copyWith(
            color: themeData.colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  '罚款金额',
                  '\$${fine.fineAmount?.toStringAsFixed(2) ?? "0.00"}',
                  themeData),
              _buildDetailRow('缴款人', fine.payee ?? '未知', themeData),
              _buildDetailRow('银行账号', fine.accountNumber ?? '未知', themeData),
              _buildDetailRow('银行名称', fine.bank ?? '未知', themeData),
              _buildDetailRow('收据编号', fine.receiptNumber ?? '未知', themeData),
              _buildDetailRow('罚款时间', fine.fineTime ?? '未知', themeData),
              _buildDetailRow('状态', fine.status ?? 'Pending', themeData),
              _buildDetailRow('备注', fine.remarks ?? '无', themeData),
              if (hasQRCode) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '请使用支付宝扫描以下二维码支付', // 更新为支付宝提示
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: _qrCodes[qrKey] ?? const CircularProgressIndicator(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '关闭',
              style: themeData.textTheme.labelMedium?.copyWith(
                color: themeData.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller.currentBodyTheme.value;

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '交通违法罚款记录',
          style: themeData.textTheme.headlineSmall?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      themeData.colorScheme.primary),
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: themeData.textTheme.bodyLarge?.copyWith(
                        color: themeData.colorScheme.onSurface,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: FutureBuilder<List<FineInformation>>(
                          future: _finesFuture,
                          builder: (context, snapshot) {
                            developer.log(
                                'FutureBuilder state: ${snapshot.connectionState}, data: ${snapshot.data}, error: ${snapshot.error}');
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      themeData.colorScheme.primary),
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  '加载罚款信息失败: ${snapshot.error}',
                                  style:
                                      themeData.textTheme.bodyLarge?.copyWith(
                                    color: themeData.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  _currentDriverName != null
                                      ? '暂无与驾驶员 $_currentDriverName 匹配的罚款记录'
                                      : '未找到驾驶员信息，请重新登录',
                                  style:
                                      themeData.textTheme.bodyLarge?.copyWith(
                                    color: themeData.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            } else {
                              final fines = snapshot.data!;
                              return RefreshIndicator(
                                onRefresh: _refreshFines,
                                child: ListView.builder(
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
                                      color: themeData
                                          .colorScheme.surfaceContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          '罚款金额: \$${amount.toStringAsFixed(2)}',
                                          style: themeData.textTheme.bodyLarge
                                              ?.copyWith(
                                            color:
                                                themeData.colorScheme.onSurface,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '缴款人: $payee\n时间: $date\n状态: $status',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        trailing: Icon(
                                          status == 'Paid'
                                              ? Icons.check_circle
                                              : Icons.payment,
                                          color: status == 'Paid'
                                              ? Colors.green
                                              : themeData
                                                  .colorScheme.onSurfaceVariant,
                                        ),
                                        onTap: () {
                                          _showFineDetailsDialog(record);
                                        },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshFines,
        backgroundColor: themeData.colorScheme.primary,
        foregroundColor: themeData.colorScheme.onPrimary,
        tooltip: '刷新罚款记录',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
