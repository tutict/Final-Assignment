part of 'app_mixins.dart';

/// 用于所有表单字段的验证逻辑。
/// 包含方法以验证文本字段和下拉菜单，确保它们不为空。
mixin ValidatorMixin {
  String? validateTextFieldIsRequired(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return "此字段是必填项";
    }
    return null;
  }

// String? validateDropdownIsRequired(String? value) {
//   if (value == null || value.trim().isEmpty) return "请选择项目";
//   return null;
// }
}

/// [ValidationInputMixin] 定义输入验证相关的功能。
/// 实现该混入的类可以调用相关输入验证方法。
mixin ValidationInputMixin {
  /// 验证电子邮件格式的方法。
  bool validateEmail(String email) {
    // 简单示例验证逻辑，可以根据需要进行增强。
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$');
    return emailRegex.hasMatch(email);
  }
}