import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:async';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:final_assignment_front/core/realtime/business_event_listener.dart';
import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/dashboard/views/user/pages/main_process/user_business_page_chrome.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:final_assignment_front/utils/workflow_permissions.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

class FineInformationPage extends StatefulWidget {
  const FineInformationPage({super.key});

  @override
  State<FineInformationPage> createState() => _FineInformationPageState();
}

class _FineInformationPageState extends State<FineInformationPage> {
  late FineInformationControllerApi fineApi;
  Future<List<FineInformation>> _finesFuture =
      Future<List<FineInformation>>.value(const <FineInformation>[]);
  final UserDashboardController controller =
      Get.find<UserDashboardController>();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final UserManagementControllerApi userApi = UserManagementControllerApi();
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentDriverName;
  final Map<String, Widget> _qrCodes = {};
  StreamSubscription<PaymentStatusChange>? _paymentStatusSubscription;

  String? _paymentStatusOf(FineInformation fine) =>
      fine.paymentStatus ?? fine.status;

  String _paymentStatusLabel(String? status) {
    return PaymentStatus.fromCode(status)?.label ?? status ?? '未知';
  }

  bool _isPaid(String? status) =>
      PaymentStatus.fromCode(status) == PaymentStatus.paid;

  @override
  void initState() {
    super.initState();
    fineApi = FineInformationControllerApi();
    _startBusinessEventSubscription();
    _initializeFines();
  }

