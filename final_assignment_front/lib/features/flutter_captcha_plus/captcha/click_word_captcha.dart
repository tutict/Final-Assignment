import 'dart:convert';
import 'dart:async';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:steel_crypt/steel_crypt.dart';

typedef VoidSuccessCallback = dynamic Function(String v);

class ClickWordCaptcha extends StatefulWidget {
  final VoidSuccessCallback onSuccess;
  final VoidCallback onFail;

  const ClickWordCaptcha({
    super.key,
    required this.onSuccess,
    required this.onFail,
  });

  @override
  _ClickWordCaptchaState createState() => _ClickWordCaptchaState();
}

class _ClickWordCaptchaState extends State<ClickWordCaptcha> {
  ClickWordCaptchaStateEnum _clickWordCaptchaState = ClickWordCaptchaStateEnum.none;
  List<Offset> _tapOffsetList = [];
  ClickWordCaptchaModel _clickWordCaptchaModel = ClickWordCaptchaModel();

  Color titleColor = Colors.black;
  Color borderColor = const Color(0xffdddddd);
  String bottomTitle = "";
  Size baseSize = const Size(310.0, 155.0);

  //改变底部样式及字段
  _changeResultState() {
    switch (_clickWordCaptchaState) {
      case ClickWordCaptchaStateEnum.normal:
        titleColor = Colors.black;
        borderColor = const Color(0xffdddddd);
        break;
      case ClickWordCaptchaStateEnum.success:
        _tapOffsetList = [];
        titleColor = Colors.green;
        borderColor = Colors.green;
        bottomTitle = "验证成功";
        break;
      case ClickWordCaptchaStateEnum.fail:
        _tapOffsetList = [];
        titleColor = Colors.red;
        borderColor = Colors.red;
        bottomTitle = "验证失败";
        break;
      default:
        titleColor = Colors.black;
        borderColor = const Color(0xffdddddd);
        bottomTitle = "数据加载中……";
        break;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  //加载验证码
  _loadCaptcha() async {
    _tapOffsetList = [];
    _clickWordCaptchaState = ClickWordCaptchaStateEnum.none;
    _changeResultState();
    var res = await HttpManager.requestData(
        '/captcha/get', {"captchaType": "clickWord"}, {});
    if (res['repCode'] != '0000' || res['repData'] == null) {
      _clickWordCaptchaModel.secretKey = "";
      bottomTitle = "加载失败,请刷新";
      _clickWordCaptchaState = ClickWordCaptchaStateEnum.normal;
      _changeResultState();
      return;
    } else {
      Map<String, dynamic> repData = res['repData'];
      _clickWordCaptchaModel = ClickWordCaptchaModel.fromMap(repData);

      var baseR = await WidgetUtil.getImageWH(
          image: Image.memory(
              const Base64Decoder().convert(_clickWordCaptchaModel.imgStr)));
      baseSize = baseR;

      bottomTitle = "请依次点击【${_clickWordCaptchaModel.wordStr}】";
    }

    _clickWordCaptchaState = ClickWordCaptchaStateEnum.normal;
    _changeResultState();
  }

  //校验验证码
  _checkCaptcha() async {
    List<Map<String, dynamic>> mousePos = [];
    _tapOffsetList.map((size) {
      mousePos
          .add({"x": size.dx.roundToDouble(), "y": size.dy.roundToDouble()});
    }).toList();
    var pointStr = json.encode(mousePos);

    var cryptedStr = pointStr;

    // secretKey 不为空 进行AES加密
    if (_clickWordCaptchaModel.secretKey.isNotEmpty) {
      var aesEncrypter = AesCrypt(
        key: _clickWordCaptchaModel.secretKey,
        padding: PaddingAES.pkcs7,
      );
      cryptedStr = aesEncrypter.gcm.encrypt(inp: pointStr, iv: '');
    }

    var res = await HttpManager.requestData('/captcha/check', {
      "pointJson": cryptedStr,
      "captchaType": "clickWord",
      "token": _clickWordCaptchaModel.token
    }, {});
    if (res['repCode'] != '0000' || res['repData'] == null) {
      _checkFail();
      return;
    }
    Map<String, dynamic> repData = res['repData'];
    if (repData["result"] != null && repData["result"] == true) {
      var captchaVerification = "${_clickWordCaptchaModel.token}---$pointStr";
      if (_clickWordCaptchaModel.secretKey.isNotEmpty) {
        captchaVerification = EncryptUtil.aesEncode(
            key: _clickWordCaptchaModel.secretKey,
            content: captchaVerification);
      }
      _checkSuccess(captchaVerification);
    } else {
      _checkFail();
    }
  }

  //校验失败
  _checkFail() async {
    _clickWordCaptchaState = ClickWordCaptchaStateEnum.fail;
    _changeResultState();

    await Future.delayed(const Duration(milliseconds: 1000));
    _loadCaptcha();
    //回调
    widget.onFail();
  }

  //校验成功
  _checkSuccess(String pointJson) async {
    _clickWordCaptchaState = ClickWordCaptchaStateEnum.success;
    _changeResultState();

    await Future.delayed(const Duration(milliseconds: 1000));

    var aesEncrypter = AesCrypt(
      key: 'BGxdEUOZkXka4HSj',
      padding: PaddingAES.pkcs7,
    );
    var cryptedStr = aesEncrypter.gcm.encrypt(inp: pointJson, iv: '');

    print(cryptedStr);
    //回调 pointJson 是经过AES加密之后的信息
    widget.onSuccess(cryptedStr);
    //关闭
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    var data = MediaQuery.of(context);
    var dialogWidth = 0.9 * data.size.width;
    if (dialogWidth < 320.0) {
      dialogWidth = data.size.width;
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: dialogWidth,
          height: 320,
          color: Colors.white,
          child: Column(
            children: <Widget>[
              _topContainer(),
              _captchaContainer(),
              _bottomContainer()
            ],
          ),
        ),
      ),
    );
  }

