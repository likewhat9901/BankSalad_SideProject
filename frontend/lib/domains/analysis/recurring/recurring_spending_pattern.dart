/// 반복 소비 패턴
class RecurringSpendingPattern {
  final String key;  // 패턴 키 (예: "상호명_시간대")
  final String merchant;  // 상호명
  final String? timeRange;  // 시간대 (예: "18:00-20:00")
  final String? dayOfWeek;  // 요일
  final String category;
  final String paymentMethod;
  final int count;  // 반복 횟수
  final int totalAmount;  // 총 금액
  final int averageAmount;  // 평균 금액
  final DateTime firstDate;  // 첫 거래일
  final DateTime lastDate;  // 마지막 거래일
  final List<int> amounts;  // 각 거래 금액 리스트

  RecurringSpendingPattern({
    required this.key,
    required this.merchant,
    this.timeRange,
    this.dayOfWeek,
    required this.category,
    required this.paymentMethod,
    required this.count,
    required this.totalAmount,
    required this.averageAmount,
    required this.firstDate,
    required this.lastDate,
    required this.amounts,
  });

  factory RecurringSpendingPattern.fromJson(Map<String, dynamic> json) {
    return RecurringSpendingPattern(
      key: json['key'],
      merchant: json['merchant'],
      timeRange: json['time_range'],
      dayOfWeek: json['day_of_week'],
      category: json['category'],
      paymentMethod: json['payment_method'],
      count: json['count'],
      totalAmount: json['total_amount'],
      averageAmount: json['average_amount'],
      firstDate: DateTime.parse(json['first_date']),
      lastDate: DateTime.parse(json['last_date']),
      amounts: (json['amounts'] as List).cast<int>(),
    );
  }

  /// 반복 주기 계산 (일 단위)
  int get periodDays {
    if (count < 2) return 0;
    final daysDiff = lastDate.difference(firstDate).inDays;
    return daysDiff ~/ (count - 1);
  }

  /// 패턴 설명 생성
  String get description {
    final parts = <String>[];
    if (timeRange != null) parts.add('$timeRange 시간대');
    if (dayOfWeek != null) parts.add('$dayOfWeek');
    if (parts.isEmpty) return '반복 소비';
    return parts.join(', ');
  }
}