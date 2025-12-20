/// 시간대 소비 패턴
class TimeSpendingPattern {
  final String type;  // "time_range", "early_month", "weekend_evening"
  final String name;  // 표시 이름
  final String description;  // 설명
  final int count;  // 거래 횟수
  final int totalAmount;  // 총 금액
  final int averageAmount;  // 평균 금액
  final String? timeRange;  // 시간대 (선택)
  final String? days;  // 일자 범위 (선택)

  TimeSpendingPattern({
    required this.type,
    required this.name,
    required this.description,
    required this.count,
    required this.totalAmount,
    required this.averageAmount,
    this.timeRange,
    this.days,
  });

  factory TimeSpendingPattern.fromJson(Map<String, dynamic> json) {
    return TimeSpendingPattern(
      type: json['type'],
      name: json['name'],
      description: json['description'],
      count: json['count'],
      totalAmount: json['total_amount'],
      averageAmount: json['average_amount'],
      timeRange: json['time_range'],
      days: json['days'],
    );
  }
}