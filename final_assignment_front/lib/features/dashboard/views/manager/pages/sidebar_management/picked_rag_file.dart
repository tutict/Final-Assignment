import 'dart:typed_data';

class PickedRagFile {
  const PickedRagFile({
    required this.name,
    required this.bytes,
    required this.size,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final int size;
  final String contentType;

  String get title {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
