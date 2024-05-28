import 'package:encrypt/encrypt.dart';

class EncryptUtil {
  final Key key;
  final Encrypter _encrypter;
  final IV iv; // Initialization vector

  EncryptUtil(String key)
      : key = Key.fromUtf8(key),
        _encrypter = Encrypter(AES(Key.fromUtf8(key))),
        iv = IV.fromLength(16); // AES needs a 16 bytes IV

  /// AES 加密
  /// [content] 需要加密的内容字符串
  String aesEncode(String content) {
    final encrypted = _encrypter.encrypt(content, iv: iv);
    return encrypted.base64;
  }

  /// AES 解密
  /// [contentBase64] 需要解密的 base64 编码的字符串
  String aesDecode(String contentBase64) {
    try {
      final encrypted = Encrypted.fromBase64(contentBase64);
      final decrypted = _encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      print(e);
      return '';
    }
  }
}
