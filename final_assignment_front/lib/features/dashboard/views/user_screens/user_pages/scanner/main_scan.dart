import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'dart:developer' as developer;

class MainScan extends StatefulWidget {
  final FineInformation? fine;

  const MainScan({super.key, this.fine});

  @override
  State<MainScan> createState() => _MainScanState();
}

class _MainScanState extends State<MainScan> {
  String _platformVersion = 'Unknown';
  bool _isGenerating = false;
  Widget? _qrWidget;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
    if (widget.fine != null) {
      _generateCode(); // Generate QR code for fine if provided
    }
  }

  /// Initialize platform state (optional, retained for compatibility)
  Future<void> _initPlatformState() async {
    setState(() {
      _platformVersion = 'Flutter QR Code Generator';
    });
  }

  /// Generate QR code using qr_flutter
  Future<void> _generateCode() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _qrWidget = null;
    });

    // Use fine data if provided, otherwise use default content
    final content = widget.fine != null
        ? 'Fine ID: ${widget.fine!.fineId}, Amount: ${widget.fine!.fineAmount}, Payee: ${widget.fine!.payee}'
        : '这是条码';

    try {
      final qrWidget = QrImageView(
        data: content,
        version: QrVersions.auto,
        size: 300.0,
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color(0xFF7CB342),
        embeddedImage: const AssetImage('assets/images/ic_logo.jpg'),
        embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(60, 60)),
      );

      if (mounted) {
        setState(() {
          _qrWidget = qrWidget;
          _isGenerating = false;
        });
        developer.log('Generated QR code with qr_flutter');

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(widget.fine != null
                ? 'Fine QR Code (ID: ${widget.fine!.fineId})'
                : 'QR Code'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: qrWidget,
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('关闭'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showError('生成条码失败: $e');
      }
      developer.log('QR code generation error: $e');
    }
  }

  /// Show error message via Cupertino dialog
  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Build QR code display
  Widget _buildQrCode() {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.fine != null ? '罚款条码 (ID: ${widget.fine!.fineId})' : '生成条码',
            style: theme.textTheme.navTitleTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
            child: _isGenerating
                ? const Center(child: CupertinoActivityIndicator(radius: 16))
                : _qrWidget != null
                    ? _qrWidget!
                    : Text(
                        '尚未生成条码',
                        style: theme.textTheme.textStyle.copyWith(
                          color:
                              theme.textTheme.textStyle.color?.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('二维码生成'),
        backgroundColor: theme.primaryColor,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.barBackgroundColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '平台版本: $_platformVersion',
                  style: theme.textTheme.textStyle.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              _buildQrCode(),
              const SizedBox(height: 16),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                color: theme.primaryColor,
                onPressed: _isGenerating ? null : _generateCode,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.qrcode, size: 20),
                    SizedBox(width: 8),
                    Text('生成条码'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
