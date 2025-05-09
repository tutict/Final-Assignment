import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hms_scan_kit/flutter_hms_scan_kit.dart';
import 'package:flutter_hms_scan_kit/scan_result.dart';

class MainScan extends StatefulWidget {
  const MainScan({super.key});

  @override
  State<MainScan> createState() => _MainScanState();
}

class _MainScanState extends State<MainScan> {
  String _platformVersion = 'Unknown';
  ScanResult? _scanResult;
  List<int>? _code;
  bool _isScanning = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
    _generateCode();
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
    if (_isScanning) return; // Prevent multiple scans
    setState(() {
      _isScanning = true;
      _scanResult = null; // Clear previous result
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
    if (_isGenerating) return; // Prevent multiple generations
    setState(() {
      _isGenerating = true;
      _code = null; // Clear previous QR code
    });
    try {
      final bytes = await rootBundle.load("assets/images/ic_logo.png");
      final code = await FlutterHmsScanKit.generateCode(
        content: "这是条码",
        type: ScanTypeFormat.QRCODE_SCAN_TYPE,
        width: 300,
        height: 300,
        color: "#7CB342",
        logo: bytes.buffer.asUint8List(),
      );
      if (mounted) {
        setState(() {
          _code = code;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showError('生成条码失败: $e');
      }
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
            '生成条码',
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
                        Uint8List.fromList(_code!),
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
              // Platform version
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
              // Scan result section
              _buildScanResult(),
              const SizedBox(height: 16),
              // Scan button
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
              // QR code section
              _buildQrCode(),
              const SizedBox(height: 16),
              // Generate QR code button
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
