
/// 소비 성향 모델
class SpendingPersonality {
  final String type;  // "PRRS", "IIUD" 등
  final String name;  // "계획왕"
  final String description;
  final List<String> traits;  // ["계획적", "규칙적", ...]
  final String characterIcon;  // "🎯"
  final String? characterImage;  // "assets/images/characters/prrs.png"
  final String advice;
  final PersonalityScores scores;

  SpendingPersonality({
    required this.type,
    required this.name,
    required this.description,
    required this.traits,
    required this.characterIcon,
    this.characterImage,
    required this.advice,
    required this.scores,
  });

  factory SpendingPersonality.fromJson(Map<String, dynamic> json) {
    return SpendingPersonality(
      type: json['type'],
      name: json['name'],
      description: json['description'],
      traits: (json['traits'] as List).cast<String>(),
      characterIcon: json['character_icon'],
      characterImage: json['character_image'] ?? '',
      advice: json['advice'],
      scores: PersonalityScores.fromJson(json['scores']),
    );
  }
}

/// 소비 성향 점수
class PersonalityScores {
  final double planning;  // 계획성 (0.0 ~ 1.0)
  final double regular;   // 규칙성 (0.0 ~ 1.0)
  final double recurring; // 반복성 (0.0 ~ 1.0)
  final double saving;    // 절약성 (0.0 ~ 1.0)

  PersonalityScores({
    required this.planning,
    required this.regular,
    required this.recurring,
    required this.saving,
  });

  factory PersonalityScores.fromJson(Map<String, dynamic> json) {
    return PersonalityScores(
      planning: (json['planning'] as num).toDouble(),
      regular: (json['regular'] as num).toDouble(),
      recurring: (json['recurring'] as num).toDouble(),
      saving: (json['saving'] as num).toDouble(),
    );
  }
}