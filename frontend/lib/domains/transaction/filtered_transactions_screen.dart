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
      final result = await TransactionApi.getTransactionsPaginated(
        limit: 1000,  // 충분히 큰 값
        offset: 0,
        category: widget.filters['category'] as String?,
        startDate: widget.filters['start_date'] as String?,
        endDate: widget.filters['end_date'] as String?,
      );

      List<Transaction> transactions = result['transactions'] as List<Transaction>;

      // 추가 필터링 (프론트엔드에서)
      if (widget.filters['merchant'] != null) {
        final merchant = widget.filters['merchant'] as String;
        transactions = transactions.where((t) => t.description.contains(merchant)).toList();
      }

      if (widget.filters['payment_method'] != null) {
        final paymentMethod = widget.filters['payment_method'] as String;
        transactions = transactions.where((t) => t.paymentMethod == paymentMethod).toList();
      }

      // 시간대 필터링 (시간 파싱 필요)
      if (widget.filters['time_range'] != null) {
        final timeRange = widget.filters['time_range'] as String;
        transactions = _filterByTimeRange(transactions, timeRange);
      }

      // 주말 필터링
      if (widget.filters['is_weekend'] == true) {
        transactions = _filterWeekend(transactions);
      }

      // 월 초 필터링
      if (widget.filters['early_month'] == true) {
        transactions = _filterEarlyMonth(transactions);
      }

      setState(() {
        _transactions = transactions;
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

  List<Transaction> _filterByTimeRange(List<Transaction> transactions, String timeRange) {
    // "18:00-22:00" 형식 파싱
    final parts = timeRange.split('-');
    if (parts.length != 2) return transactions;

    final startHour = int.tryParse(parts[0].split(':')[0]);
    final endHour = int.tryParse(parts[1].split(':')[0]);
    if (startHour == null || endHour == null) return transactions;

    return transactions.where((t) {
      try {
        final dateTime = DateTime.parse(t.date);
        final hour = dateTime.hour;
        
        if (startHour < endHour) {
          return hour >= startHour && hour < endHour;
        } else {
          // 야간 시간대 (22시~02시)
          return hour >= startHour || hour < endHour;
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Transaction> _filterWeekend(List<Transaction> transactions) {
    return transactions.where((t) {
      try {
        final dateTime = DateTime.parse(t.date);
        final dayOfWeek = dateTime.weekday;
        return dayOfWeek == 6 || dayOfWeek == 7;  // 토, 일
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Transaction> _filterEarlyMonth(List<Transaction> transactions) {
    return transactions.where((t) {
      try {
        final dateTime = DateTime.parse(t.date);
        return dateTime.day <= 5;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  
}