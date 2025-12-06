/// 과소비 사유
class OverspendingReason {
  final String type;    // "high_frequency", "high_amount", "high_monthly"
  final int count;
  final String message;

  OverspendingReason({
    required this.type,
    required this.count,
    required this.message,
  });

  factory OverspendingReason.fromJson(Map<String, dynamic> json) {
    return OverspendingReason(
      type: json['type'],
      count: json['count'],
      message: json['message'],
    );
  }
}

/// 과소비 패턴 (카테고리별)
class OverspendingPattern {
  final String category;
  final int totalAmount;
  final List<OverspendingReason> reasons;

  OverspendingPattern({
    required this.category,
    required this.totalAmount,
    required this.reasons,
  });

  factory OverspendingPattern.fromJson(Map<String, dynamic> json) {
    return OverspendingPattern(
      category: json['category'],
      totalAmount: json['total_amount'],
      reasons: (json['reasons'] as List)
          .map((r) => OverspendingReason.fromJson(r))
          .toList(),
    );
  }
}