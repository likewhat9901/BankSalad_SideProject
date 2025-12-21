import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../savings_opportunity.dart';
import '../../../core/routing/app_route.dart';

class SavingsCard extends StatelessWidget {
  final SavingsOpportunity opportunity;
  final int rank;
  final int? year;
  final int? month;

  const SavingsCard({
    super.key,
    required this.opportunity,
    required this.rank,
    this.year,
    this.month,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opportunity.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                opportunity.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '현재 지출',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${formatter.format(opportunity.currentAmount)}원',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.savings,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${formatter.format(opportunity.savingsAmount)}원 절약',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (opportunity.type == 'recurring' && 
                  opportunity.currentFrequency != null &&
                  opportunity.recommendedFrequency != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '월 ${opportunity.currentFrequency}회 → 월 ${opportunity.recommendedFrequency}회',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.grey;
    }
  }

  void _handleTap(BuildContext context) {
    // 절약 기회 상세 화면으로 이동 (필요시 구현)
    // 또는 관련 거래내역 필터링 화면으로 이동
    final filters = <String, dynamic>{
      'category': opportunity.category,
    };
    
    if (opportunity.merchant != null) {
      filters['merchant'] = opportunity.merchant;
    }

    if (year != null && month != null) {
      final lastDay = DateTime(year!, month! + 1, 0).day;
      filters['start_date'] = '${year!}-${month!.toString().padLeft(2, '0')}-01';
      filters['end_date'] = '${year!}-${month!.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    }
    
    Navigator.pushNamed(
      context,
      AppRoutes.filteredTransactions,
      arguments: {
        'title': opportunity.title,
        'filters': filters,
      },
    );
  }
}