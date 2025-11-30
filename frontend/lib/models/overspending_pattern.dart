class OverspendingPattern {
  final String category;
  final int amount;
  final double percentage;
  final String month;

  OverspendingPattern({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.month,
  });

  // 나중에 백엔드 연동 시 사용
  factory OverspendingPattern.fromJson(Map<String, dynamic> json) {
    return OverspendingPattern(
      category: json['category'],
      amount: json['amount'],
      percentage: (json['percentage'] as num).toDouble(),
      month: json['month'] ?? '',
    );
  }
}