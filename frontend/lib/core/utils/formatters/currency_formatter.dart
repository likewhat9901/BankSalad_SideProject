import 'package:intl/intl.dart';

/// 통화 포맷팅 유틸리티
/// 프로젝트 전역에서 사용하는 통화 포맷팅을 중앙화합니다.
class CurrencyFormatter {
  // 싱글톤 패턴으로 NumberFormat 인스턴스 재사용
  static final NumberFormat _formatter = NumberFormat('#,###', 'ko_KR');

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

  /// 금액을 부호와 함께 포맷팅합니다.
  /// 예: -10000 -> "-10,000원", 10000 -> "+10,000원"
  static String formatWithSign(int amount) {
    final sign = amount < 0 ? '-' : '+';
    return '$sign${formatWithCurrency(amount.abs())}';
  }
}