/// 절약 기회 모델
class SavingsOpportunity {
  final String type;  // "recurring", "overspending", "category"
  final String title;
  final String description;
  final int currentAmount;
  final int savingsAmount;  // 절약 가능 금액
  final String category;
  
  // 반복 소비용
  final String? merchant;
  final int? currentFrequency;
  final int? recommendedFrequency;
  
  // 과소비용
  final List<String>? reasons;
  
  // 카테고리용
  final int? currentAvg;
  final int? recommendedAvg;

  SavingsOpportunity({
    required this.type,
    required this.title,
    required this.description,
    required this.currentAmount,
    required this.savingsAmount,
    required this.category,
    this.merchant,
    this.currentFrequency,
    this.recommendedFrequency,
    this.reasons,
    this.currentAvg,
    this.recommendedAvg,
  });

  factory SavingsOpportunity.fromJson(Map<String, dynamic> json) {
    return SavingsOpportunity(
      type: json['type'],
      title: json['title'],
      description: json['description'],
      currentAmount: json['current_amount'],
      savingsAmount: json['savings_amount'],
      category: json['category'],
      merchant: json['merchant'],
      currentFrequency: json['current_frequency'],
      recommendedFrequency: json['recommended_frequency'],
      reasons: json['reasons'] != null 
        ? (json['reasons'] as List).cast<String>()
        : null,
      currentAvg: json['current_avg'],
      recommendedAvg: json['recommended_avg'],
    );
  }
}