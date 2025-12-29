import 'package:flutter/material.dart';
import '../../../core/utils/formatters/currency_formatter.dart';
import '../../../core/routing/app_route.dart';
import '../transaction.dart';
import '../utils/category_icons.dart';

/// 거래내역 타일 위젯
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onUpdate;   // 수정 후 콜백 함수

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.amount < 0;
    final cat = CategoryIcons.getIcon(transaction.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cat['color'].withOpacity(0.2),
          child: Icon(cat['icon'], color: cat['color']),
        ),
        title: Text(
          transaction.description.isEmpty ? '내역 없음' : transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${transaction.category} | ${transaction.paymentMethod}',
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Text(
          CurrencyFormatter.formatWithSign(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpense ? Colors.red : Colors.green,
            fontSize: 16,
          ),
        ),
        isThreeLine: false,
        onTap: () {  // 클릭 이벤트
          // 상세 화면으로 이동 (transaction_detail_screen.dart)
          Navigator.pushNamed(context, AppRoutes.transactionDetail, arguments: {
            'transaction': transaction,    // 거래내역 데이터
            'onUpdate': onUpdate,    // 수정 후 콜백 함수
          }).then((updated) {
            // 수정되었으면 콜백 실행
            if (updated == true) {
              onUpdate?.call();
            }
          });
        },
      ),
    );
  }
}