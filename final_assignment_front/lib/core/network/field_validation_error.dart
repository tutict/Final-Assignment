class FieldValidationError {
  const FieldValidationError({
    required this.field,
    required this.message,
  });

  final String field;
  final String message;

  factory FieldValidationError.fromJson(Map<String, dynamic> json) {
    return FieldValidationError(
      field: json['field']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}

