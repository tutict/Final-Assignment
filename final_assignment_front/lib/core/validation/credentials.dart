/// Minimum password length shared by login, registration, and reset flows.
/// Keep in sync with the backend password policy.
const int kMinPasswordLength = 5;

const String _kEmailEmptyMessage = '用户邮箱不能为空';
const String _kEmailInvalidMessage = '请输入有效的邮箱地址';
const String _kPasswordEmptyMessage = '密码不能为空';
final String kPasswordTooShortMessage = '密码至少 $kMinPasswordLength 位';

/// Validates an email address used as the login identifier.
/// Returns `null` when valid, otherwise a localized error message.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return _kEmailEmptyMessage;
  final emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(value.trim())) return _kEmailInvalidMessage;
  return null;
}

/// Validates a password against the shared minimum-length policy.
/// Returns `null` when valid, otherwise a localized error message.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return _kPasswordEmptyMessage;
  if (value.length < kMinPasswordLength) return kPasswordTooShortMessage;
  return null;
}
