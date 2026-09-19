import 'package:final_assignment_front/features/ai/business_chat_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const agent = BusinessChatAgent();

  test('user FAQ keywords still resolve to navigation actions', () {
    const questions = [
      '如何查询我的交通违法记录？',
      '罚款缴纳流程是什么？',
      '交通违法申诉需要哪些材料？',
    ];
    for (final question in questions) {
      final result = agent.resolve(message: question, role: 'USER');
      expect(result, isNotNull, reason: question);
      expect(result!.actions, isNotEmpty, reason: question);
    }
  });

  test('unrelated user questions do not short-circuit to local actions', () {
    final result = agent.resolve(message: '今天天气怎么样？', role: 'USER');
    expect(result, isNull);
  });
}
