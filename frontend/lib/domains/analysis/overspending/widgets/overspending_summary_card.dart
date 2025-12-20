import 'package:flutter/material.dart';
import '../overspending_pattern.dart';
import '../../../../core/utils/formatters/currency_formatter.dart';

/// 과소비 요약 카드 위젯
class OverspendingSummaryCard extends StatelessWidget {
  final List<OverspendingPattern> patterns;

  const OverspendingSummaryCard({
    super.key,
    required this.patterns,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = patterns.fold<int>(
      0,
      (sum, p) => sum + p.totalAmount,
    );
    final totalReasons = patterns.fold<int>(
      0,
      (sum, p) => sum + p.reasons.length,
    );

    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  '과소비 요약',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.formatWithCurrency(totalAmount),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            Text(
              '${patterns.length}개 카테고리, $totalReasons개 패턴 감지',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}