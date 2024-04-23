import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> getFormattedAddress(double latitude, double longitude) async {
  // 替换为你的后端服务地址
  String baseUrl = "http://your-backend-service.com/geocode";
  String url = '$baseUrl?latitude=$latitude&longitude=$longitude';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // 解析JSON响应
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // 检查高德地图返回的状态码
      if (jsonResponse['infocode'] == 10000) {
        return jsonResponse['regeocode']['addressComponent']['formattedAddress'];
      } else {
        throw Exception('Geocode error: ' + jsonResponse['info']);
      }
    } else {
      throw Exception('Failed to load address.');
    }
  } catch (error) {
    print(error);
    return "Error loading address";
  }
}

// 使用示例
void main() async {
  double latitude = 39.9289; // 示例纬度
  double longitude = 116.3883; // 示例经度

  String address = await getFormatted(latitude, longitude);
  print(address);
}