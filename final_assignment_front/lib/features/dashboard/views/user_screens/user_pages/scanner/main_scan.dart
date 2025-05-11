import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hms_scan_kit/flutter_hms_scan_kit.dart';
import 'package:flutter_hms_scan_kit/scan_result.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io' show Platform;
import 'package:final_assignment_front/features/model/fine_information.dart'; // Adjust path as needed
import 'dart:developer' as developer;

class MainScan extends StatefulWidget {
  final FineInformation? fine; // Optional fine data for QR code generation
  const MainScan({super.key, this.fine});

  @override
  State<MainScan> createState() => _MainScanState();
}

class _MainScanState extends State<MainScan> {
  String _platformVersion = 'Unknown';
  ScanResult? _scanResult;
  Uint8List? _code;
  bool _isScanning = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
    if (widget.fine != null) {
      _generateCode(); // Generate QR code for fine if provided
    }
  }

  /// Initialize platform state to get HMS Scan Kit version
  Future<void> _initPlatformState() async {
    try {
      final platformVersion =
          await FlutterHmsScanKit.platformVersion ?? 'Unknown platform version';
      if (mounted) {
        setState(() {
          _platformVersion = platformVersion;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _platformVersion = 'Failed to get platform version: $e';
        });
      }
    }
  }

  /// Trigger scan action
  Future<void> _scan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });
    try {
      final result = await FlutterHmsScanKit.scan;
      if (mounted) {
        setState(() {
          _scanResult = result;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _showError('扫描失败: $e');
      }
    }
  }

  /// Generate QR code
  Future<void> _generateCode() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _code = null;
    });

    // Use fine data if provided, otherwise use default content
    final content = widget.fine != null
        ? 'Fine ID: ${widget.fine!.fineId}, Amount: ${widget.fine!.fineAmount}, Payee: ${widget.fine!.payee}'
        : '这是条码';

    try {
      // Check if running on a Huawei device with HMS
      bool isHuaweiDevice =
          Platform.isAndroid ;

      if (isHuaweiDevice) {
        try {
          // Load logo asset
          final bytes = await DefaultAssetBundle.of(context)
              .load('assets/images/ic_logo.jpg');
          final code = await FlutterHmsScanKit.generateCode(
            content: content,
            type: ScanTypeFormat.QRCODE_SCAN_TYPE,
            width: 300,
            height: 300,
            color: '#7CB342',
            logo: bytes.buffer.asUint8List(),
          );
          if (mounted) {
            setState(() {
              _code = code != null ? Uint8List.fromList(code) : null;
              _isGenerating = false;
            });
            developer.log('Generated QR code with HMS Scan Kit');
          }
          return;
        } catch (e) {
          developer.log('HMS Scan Kit failed: $e');
          // Fallback to qr_flutter
        }
      }

      // Fallback to qr_flutter for non-Huawei devices
      final qrWidget = QrImageView(
        data: content,
        version: QrVersions.auto,
        size: 300.0,
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF7CB342),
        embeddedImage: AssetImage('assets/images/ic_logo.jpg'),
        embeddedImageStyle: QrEmbeddedImageStyle(size: Size(60, 60)),
      );

      // Convert QrImageView to image bytes (requires additional setup, e.g., render to image)
      // For simplicity, we'll display the widget directly or save as needed
      setState(() {
        _code =
            null; // Set to null since we're using widget; update if rendering to bytes
        _isGenerating = false;
      });
      developer.log('Generated QR code with qr_flutter');

      // Display QR code in a dialog for non-Huawei devices
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(widget.fine != null
                ? 'Fine QR Code (ID: ${widget.fine!.fineId})'
                : 'QR Code'),
            content: Container(
              width: 300,
              height: 300,
              child: qrWidget,
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('关闭'),
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

  /// Build scan result display
  Widget _buildScanResult() {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '扫描结果',
            style: theme.textTheme.navTitleTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_isScanning)
            const Center(
              child: CupertinoActivityIndicator(radius: 16),
            )
          else if (_scanResult == null)
            Text(
              '尚未扫描',
              style: theme.textTheme.textStyle.copyWith(
                color: theme.textTheme.textStyle.color?.withOpacity(0.6),
                fontSize: 16,
              ),
            )
          else ...[
            _buildResultRow('内容', _scanResult!.value ?? '无', theme),
          ],
        ],
      ),
    );
  }

  /// Build individual result row
  Widget _buildResultRow(String label, String value, CupertinoThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.textStyle.copyWith(fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
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
                : _code != null
                    ? Image.memory(
                        _code!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          '无法加载条码',
                          style: theme.textTheme.textStyle
                              .copyWith(color: CupertinoColors.systemRed),
                        ),
                      )
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
        middle: const Text('扫一扫'),
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
              const SizedBox(height: 16),
              _buildScanResult(),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                onPressed: _isScanning ? null : _scan,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.camera_viewfinder, size: 20),
                    SizedBox(width: 8),
                    Text('扫描'),
                  ],
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