  //图片验证码
  _captchaContainer() {
    List<Widget> widgetList = [];
    if (_clickWordCaptchaModel.imgStr.isNotEmpty) {
      widgetList.add(Image(
          width: baseSize.width,
          height: baseSize.height,
          gaplessPlayback: true,
          image: MemoryImage(
              const Base64Decoder().convert(_clickWordCaptchaModel.imgStr))));
    }

    double widgetW = 20;
    for (int i = 0; i < _tapOffsetList.length; i++) {
      Offset offset = _tapOffsetList[i];
      widgetList.add(Positioned(
          left: offset.dx - widgetW * 0.5,
          top: offset.dy - widgetW * 0.5,
          child: Container(
            alignment: Alignment.center,
            width: widgetW,
            height: widgetW,
            decoration: BoxDecoration(
                color: const Color(0xCC43A047),
                borderRadius: BorderRadius.all(Radius.circular(widgetW))),
            child: Text(
              "${i + 1}",
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          )));
    }
    widgetList.add(
      Positioned(
        top: 0,
        right: 0,
        child: IconButton(
            icon: const Icon(Icons.refresh),
            iconSize: 30,
            color: Colors.deepOrangeAccent,
            onPressed: () {
              //刷新
              _loadCaptcha();
            }),
      ),
    );

    return GestureDetector(
        onTapDown: (TapDownDetails details) {
          debugPrint(
              "onTapDown globalPosition全局坐标系位置:  ${details.globalPosition} localPosition组件坐标系位置: ${details.localPosition} ");
          if (_clickWordCaptchaModel.wordList.isNotEmpty &&
              _tapOffsetList.length < _clickWordCaptchaModel.wordList.length) {
            _tapOffsetList.add(
                Offset(details.localPosition.dx, details.localPosition.dy));
          }
          setState(() {});
          if (_clickWordCaptchaModel.wordList.isNotEmpty &&
              _tapOffsetList.length == _clickWordCaptchaModel.wordList.length) {
            _checkCaptcha();
          }
        },
        child: SizedBox(
          width: baseSize.width,
          height: baseSize.height,
          child: Stack(
            children: widgetList,
          ),
        ));
  }

  //底部按钮
  _bottomContainer() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      alignment: Alignment.center,
      width: baseSize.width,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          border: Border.all(color: borderColor)),
      child: Text(bottomTitle, style: TextStyle(fontSize: 18, color: titleColor).useSystemChineseFont()),
    );
  }

  //顶部，提示+关闭
  _topContainer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      margin: const EdgeInsets.only(bottom: 20, top: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 1, color: Color(0xffe5e5e5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Text(
            '请完成安全验证',
            style: TextStyle(fontSize: 18),
          ),
          IconButton(
              icon: const Icon(Icons.highlight_off),
              iconSize: 35,
              color: Colors.black54,
              onPressed: () {
                //退出
                Navigator.pop(context);
              }),
        ],
      ),
    );
  }
}

//校验状态
enum ClickWordCaptchaStateEnum {
  normal, //默认 可自定义描述
  success, //成功
  fail, //失败
  none, //无状态  用于加载使用
}

//请求数据模型
class ClickWordCaptchaModel {
  String imgStr; //图表url 目前用base64 data
  String token; // 获取的token 用于校验
  List wordList; //显示需要点选的字
  String wordStr; //显示需要点选的字转换为字符串
  String secretKey; //加密key

  ClickWordCaptchaModel({
    this.imgStr = "",
    this.token = "",
    this.secretKey = "",
    this.wordList = const [],
    this.wordStr = "",
  });

  //解析数据转换模型
  static ClickWordCaptchaModel fromMap(Map<String, dynamic> map) {
    ClickWordCaptchaModel captchaModel = ClickWordCaptchaModel();
    captchaModel.imgStr = map["originalImageBase64"] ?? "";
    captchaModel.token = map["token"] ?? "";
    captchaModel.secretKey = map["secretKey"] ?? "";
    captchaModel.wordList = map["wordList"] ?? [];

    if (captchaModel.wordList.isNotEmpty) {
      captchaModel.wordStr = captchaModel.wordList.join(",");
    }

    return captchaModel;
  }

  //将模型转换
  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['imgStr'] = imgStr;
    map['token'] = token;
    map['secretKey'] = secretKey;
    map['wordList'] = wordList;
    map['wordStr'] = wordStr;
    return map;
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class HttpManager {
  static Future<Map<String, dynamic>> requestData(
      String endpoint, Map<String, dynamic> params, Map<String, dynamic> headers) async {
    // Implement the HTTP request logic here
    // This is a placeholder function, replace it with your actual HTTP request implementation
    return {
      'repCode': '0000',
      'repData': {
        "originalImageBase64": "base64encodedimage",
        "token": "sometoken",
        "secretKey": "somesecretkey",
        "wordList": ["word1", "word2"]
      }
    };
  }
}

class WidgetUtil {
  static Future<Size> getImageWH({required Image image}) async {
    Completer<Size> completer = Completer();
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        var myImage = info.image;
        Size size = Size(myImage.width.toDouble(), myImage.height.toDouble());
        completer.complete(size);
      }),
    );
    return completer.future;
  }
}

class EncryptUtil {
  static String aesEncode({required String key, required String content}) {
    var aesEncrypter = AesCrypt(
      key: key,
      padding: PaddingAES.pkcs7,
    );
    return aesEncrypter.gcm.encrypt(inp: content, iv: '');
  }
}
