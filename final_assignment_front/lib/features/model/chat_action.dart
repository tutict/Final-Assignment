class ChatAction {
  final String? type;
  final String? label;
  final String? target;
  final String? value;

  ChatAction({
    this.type,
    this.label,
    this.target,
    this.value,
  });

  factory ChatAction.fromJson(Map<String, dynamic> json) {
    return ChatAction(
      type: json['type'] as String?,
      label: json['label'] as String?,
      target: json['target'] as String?,
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'label': label,
      'target': target,
      'value': value,
    };
  }

  @override
  String toString() {
    return 'ChatAction{ type: $type, label: $label, target: $target, value: $value }';
  }
}
