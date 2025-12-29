import 'package:flutter/material.dart';
import '../recurring_spending_pattern.dart';
import '../../../../core/utils/formatters/currency_formatter.dart';
import '../../../../core/routing/app_route.dart';

/// 반복 소비 패턴 카드 위젯
class RecurringSpendingCard extends StatelessWidget {
  final List<RecurringSpendingPattern> patterns;
  final bool isLoading;

  const RecurringSpendingCard({
    super.key,
    required this.patterns,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (patterns.isEmpty) {
      return Card(
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.repeat, color: Colors.grey.shade400, size: 40),
              const SizedBox(height: 8),
              Text(
                '반복 소비 패턴이 없습니다',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '반복 소비 패턴',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 패턴 리스트
            ...patterns.map((pattern) => _PatternItem(pattern: pattern)),
          ],
        ),
      ),
    );
  }
}

/// 개별 패턴 아이템
class _PatternItem extends StatelessWidget {
  final RecurringSpendingPattern pattern;

  const _PatternItem({required this.pattern});

  void _handleTap(BuildContext context) {
    final filters = <String, dynamic>{
      'merchant': pattern.merchant,
      'category': pattern.category,
      'payment_method': pattern.paymentMethod,
      'start_date': pattern.firstDate.toIso8601String().split('T')[0],
      'end_date': pattern.lastDate.toIso8601String().split('T')[0],
    };

    if (pattern.timeRange != null) {
      filters['time_range'] = pattern.timeRange;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.filteredTransactions,
      arguments: {
        'title': '${pattern.merchant} 거래내역',
        'filters': filters,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상호명과 금액
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pattern.merchant,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pattern.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatWithCurrency(pattern.totalAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      '${pattern.count}회',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 상세 정보 - Row를 Wrap으로 변경
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.category,
                  label: pattern.category,
                ),
                _InfoChip(
                  icon: Icons.payment,
                  label: pattern.paymentMethod,
                ),
                if (pattern.periodDays > 0)
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: '${pattern.periodDays}일 주기',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 정보 칩 위젯
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}