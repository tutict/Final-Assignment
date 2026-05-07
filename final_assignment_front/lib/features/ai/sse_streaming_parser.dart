import 'dart:async';
import 'dart:convert';

import 'ai_stream_event.dart';

class SseStreamingParser extends StreamTransformerBase<String, AiStreamEvent> {
  const SseStreamingParser();

  @override
  Stream<AiStreamEvent> bind(Stream<String> stream) {
    late StreamController<AiStreamEvent> controller;
    StreamSubscription<String>? subscription;
    late _SseParseState state;

    controller = StreamController<AiStreamEvent>(
      sync: true,
      onListen: () {
        state = _SseParseState(controller.add);
        subscription = stream.listen(
          state.addChunk,
          onError: controller.addError,
          onDone: () {
            state.close();
            controller.close();
          },
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () => subscription?.cancel(),
    );

    return controller.stream;
  }
}

class _SseParseState {
  _SseParseState(this.emit);

  final void Function(AiStreamEvent event) emit;
  final StringBuffer _lineBuffer = StringBuffer();
  final StringBuffer _dataBuffer = StringBuffer();
  String? _eventName;
  bool _pendingCarriageReturn = false;

  void addChunk(String chunk) {
    for (var index = 0; index < chunk.length; index++) {
      final codeUnit = chunk.codeUnitAt(index);

      if (_pendingCarriageReturn) {
        _pendingCarriageReturn = false;
        if (codeUnit == 10) {
          continue;
        }
      }

      if (codeUnit == 13) {
        _processLine(_lineBuffer.toString());
        _lineBuffer.clear();
        _pendingCarriageReturn = true;
      } else if (codeUnit == 10) {
        _processLine(_lineBuffer.toString());
        _lineBuffer.clear();
      } else {
        _lineBuffer.writeCharCode(codeUnit);
      }
    }
  }

  void close() {
    if (_lineBuffer.isNotEmpty) {
      _processLine(_lineBuffer.toString());
      _lineBuffer.clear();
    }
    _dispatchEvent();
  }

  void _processLine(String line) {
    if (line.isEmpty) {
      _dispatchEvent();
      return;
    }
    if (line.startsWith(':')) {
      return;
    }

    final colonIndex = line.indexOf(':');
    final field = colonIndex == -1 ? line : line.substring(0, colonIndex);
    var value = colonIndex == -1 ? '' : line.substring(colonIndex + 1);
    if (value.startsWith(' ')) {
      value = value.substring(1);
    }

    switch (field) {
      case 'event':
        _eventName = value;
        break;
      case 'data':
        if (_dataBuffer.isNotEmpty) {
          _dataBuffer.write('\n');
        }
        _dataBuffer.write(value);
        break;
      default:
        break;
    }
  }

  void _dispatchEvent() {
    if (_dataBuffer.isEmpty) {
      _eventName = null;
      return;
    }

    final data = _dataBuffer.toString();
    _dataBuffer.clear();

    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        emit(AiStreamEvent.fromJson(decoded, eventName: _eventName));
      } else {
        emit(AiStreamEvent.error('Malformed SSE data', rawType: _eventName));
      }
    } on FormatException {
      emit(AiStreamEvent.error('Malformed SSE data', rawType: _eventName));
    } finally {
      _eventName = null;
    }
  }
}