  @override
  void dispose() {
    _paymentStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startBusinessEventSubscription() async {
    if (!Get.isRegistered<BusinessEventListener>()) {
      return;
    }
    final listener = Get.find<BusinessEventListener>();
    try {
      await listener.startListening();
      _paymentStatusSubscription ??= listener.paymentStatusChanges.stream
          .listen(_handlePaymentStatusChange);
    } catch (e) {
      AppLogger.debug('Failed to start payment status listener: $e');
    }
  }

  Future<void> _handlePaymentStatusChange(PaymentStatusChange change) async {
    if (!mounted || change.fineId == null || change.newStatus.isEmpty) {
      return;
    }
    try {
      final currentFines = await _finesFuture;
      final updatedFines = currentFines.map((fine) {
        if (fine.fineId != change.fineId) {
          return fine;
        }
        return fine.copyWith(
          paymentStatus: change.newStatus,
          status: change.newStatus,
          updatedAt: change.updatedAt,
        );
      }).toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _finesFuture = Future.value(updatedFines);
      });
      _showSnackBar('支付状态已更新为 ${_paymentStatusLabel(change.newStatus)}');
    } catch (e) {
      AppLogger.debug('Payment status local update failed: $e');
    }
  }

  Future<void> _initializeFines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jwtToken = await AuthTokenStore.instance.getJwtToken();
      if (jwtToken != null && JwtDecoder.isExpired(jwtToken)) {
        final refreshed = await Get.find<AuthService>().refreshJwtToken();
        jwtToken = await AuthTokenStore.instance.getJwtToken();
        if (!refreshed || jwtToken == null || JwtDecoder.isExpired(jwtToken)) {
          throw Exception('登录已过期，请重新登录');
        }
      }
      _currentDriverName = prefs.getString('driverName');
      if (_currentDriverName == null && jwtToken != null) {
        _currentDriverName = await _fetchDriverName();
        if (_currentDriverName != null) {
          await prefs.setString('driverName', _currentDriverName!);
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
        if (canPay(_paymentStatusOf(fine))) await _generateQRCode(fine);
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

  Future<String?> _fetchDriverName() async {
    try {
      final jwtToken = await AuthTokenStore.instance.getJwtToken();
      if (jwtToken == null || jwtToken.isEmpty) {
        return null;
      }
      await userApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('userName');
      Map<String, dynamic>? decoded;
      try {
        decoded = JwtDecoder.decode(jwtToken);
      } catch (e, stackTrace) {
        developer.log(
          'JWT decode failed',
          name: 'AuthError',
          error: e,
          stackTrace: stackTrace,
        );
        if (Get.isRegistered<AuthService>()) {
          await Get.find<AuthService>().clearTokens();
        } else {
          await prefs.remove('jwtToken');
          await prefs.remove('refreshToken');
        }
        NavigationHelper.offAllNamed(Routes.login);
        return null;
      }
      final username = storedUsername?.isNotEmpty == true
          ? storedUsername!
          : decoded['sub']?.toString();
      if (username == null || username.isEmpty) {
        throw Exception('无法确定当前用户名');
      }

      if (!Get.isRegistered<UserProfileService>()) {
        throw Exception('UserProfileService is not registered');
      }
      final profile = await Get.find<UserProfileService>().getProfile();
      final driverId = profile.driverId;
      if (driverId == null) {
        setState(() {
          _errorMessage = '您的账户尚未关联司机档案，请联系管理员';
        });
        return null;
      }

      await driverApi.initializeWithJwt();
      final driverInfo = await driverApi.getDriver(driverId: driverId);
      if (driverInfo != null && driverInfo.name != null) {
        final driverName = driverInfo.name!;
        developer.log('Driver name from API: $driverName');
        return driverName;
      } else {
        developer.log('No driver info found for driverId: $driverId');
        return null;
      }
    } catch (e) {
      developer.log('Error fetching driver name: $e');
      return null;
    }
  }

  Future<List<FineInformation>> _loadUserFines() async {
    try {
      final allFines = await fineApi.listFines();
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
        eyeStyle: const QrEyeStyle(color: Color(0xFF7CB342)),
        dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF7CB342)),
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
      AppLogger.debug(
          'Failed to generate QR code for fine ${fine.receiptNumber}: $e');
      _showSnackBar('生成付款码失败: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    showUserBusinessToast(context, message: message, isError: isError);
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
        if (canPay(_paymentStatusOf(fine))) await _generateQRCode(fine);
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
    final hasQRCode =
        _qrCodes.containsKey(qrKey) && canPay(_paymentStatusOf(fine));

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
              _buildDetailRow(
                  '状态', _paymentStatusLabel(_paymentStatusOf(fine)), themeData),
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

    return DashboardPageTemplate(
      theme: themeData,
      title: '罚款缴纳',
      pageType: DashboardPageType.user,
      bodyIsScrollable: true,
      padding: EdgeInsets.zero,
      actions: [
        DashboardPageBarAction(
          icon: Icons.refresh,
          onPressed: _refreshFines,
          tooltip: '刷新罚款记录',
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: UserBusinessPageHeader(
              title: '罚款缴纳',
              subtitle: '核对个人罚款记录、缴款状态和线上付款码。',
              icon: Icons.credit_card_rounded,
              badge: _currentDriverName ?? '驾驶员',
              accentColor: const Color(0xFF25A7A0),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FineInformation>>(
              future: _finesFuture,
              builder: (context, snapshot) {
                developer.log(
                    'FutureBuilder state: ${snapshot.connectionState}, data: ${snapshot.data}, error: ${snapshot.error}');
                if (_errorMessage.isNotEmpty) {
                  return Center(
                    child: UserBusinessStatusPanel(
                      message: _errorMessage,
                      kind: UserBusinessStatusKind.error,
                      actionLabel: userBusinessMessageNeedsLogin(_errorMessage)
                          ? '重新登录'
                          : null,
                      onAction: userBusinessMessageNeedsLogin(_errorMessage)
                          ? () => NavigationHelper.offAllNamed(Routes.login)
                          : null,
                    ),
                  );
                }
                if (_isLoading ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          themeData.colorScheme.primary),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: UserBusinessStatusPanel(
                      message: '加载罚款信息失败: ${snapshot.error}',
                      kind: UserBusinessStatusKind.error,
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: UserBusinessStatusPanel(
                      message: _currentDriverName != null
                          ? '暂无与驾驶员 $_currentDriverName 匹配的罚款记录'
                          : '未找到驾驶员信息，请重新登录',
                      kind: _currentDriverName != null
                          ? UserBusinessStatusKind.empty
                          : UserBusinessStatusKind.error,
                      actionLabel: _currentDriverName == null ? '重新登录' : null,
                      onAction: _currentDriverName == null
                          ? () => NavigationHelper.offAllNamed(Routes.login)
                          : null,
                    ),
                  );
                } else {
                  final fines = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: _refreshFines,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: fines.length,
                      itemBuilder: (context, index) {
                        final record = fines[index];
                        final amount = record.fineAmount ?? 0.0;
                        final payee = record.payee ?? '未知';
                        final date = record.fineTime ?? '未知';
                        final status = _paymentStatusOf(record);
                        final statusLabel = _paymentStatusLabel(status);
                        return UserBusinessRecordCard(
                          icon: _isPaid(status)
                              ? Icons.check_circle_outline_rounded
                              : Icons.payment_rounded,
                          title: '罚款金额：¥${amount.toStringAsFixed(2)}',
                          badge: statusLabel,
                          accentColor: _isPaid(status)
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF25A7A0),
                          details: [
                            '缴款人：$payee',
                            '罚款时间：$date',
                            '票据编号：${record.receiptNumber ?? '未生成'}',
                          ],
                          onTap: () {
                            _showFineDetailsDialog(record);
                          },
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
    );
  }
}
