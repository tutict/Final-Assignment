import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class SignConfig {
  static String generateMd5(String data) {
    var content = const Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  static Future<Map<String, dynamic>> signData(
      Map<String, dynamic> params, String tokenStr) async {
    var time = DateTime.now().millisecondsSinceEpoch;
    String token = tokenStr;
    Map<String, dynamic> reqData = {};
    Map<String, dynamic> paramsObj = params;

    //进行签名校验
    Map<String, dynamic> cr = {};
    cr['token'] = token;
    cr['time'] = time.toString();
    cr['reqData'] = json.encode(paramsObj);

    var array = cr.keys.toList();
    array.sort();

    var str = '';
    for (var key in array) {
      var value = cr[key];
      str += key + value;
    }

    reqData["time"] = time;
    reqData["token"] = token;
    reqData['reqData'] = params;
    reqData['sign'] = generateMd5(str);

    return reqData;
  }
}
