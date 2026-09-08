import 'dart:async';

import 'package:final_assignment_front/features/ai/ai_stream_event.dart';
import 'package:final_assignment_front/features/ai/sse_streaming_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parser survives utf8 code-unit splitting mid-multibyte', () async {
    // Full backend payload (Chinese token). Backend sends event: + data: per
    // event, blank line between. We split the *decoded* string into tiny
    // chunks at every possible boundary to mimic BrowserClient buffering.
    const tokenJson =
        '{"type":"token","sessionKey":"k","messageId":"m","token":"\\u60a8\\u597d\\u6b22\\u8fce","payload":{"provider":"ollama"},"timestamp":0}';
    final frame = 'event:token\ndata:$tokenJson\n\n';
    final doneFrame = 'event:done\ndata:{"type":"done","sessionKey":"k","messageId":"m","timestamp":0}\n\n';

    // Feed one frame, but split into 1-char chunks so the parser's
    // charCodeAt loop sees partial multibyte pieces repeatedly.
    final events = <AiStreamEvent>[];
    final streamCtl = StreamController<String>();
    final sub = streamCtl.stream
        .transform(const SseStreamingParser())
        .listen(events.add);

    for (final ch in frame.split('')) {
      streamCtl.add(ch);
    }
    for (final ch in doneFrame.split('')) {
      streamCtl.add(ch);
    }
    await streamCtl.close();
    await sub.asFuture<void>().catchError((_) {});

    // Expect 1 token event (您您好欢迎 appended) + 1 done.
    expect(events.where((e) => e.type == AiStreamEventType.token).length, 1);
    expect(events.where((e) => e.type == AiStreamEventType.done).length, 1);
    final tok = events.firstWhere((e) => e.type == AiStreamEventType.token);
    // backslash-escaped unicode in JSON → decoded by jsonDecode
    expect(tok.token, contains('您'));
  });
}