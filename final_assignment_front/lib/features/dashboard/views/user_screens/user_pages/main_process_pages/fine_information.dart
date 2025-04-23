import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hms_scan_kit/flutter_hms_scan_kit.dart';
import 'package:flutter_hms_scan_kit/scan_result.dart';
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
  String? _currentUsername;
  final Map<String, List<int>> _qrCodes = {}; // Store QR codes for each fine

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
      _currentUsername = prefs.getString('userName');
      if (jwtToken == null || _currentUsername == null) {
        throw Exception('未登录或未找到用户信息');
      }
      await fineApi.initializeWithJwt();
      _finesFuture = _loadUserFines();
      await _finesFuture.then((fines) {
        for (var fine in fines) {
          if (fine.status != 'Paid') _generateQRCode(fine);
        }
      });
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

  Future<void> _generateQRCode(FineInformation fine) async {
    try {
      final paymentUrl =
          'weixin://pay?amount=${fine.fineAmount}&payee=${fine.payee}&receipt=${fine.receiptNumber}';
      final bytes = await rootBundle.load("assets/images/ic_logo.png");
      final qrCode = await FlutterHmsScanKit.generateCode(
        content: paymentUrl,
        type: ScanTypeFormat.QRCODE_SCAN_TYPE,
        width: 200,
        height: 200,
        color: "#7CB342",
        logo: bytes.buffer.asUint8List(),
      );
      setState(() {
        _qrCodes[fine.receiptNumber ?? fine.fineTime ?? 'unknown'] = qrCode!;
      });
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
      _finesFuture = _loadUserFines();
    });
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
                    '请使用微信扫描以下二维码支付',
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: _qrCodes[qrKey] != null
                      ? Image.memory(Uint8List.fromList(_qrCodes[qrKey]!))
                      : const CircularProgressIndicator(),
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
                                  '暂无罚款记录',
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
