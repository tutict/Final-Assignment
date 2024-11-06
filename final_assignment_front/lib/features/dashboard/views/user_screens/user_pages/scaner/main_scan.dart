import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    initPlatformState();
    generateCode();
  }

  // Initialize platform state
  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await FlutterHmsScanKit.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  // Trigger scan action
  Future<void> scan() async {
    try {
      _scanResult = await FlutterHmsScanKit.scan;
      setState(() {});
    } catch (e) {
      debugPrint('Scan failed: $e');
    }
  }

  // Generate QR code
  Future<void> generateCode() async {
    try {
      var bytes = await rootBundle.load("assets/images/ic_logo.png");
      _code = await FlutterHmsScanKit.generateCode(
        content: "这是条码",
        type: ScanTypeFormat.QRCODE_SCAN_TYPE,
        width: 300,
        height: 300,
        color: "#7CB342",
        logo: bytes.buffer.asUint8List(),
      );
      setState(() {});
    } catch (e) {
      debugPrint('Failed to generate QR code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('扫一扫'),
        backgroundColor: CupertinoColors.systemBlue,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('平台版本: $_platformVersion',
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .copyWith(fontSize: 16)),
              const SizedBox(height: 20),
              Text('类型: ${_scanResult?.scanTypeForm ?? '尚未扫描'}',
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Text('内容类型: ${_scanResult?.scanType ?? '尚未扫描'}',
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Text('扫码内容: ${_scanResult?.value ?? '尚未扫描'}',
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .copyWith(fontSize: 16)),
              const SizedBox(height: 30),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                onPressed: scan,
                child: const Text("扫描"),
              ),
              const SizedBox(height: 40),
              const Text('生成条码',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (_code != null)
                Image.memory(Uint8List.fromList(_code!))
              else
                const CupertinoActivityIndicator(),
              const SizedBox(height: 20),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                onPressed: generateCode,
                child: const Text("生成条码"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
