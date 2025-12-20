import 'package:intl/intl.dart';        // 숫자, 날짜를 국가별 포맷으로 변환하는 플러그인

// ========== 통화 포맷팅 유틸리티 ==========
class CurrencyFormatter {
  /// NumberFormat 인스턴스 (정적 공유 객체)
  static final NumberFormat _formatter = NumberFormat('#,###', 'ko_KR'); // 3자리마다 콤마, 한국 로케일 기준

  /// 금액을 포맷팅합니다.
  /// 예: 10000 -> "10,000"
  static String format(int amount) {
    return _formatter.format(amount);
  }

  /// 금액을 "원" 단위와 함께 포맷팅합니다.
  /// 예: 10000 -> "10,000원"
  static String formatWithCurrency(int amount) {
    return '${format(amount)}원';
  }

  /// 금액을 '원' 단위와 부호와 함께 포맷팅합니다.
  /// 예: -10000 -> "-10,000원", 10000 -> "+10,000원"
  static String formatWithSign(int amount) {
    final sign = amount < 0 ? '-' : '+';
    return '$sign${formatWithCurrency(amount.abs())}';
  }
}