import 'package:flutter/material.dart';
import '../spending_personality.dart';

class SpendingPersonalityCard extends StatelessWidget {
  final SpendingPersonality personality;

  const SpendingPersonalityCard({
    super.key,
    required this.personality,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 캐릭터 아이콘 또는 이미지
            personality.characterImage != null && personality.characterImage!.isNotEmpty
            ? Image.asset(
                personality.characterImage!,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지 로드 실패 시 default 이미지 표시
                  return Text(
                    personality.characterIcon,
                    style: const TextStyle(fontSize: 80),
                  );
                },
              )
            : Text(
                personality.characterIcon,
                style: const TextStyle(fontSize: 80),
              ),
            
            // 유형 이름
            Text(
              personality.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // 유형 코드
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                personality.type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 설명
            Text(
              personality.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // 특성 태그
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: personality.traits.map((trait) {
                return Chip(
                  label: Text(trait),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // 조언
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      personality.advice,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 점수 바
            _buildScoresSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상세 점수',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildScoreBar('계획성', personality.scores.planning, Colors.blue),
        const SizedBox(height: 8),
        _buildScoreBar('규칙성', personality.scores.regular, Colors.orange),
        const SizedBox(height: 8),
        _buildScoreBar('반복성', personality.scores.recurring, Colors.purple),
        const SizedBox(height: 8),
        _buildScoreBar('절약성', personality.scores.saving, Colors.green),
      ],
    );
  }

  Widget _buildScoreBar(String label, double score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(score * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}