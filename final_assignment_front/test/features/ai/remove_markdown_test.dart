import 'package:final_assignment_front/features/api/chat_controller_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ChatControllerApi api;

  setUp(() {
    api = ChatControllerApi();
  });

  group('removeMarkdown 保留词间空格', () {
    test('流式 token 不应被裁剪首尾空白', () {
      expect(api.removeMarkdown(' I', trim: false), ' I');
      expect(api.removeMarkdown(" couldn't", trim: false), " couldn't");
      expect(api.removeMarkdown(' ', trim: false), ' ');
    });

    test('整段文本仍按需裁剪首尾空白', () {
      expect(api.removeMarkdown('  hello  '), 'hello');
    });

    test('按 token 拼接后英文单词之间保留空格', () {
      const tokens = ['I', " couldn't", ' find', ' any', ' information', ' today', '.'];
      final merged = tokens.map((t) => api.removeMarkdown(t, trim: false)).join();
      expect(merged, "I couldn't find any information today.");
    });
  });

  group('removeMarkdown 不误伤正文符号', () {
    test('保留日期中的连字符', () {
      expect(api.removeMarkdown('2026-10-22 的记录'), '2026-10-22 的记录');
    });

    test('保留带连字符的词', () {
      expect(api.removeMarkdown('e-mail 与 well-known 都保留'), 'e-mail 与 well-known 都保留');
    });

    test('保留 snake_case 标识符', () {
      expect(api.removeMarkdown('字段 order_id 不变'), '字段 order_id 不变');
    });

    test('保留乘法与破折号', () {
      expect(api.removeMarkdown('2 * 3 = 6'), '2 * 3 = 6');
    });
  });

  group('removeMarkdown 仍剥离展示型标记', () {
    test('剥离加粗', () {
      expect(api.removeMarkdown('**重点**'), '重点');
    });

    test('剥离斜体', () {
      expect(api.removeMarkdown('*重点*'), '重点');
      expect(api.removeMarkdown('_重点_'), '重点');
    });

    test('剥离行首标题与列表符号', () {
      expect(api.removeMarkdown('## 标题\n正文'), '标题\n正文');
      expect(api.removeMarkdown('- 第一项\n- 第二项'), '第一项\n第二项');
    });

    test('保留 think 语义占位', () {
      expect(api.removeMarkdown('<think>推理</think>结论'), '[THINK]推理[/THINK]结论');
    });
  });

  group('removeMarkdown 处理跨分片的标记', () {
    test('加粗标记被拆到两个 token 时，逐片清洗无法命中', () {
      const tokens = ['1. **', '检查政府网站', '**'];
      final perToken = tokens.map((t) => api.removeMarkdown(t, trim: false)).join();
      expect(perToken, contains('**'), reason: '逐片清洗会留下残余标记');
    });

    test('累计文本整体清洗可去掉跨分片的加粗标记', () {
      const tokens = ['1. **', '检查政府网站', '**'];
      final perToken = tokens.map((t) => api.removeMarkdown(t, trim: false)).join();
      expect(api.removeMarkdown(perToken), '1. 检查政府网站');
    });

    test('累计文本整体清洗可去掉跨分片的斜体标记', () {
      const tokens = ['*斜', '体*'];
      final perToken = tokens.map((t) => api.removeMarkdown(t, trim: false)).join();
      expect(api.removeMarkdown(perToken), '斜体');
    });

    test('整体清洗不会误伤被逐片清洗保留的正文符号', () {
      const tokens = ['2 ', '*', ' 3 = 6'];
      final perToken = tokens.map((t) => api.removeMarkdown(t, trim: false)).join();
      expect(api.removeMarkdown(perToken), '2 * 3 = 6');
    });
  });
}
