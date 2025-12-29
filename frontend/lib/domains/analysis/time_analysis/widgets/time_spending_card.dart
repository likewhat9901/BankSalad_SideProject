import 'package:flutter/material.dart';
import '../time_spending_pattern.dart';
import '../../../../core/utils/formatters/currency_formatter.dart';
import '../../../../core/routing/app_route.dart';

/// 시간대 소비 분석 카드 (충동 지점)
class TimeSpendingCard extends StatelessWidget {
  final List<TimeSpendingPattern> patterns;
  final bool isLoading;
  final int? year; 
  final int? month;

  const TimeSpendingCard({
    super.key,
    required this.patterns,
    this.isLoading = false,
    this.year,
    this.month,
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
              Icon(Icons.access_time, color: Colors.grey.shade400, size: 40),
              const SizedBox(height: 8),
              Text(
                '시간대 소비 패턴이 없습니다',
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
                  Icons.access_time,
                  color: Colors.purple.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '시간대 소비 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '충동 지점',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 패턴 리스트
            ...patterns.map((pattern) => _PatternItem(pattern: pattern, year: year, month: month)),
          ],
        ),
      ),
    );
  }
}

/// 개별 패턴 아이템
class _PatternItem extends StatelessWidget {
  final TimeSpendingPattern pattern;
  final int? year;
  final int? month;

  const _PatternItem({required this.pattern, this.year, this.month});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 패턴 이름과 금액
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pattern.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                        color: Colors.purple.shade700,
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
            // 상세 정보
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (pattern.timeRange != null)
                  _InfoChip(
                    icon: Icons.schedule,
                    label: pattern.timeRange!,
                  ),
                if (pattern.days != null)
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: pattern.days!,
                  ),
                _InfoChip(
                  icon: Icons.attach_money,
                  label: '평균 ${CurrencyFormatter.formatWithCurrency(pattern.averageAmount)}',
                ),
              ],
            ),
          ],
        ),
      )
    );
  }

  void _handleTap(BuildContext context) {
    final filters = <String, dynamic>{
      'year': year,
      'month': month,
    };

    if (year != null && month != null) {
      final lastDay = DateTime(year!, month! + 1, 0).day;
      filters['start_date'] = '${year!.toString().padLeft(4, '0')}-${month!.toString().padLeft(2, '0')}-01';
      filters['end_date'] = '${year!.toString().padLeft(4, '0')}-${month!.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    }

    switch (pattern.type) {
      case 'time_range':
        if (pattern.timeRange != null) {
          filters['time_range'] = pattern.timeRange;
        }
        break;

      case 'early_month':
        filters['early_month'] = true;
        break;

      case 'weekend_evening':
        filters['is_weekend'] = true;
        if (pattern.timeRange != null) {
          filters['time_range'] = pattern.timeRange;
        }
        break;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.filteredTransactions,
      arguments: {
        'title': pattern.name,
        'filters': filters,
      },
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