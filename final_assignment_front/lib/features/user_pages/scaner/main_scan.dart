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

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await FlutterHmsScanKit.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> scan() async {
    _scanResult = await FlutterHmsScanKit.scan;
    setState(() {});
  }

  Future<void> generateCode() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('扫一扫'),
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('平台版本: $_platformVersion\n'),
                Text('类型: ${_scanResult?.scanTypeForm}\n'),
                Text('内容类型: ${_scanResult?.scanType}\n'),
                Text('扫码内容: ${_scanResult?.value}\n'),
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
                  Container(height: 300, color: Colors.transparent),
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
