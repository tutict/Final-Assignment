class DateFormatter {
  DateFormatter._();

  /// LocalDate fields -> yyyy-MM-dd.
  static String formatLocalDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  /// LocalDateTime fields -> yyyy-MM-ddTHH:mm:ss without timezone.
  static String formatLocalDateTime(DateTime dt) => '${formatLocalDate(dt)}T'
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}
