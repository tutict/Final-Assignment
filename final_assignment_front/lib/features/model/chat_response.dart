class ChatResponse {
  final String? message;

  ChatResponse({
    this.message,
  });

  // 根据JSON反序列化，注意要匹配你的后端字段
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      message: json['message'] as String?, // 假设后端返回 { "message": "xxx" }
    );
  }

  // 如果需要序列化回去，可添加 toJson()
  Map<String, dynamic> toJson() {
    return {
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ChatResponse{ message: $message }';
  }
}
