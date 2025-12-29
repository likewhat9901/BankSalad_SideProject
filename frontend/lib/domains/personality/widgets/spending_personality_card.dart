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
        padding: const EdgeInsets.all(16),  // 20 → 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 캐릭터 + 유형 이름을 가로로 배치
            Row(
              children: [
                // 캐릭터 아이콘 (작게)
                personality.characterImage != null && personality.characterImage!.isNotEmpty
                  ? Image.asset(
                      personality.characterImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          personality.characterIcon,
                          style: const TextStyle(fontSize: 60),
                        );
                      },
                    )
                  : Text(
                      personality.characterIcon,
                      style: const TextStyle(fontSize: 60),
                    ),
                const SizedBox(width: 20),
                
                // 이름 + 유형 코드 (세로)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personality.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        personality.type,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),  // 16 → 12
            
            // 설명
            Text(
              personality.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            
            // 특성 태그 (유지하되 간격 축소)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: personality.traits.map((trait) {
                return Chip(
                  label: Text(trait, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            
            // 조언 (축소)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      personality.advice,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 상세 점수 섹션 제거 또는 ExpansionTile로 접기
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