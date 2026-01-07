import 'package:final_assignment_front/features/dashboard/views/user/user_dashboard.dart';
import 'package:final_assignment_front/features/dashboard/views/user/widgets/user_page_app_bar.dart';
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
      _generateCode(); // auto-generate when fine provided
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
      final themeData = dashboardController.currentBodyTheme.value;
      return Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: UserPageAppBar(
          theme: themeData,
          title: '二维码生成',
          onThemeToggle: dashboardController.toggleBodyTheme,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.fine != null) _buildFineCard(themeData, widget.fine!),
              const SizedBox(height: 16),
              _buildQrPreview(themeData),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateCode,
                icon: const Icon(Icons.qr_code),
                label: Text(_lastGeneratedData == null ? '生成二维码' : '重新生成'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFineCard(ThemeData theme, FineInformation fine) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('罚款详情',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                )),
            const Divider(),
            _buildDetailRow(theme, '罚款编号', fine.fineId?.toString() ?? '--'),
            _buildDetailRow(theme, '罚款金额', '${fine.fineAmount ?? 0} 元'),
            _buildDetailRow(theme, '缴纳对象', fine.payee ?? '--'),
            _buildDetailRow(theme, '缴纳状态', fine.paymentStatus ?? '--'),
          ],
        ),
      ),
    );
  }

  Widget _buildQrPreview(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final qrText = _lastGeneratedData ?? '尚未生成二维码';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _lastGeneratedData != null ? '已生成二维码' : '等待生成二维码',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_lastGeneratedData == null)
              Text(
                qrText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            if (_lastGeneratedData != null)
              Container(
                constraints:
                    const BoxConstraints(maxWidth: 260, maxHeight: 260),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: _lastGeneratedData!,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(color: colorScheme.primary),
                  dataModuleStyle: QrDataModuleStyle(color: colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
