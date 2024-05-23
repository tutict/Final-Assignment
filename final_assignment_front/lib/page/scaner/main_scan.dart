import 'package:flutter_hms_scan_kit/flutter_hms_scan_kit.dart';
import 'package:flutter_hms_scan_kit/scan_result.dart';

///扫码
ScanResult? _scanResult;
///方式一
Future<void> scan() async {
  _scanResult = await FlutterHmsScanKit.scan;
  setState(() {});
}
///方式二
Future<void> scan() async {
  _scanResult = await FlutterHmsScanKit.startScan();
  setState(() {});
}

///扫码结果
class ScanResult {
  /// 扫码结果信息
  ScanType? scanType;
  /// 条码内容类型
  ScanTypeFormat? scanTypeForm;
  /// 获取条码原始的全部码值信息。只有当条码编码格式为UTF-8时才可以使用
  String? value;
  /// 非UTF-8格式的条码使用
  List<int>? valueByte;
}

///生成条码
Future<void> generateCode() async {
  var bytes = await rootBundle.load("assets/images/ic_logo.png");
  _code = await FlutterHmsScanKit.generateCode(
    content: "这是条码",
    type: ScanType.QRCODE_SCAN_TYPE,
    width: 300,
    height: 300,
    color: "#7CB342",
    logo: bytes.buffer.asUint8List(),
  );
  setState(() {});
}