import 'package:final_assignment_front/features/ai/ai_chat_identity.dart';
import 'package:flutter_test/flutter_test.dart';

/// AI 助手前缀必须来自后端真实使用的模型，不能硬编码供应商名称。
void main() {
  test('前缀由配置推导且不是历史供应商标识', () {
    expect(AiChatIdentity.label, 'Ollama llama3.2');
    expect(AiChatIdentity.prefix, 'Ollama llama3.2: ');
    expect(AiChatIdentity.prefix, isNot(contains('DeepSeek')));
  });

  test('剥离前缀后不残留冒号或旧标识', () {
    expect(
      AiChatIdentity.stripPrefix('Ollama llama3.2: 查询待处理的罚款'),
      '查询待处理的罚款',
    );
    expect(
      AiChatIdentity.stripPrefix('DeepSeek: 查询待处理的罚款'),
      '查询待处理的罚款',
    );
    expect(AiChatIdentity.stripPrefix('没有前缀的正文'), '没有前缀的正文');
  });
}
