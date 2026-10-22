import 'package:final_assignment_front/core/config/app_config.dart';

/// AI 助手身份标识：统一维护助手消息使用的前缀与前缀剥离规则。
///
/// 前缀由后端真实使用的模型推导，避免在界面里硬编码供应商名称。
class AiChatIdentity {
  const AiChatIdentity._();

  /// 模型供应商标识，例如 Ollama。
  static String get provider => AppConfig.aiProvider;

  /// 实际使用的对话模型，例如 llama3.2。
  static String get model => AppConfig.aiChatModel;

  /// 展示给用户的模型标识，例如 "Ollama llama3.2"。
  static String get label {
    final providerName = provider.trim();
    final modelName = model.trim();
    if (providerName.isEmpty) {
      return modelName.isEmpty ? 'AI' : modelName;
    }
    if (modelName.isEmpty) {
      return providerName;
    }
    return '$providerName $modelName';
  }

  /// 助手消息前缀，例如 "Ollama llama3.2: "。
  static String get prefix => '$label: ';

  /// 历史消息里可能残留的旧供应商标识，按新到旧排列。
  static const List<String> legacyLabels = ['DeepSeek'];

  /// 去掉助手消息前缀，兼容历史消息中遗留的旧前缀。
  ///
  /// 剥离后不会残留重复冒号或旧前缀文本。
  static String stripPrefix(String content) {
    var result = content.trim();
    var stripped = true;
    while (stripped) {
      stripped = false;
      for (final marker in _markers()) {
        if (!result.startsWith(marker)) continue;
        result = result.substring(marker.length).trimLeft();
        if (result.startsWith(':')) {
          result = result.substring(1).trimLeft();
        }
        stripped = true;
        break;
      }
    }
    return result;
  }

  static List<String> _markers() {
    return <String>[
      '$label:',
      for (final legacy in legacyLabels) '$legacy:',
    ];
  }
}
