import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'picked_rag_file.dart';

Future<PickedRagFile?> pickRagFile() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.txt,.md,.markdown,.csv,.tsv,.json,.docx,.xlsx,.pdf';
  final completer = Completer<PickedRagFile?>();
  late StreamSubscription<web.Event> subscription;
  subscription = input.onChange.listen((_) async {
    try {
      await subscription.cancel();
      final files = input.files;
      if (files == null || files.length == 0) {
        completer.complete(null);
        return;
      }
      final file = files.item(0);
      if (file == null) {
        completer.complete(null);
        return;
      }
      final buffer = await file.arrayBuffer().toDart;
      final bytes = Uint8List.fromList(buffer.toDart.asUint8List());
      completer.complete(PickedRagFile(
        name: file.name,
        bytes: bytes,
        size: file.size,
        contentType: file.type,
      ));
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  });
  input.click();
  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () async {
      await subscription.cancel();
      return null;
    },
  );
}
