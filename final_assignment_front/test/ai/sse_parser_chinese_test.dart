import 'dart:async';

import 'package:final_assignment_front/features/ai/ai_stream_event.dart';
import 'package:final_assignment_front/features/ai/sse_streaming_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates the exact SSE byte stream the Spring backend emits for a
/// Chinese question (from the real probe captured earlier) and verifies
/// the parser yields the expected token + done events.
void main() {
  test('SseStreamingParser yields tokens for backend-style SSE sequence', () async {
    // Exact frames observed from the real backend (event:token + data line
    // separated by blank line, then done event).
    const raw =
        'event:token\ndata:{"type":"token","sessionKey":"k1","messageId":"m1","token":"\\u60a8","payload":{"provider":"ollama"},"timestamp":0}\n\n'
        'event:token\ndata:{"type":"token","sessionKey":"k1","messageId":"m1","token":"\\u597d","payload":{"provider":"ollama"},"timestamp":0}\n\n'
        'event:done\ndata:{"type":"done","sessionKey":"k1","messageId":"m1","timestamp":0}\n\n';

    final events = <AiStreamEvent>[];
    await Stream<String>.fromIterable([raw])
        .transform(const SseStreamingParser())
        .forEach(events.add);

    expect(events.length, 3, reason: '2 tokens + 1 done = 3 events, got $events');
    expect(events[0].type, AiStreamEventType.token);
    expect(events[0].token, '您');
    expect(events[1].type, AiStreamEventType.token);
    expect(events[1].token, '好');
    expect(events[2].type, AiStreamEventType.done);
  });
}