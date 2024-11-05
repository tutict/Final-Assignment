import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('扫一扫'),
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('平台版本: $_platformVersion\n'),
                Text('类型: ${_scanResult?.scanTypeForm ?? '尚未扫描'}\n'),
                Text('内容类型: ${_scanResult?.scanType ?? '尚未扫描'}\n'),
                Text('扫码内容: ${_scanResult?.value ?? '尚未扫描'}\n'),
                ElevatedButton(
                  onPressed: scan,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 100),
                    child: Text("扫描"),
                  ),
                ),
                const SizedBox(height: 50),
                const Text('生成条码\n'),
                if (_code != null)
                  Image.memory(Uint8List.fromList(_code!))
                else
                  const CircularProgressIndicator(),
                // Show progress indicator while generating QR code
                ElevatedButton(
                  onPressed: generateCode,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 100),
                    child: Text("生成条码"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
