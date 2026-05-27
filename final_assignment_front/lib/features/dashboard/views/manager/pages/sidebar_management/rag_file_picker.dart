import 'rag_file_picker_stub.dart'
    if (dart.library.js_interop) 'rag_file_picker_web.dart' as impl;

export 'picked_rag_file.dart';
import 'picked_rag_file.dart';

Future<PickedRagFile?> pickRagFile() => impl.pickRagFile();
