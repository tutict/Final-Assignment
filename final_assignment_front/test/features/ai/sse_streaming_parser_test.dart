import 'package:final_assignment_front/features/ai/ai_stream_event.dart';
import 'package:final_assignment_front/features/ai/sse_streaming_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses token event', () async {
    final events = await Stream<String>.fromIterable([
      'event: token\r\n',
      'data: {"type":"token","sessionKey":"s1","messageId":"m1",',
      '"token":"hello","timestamp":"2026-05-07T00:00:00Z"}\r\n\r\n',
    ]).transform(const SseStreamingParser()).toList();

    expect(events, hasLength(1));
    expect(events.single.type, AiStreamEventType.token);
    expect(events.single.rawType, 'token');
    expect(events.single.sessionKey, 's1');
    expect(events.single.messageId, 'm1');
    expect(events.single.token, 'hello');
  });

  test('emits error event for malformed json', () async {
    final events = await Stream<String>.fromIterable([
      'event: token\n',
      'data: {bad-json}\n\n',
    ]).transform(const SseStreamingParser()).toList();

    expect(events, hasLength(1));
    expect(events.single.type, AiStreamEventType.error);
    expect(events.single.rawType, 'token');
    expect(events.single.message, 'Malformed SSE data');
  });

  test('parses keepalive event', () async {
    final events = await Stream<String>.fromIterable([
      'event: keepalive\n',
      'data: {"type":"keepalive"}\n\n',
    ]).transform(const SseStreamingParser()).toList();

    expect(events, hasLength(1));
    expect(events.single.type, AiStreamEventType.keepalive);
  });

  test('parses done event', () async {
    final events = await Stream<String>.fromIterable([
      'event: done\n',
      'data: {"type":"done","sessionKey":"s1","messageId":"m1"}\n\n',
    ]).transform(const SseStreamingParser()).toList();

    expect(events, hasLength(1));
    expect(events.single.type, AiStreamEventType.done);
    expect(events.single.sessionKey, 's1');
    expect(events.single.messageId, 'm1');
  });
}
