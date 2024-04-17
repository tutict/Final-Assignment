import 'dart:convert';

class ObjectUtils {
  /// isEmpty.
  static bool isEmpty(Object value) {
    if (value is String && value.isEmpty) {
      return true;
    }
    return false;
  }

  //list length == 0  || list == null
  static bool isListEmpty(Object value) {
    if (value is List && value.isEmpty) {
      return true;
    }
    return false;
  }

  static String jsonFormat(Map<dynamic, dynamic> map) {
    Map _map = Map<String, Object>.from(map);
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(_map);
  }
}