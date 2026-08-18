import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_chrome.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MainScan extends StatefulWidget {
  final FineInformation? fine;

  const MainScan({super.key, this.fine});

  @override
  State<MainScan> createState() => _MainScanState();
}

class _MainScanState extends State<MainScan> {
  final UserDashboardController dashboardController =
      Get.find<UserDashboardController>();

  bool _isGenerating = false;
  String? _lastGeneratedData;

  @override
  void initState() {
    super.initState();
    if (widget.fine != null) {
      _generateCode();
    }
  }

  Future<void> _generateCode() async {
    if (_isGenerating) return;
    final qrData = widget.fine != null
        ? 'Fine ID: ${widget.fine!.fineId}\nAmount: ${widget.fine!.fineAmount}\nPayee: ${widget.fine!.payee}'
        : '交通违法处理二维码';

    setState(() {
      _isGenerating = true;
    });

    try {
      final qrWidget = QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 280,
        backgroundColor: Colors.white,
        eyeStyle: QrEyeStyle(
          color: dashboardController.currentBodyTheme.value.colorScheme.primary,
        ),
        dataModuleStyle: QrDataModuleStyle(
          color: dashboardController.currentBodyTheme.value.colorScheme.primary,
        ),
        embeddedImage: const AssetImage('assets/images/ic_logo.jpg'),
        embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(48, 48)),
      );

      if (!mounted) return;
      setState(() {
        _lastGeneratedData = qrData;
        _isGenerating = false;
      });

      AppDialog.showCustomDialog(
        context: context,
        title: widget.fine != null ? '罚款二维码' : '二维码',
        content: SizedBox(width: 280, height: 280, child: qrWidget),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      AppSnackbar.showError(context, message: '生成二维码失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = dashboardController.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: theme,
        title: '二维码生成',
        pageType: DashboardPageType.user,
        onThemeToggle: dashboardController.toggleBodyTheme,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.fine != null) ...[
                _buildFineDetails(theme, widget.fine!),
                const SizedBox(height: 16),
              ],
              _buildQrPreview(theme),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateCode,
                icon: const Icon(Icons.qr_code_2_rounded),
                label: Text(_lastGeneratedData == null ? '生成二维码' : '重新生成'),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFineDetails(ThemeData theme, FineInformation fine) {
    final scheme = theme.colorScheme;
    return DashboardPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: scheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Text('罚款详情',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: 0,
                  )),
            ],
          ),
          Divider(
            height: 20,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _buildDetailRow(theme, '罚款编号', fine.fineId?.toString() ?? '--'),
          _buildDetailRow(theme, '罚款金额', '${fine.fineAmount ?? 0} 元'),
          _buildDetailRow(theme, '缴纳对象', fine.payee ?? '--'),
          _buildDetailRow(theme, '缴纳状态', fine.paymentStatus ?? '--'),
        ],
      ),
    );
  }

  Widget _buildQrPreview(ThemeData theme) {
    final scheme = theme.colorScheme;
    return DashboardPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            _lastGeneratedData != null ? '已生成二维码' : '等待生成二维码',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          if (_lastGeneratedData == null)
            Text(
              '尚未生成二维码',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
          else
            Container(
              constraints: const BoxConstraints(maxWidth: 260, maxHeight: 260),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.24)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: _lastGeneratedData!,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(color: scheme.primary),
                dataModuleStyle: QrDataModuleStyle(color: scheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
