import 'package:flutter/material.dart';
import 'transaction.dart';
import 'widgets/transaction_tile.dart';
import 'transaction_api.dart';
import '../../core/widgets/common/loading_widget.dart';
import '../../core/widgets/common/error_widget.dart';
import '../../core/widgets/common/empty_widget.dart';

/// 필터링된 거래내역 화면
class FilteredTransactionsScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic> filters;  // 필터 조건

  const FilteredTransactionsScreen({
    super.key,
    required this.title,
    required this.filters,
  });

  @override
  State<FilteredTransactionsScreen> createState() => _FilteredTransactionsScreenState();
}

class _FilteredTransactionsScreenState extends State<FilteredTransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_hasError) {
      return ErrorStateWidget(
        message: _errorMessage ?? '오류가 발생했습니다',
        onRetry: _loadTransactions,
      );
    }

    if (_transactions.isEmpty) {
      return const EmptyWidget(
        icon: Icons.receipt_long,
        message: '거래내역이 없습니다',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return TransactionTile(
          transaction: transaction,
          onUpdate: () {
            _loadTransactions();
          },
        );
      },
    );
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 👇 백엔드에서 모든 필터링 처리!
      final result = await TransactionApi.getTransactionsPaginated(
        limit: 1000,
        offset: 0,
        category: widget.filters['category'] as String?,
        startDate: widget.filters['start_date'] as String?,
        endDate: widget.filters['end_date'] as String?,
        merchant: widget.filters['merchant'] as String?,
        paymentMethod: widget.filters['payment_method'] as String?,
        timeRange: widget.filters['time_range'] as String?,
        isWeekend: widget.filters['is_weekend'] as bool?,
        earlyMonth: widget.filters['early_month'] as bool?,
      );

      // 프론트엔드 필터링 코드 삭제! 백엔드에서 정렬된 상태로 옴
      setState(() {
        _transactions = result['transactions'] as List<Transaction>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = '거래내역을 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

}