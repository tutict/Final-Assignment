import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class SignConfig {


  static String generateMd5(String data){
    var content = const Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  static signData( Object params, tokenStr) async{
    var time = DateTime.now().millisecondsSinceEpoch;
    String token = tokenStr;
    Map<String , dynamic> reqData = {};
    Map<String , dynamic>? paramsObj = {};
    paramsObj = params as Map<String, dynamic>?;
    var arr = [];
    //将字典转成数组
    paramsObj?.forEach((key,value)=>  arr.add(key));
    //进行签名校验
    Map cr = {};
    cr['token'] = token;
    cr['time'] = time.toString();
    cr['reqData'] = json.encode(paramsObj);
    var array = [];
    cr.forEach((key,value) => array.add(key));
    array.sort();
    var str = '';
    for (var i = 0; i < array.length; i++) {
      var key = array[i];
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