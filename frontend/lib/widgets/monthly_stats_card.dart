import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 월별 통계 카드 위젯
class MonthlyStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final NumberFormat currencyFormat;

  const MonthlyStatsCard({
    super.key,
    required this.stats,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final totalIncome = stats['total_income'] ?? 0;
    final totalExpense = stats['total_expense'] ?? 0;
    final balance = stats['balance'] ?? 0;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('수입', totalIncome, Colors.green),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _buildStatItem('지출', totalExpense, Colors.red),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('순수입  ', style: TextStyle(fontSize: 16)),
                Text(
                  '${balance >= 0 ? '+' : ''}${currencyFormat.format(balance)}원',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.blue : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          '${currencyFormat.format(amount)}원',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}