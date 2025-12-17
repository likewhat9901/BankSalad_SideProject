import 'package:flutter/material.dart';
import '../overspending_pattern.dart';
import '../../../core/utils/formatters/currency_formatter.dart';

/// 과소비 패턴 리스트 위젯
class OverspendingPatternList extends StatelessWidget {
  final List<OverspendingPattern> patterns;
  final VoidCallback? onSettingsPressed;

  const OverspendingPatternList({
    super.key,
    required this.patterns,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 제목과 설정 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔥 과소비 카테고리',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onSettingsPressed != null)  // 설정 버튼이 있으면 표시
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    onPressed: onSettingsPressed,
                    tooltip: '규칙 관리',
                    padding: EdgeInsets.zero,  // 패딩 최소화
                    constraints: const BoxConstraints(),  // 크기 제약 제거
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...patterns.map((pattern) => _PatternItem(pattern: pattern)),
          ],
        ),
      ),
    );
  }
}

/// 개별 패턴 아이템 위젯
class _PatternItem extends StatelessWidget {
  final OverspendingPattern pattern;

  const _PatternItem({required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pattern.category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatWithCurrency(pattern.totalAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 사유 리스트
          ...pattern.reasons.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      _getReasonIcon(reason.type),
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  IconData _getReasonIcon(String type) {
    switch (type) {
      case 'high_frequency':
        return Icons.repeat;
      case 'high_amount':
        return Icons.attach_money;
      case 'high_monthly':
        return Icons.calendar_month;
      default:
        return Icons.info_outline;
    }
  }
}