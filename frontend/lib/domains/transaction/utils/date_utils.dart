class TransactionDateUtils {
  /// 선택된 월의 시작 날짜
  static DateTime getMonthStart(int year, int month) {
    return DateTime(year, month, 1);
  }

  /// 선택된 월의 끝 날짜
  static DateTime getMonthEnd(int year, int month) {
    return DateTime(year, month + 1, 0);
  }

  /// API용 시작 날짜 문자열 (YYYY-MM-DD)
  static String getStartDateString(int year, int month) {
    final start = getMonthStart(year, month);
    return '${start.year}-${start.month.toString().padLeft(2, '0')}-01';
  }

  /// API용 끝 날짜 문자열 (YYYY-MM-DD)
  static String getEndDateString(int year, int month) {
    final end = getMonthEnd(year, month);
    return '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
  }
}