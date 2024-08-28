import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

///http请求
class HttpManager {
  static const contentTypeJson = "application/json";
  static const contentTypeForm = "application/x-www-form-urlencoded";
  static Map<String, String> optionParams = {
    "mirrorToken": "", // Assign a default non-null value
    "content-Type": contentTypeJson
  };

  //请求base url
  //static String baseUrl = "http://10.108.11.46:8080/api";
  static String baseUrl = "https://captcha.anji-plus.com/captcha-api";

  ///发起网络请求
  ///[ url] 请求url
  ///[ param] 请求参数
  ///[ header] 外加头
  ///[ isNeedToken] 是否需要token
  ///[ optionMethod] 请求类型 post、get
  ///[ noTip] 是否需要返回错误信息 默认不需要
  ///[ needSign] 是否需要Sign校验  默认需要
  ///[ needError] 是否需要错误提示
  static Future<dynamic> requestData(
      String url, Map<String, dynamic> param, Map<String, String>? header,
      {bool isNeedToken = true,
      String optionMethod = "post",
      bool noTip = false,
      bool needSign = true,
      bool needError = true}) async {
    //初始化请求类
    Dio dio = Dio();

    //头部
    Map<String, String> headers = HashMap();
    if (header != null) {
      headers.addAll(header);
    }

    //请求协议 post 、get
    Options option = Options(
      method: optionMethod,
      headers: headers,
      sendTimeout: const Duration(seconds: 15),
    );

    var params = param;
    // Uncomment the following lines if you need to use signData
    // if (needSign) {
    //   //获取加密的请求参数
    //   params = await SignConfig.signData(param, "");
    // }

    Response? response; // Declare response as nullable
    debugPrint("$baseUrl$url");
    debugPrint(params as String?);

    try {
      //开始请求
      response =
          await dio.request("$baseUrl$url", data: params, options: option);
    } on DioException catch (e) {
      //请求失败处理
      if (needError) {
        return e.response?.data ??
            e.message; // Return the error response data or message
      }
      return null; // If no error handling is required, return null
    }

    // Ensure response is not null before using it
    try {
      var responseJson = response.data;
      debugPrint(responseJson);

      if (response.statusCode == 200) {
        //请求链接成功
        return responseJson;
      }
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }

    // Handle the case where response is null
    if (needError) {
      return Exception("Request failed and no response received");
    }
    return null;
  }
}
