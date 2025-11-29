import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../widgets/excel_upload_button.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final List<Transaction> _transactions = [];
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'ko_KR');

  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;
  int _offset = 0;
  static const int _limit = 30;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 스크롤이 끝에 가까워지면 추가 로드
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions({bool isRefresh = false}) async {
    if (_isLoading) return;
    if (!isRefresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      if (isRefresh) {
        _transactions.clear();
        _offset = 0;
        _hasMore = true;
      }
    });

    try {
      final result = await ApiService.getTransactionsPaginated(
        limit: _limit,
        offset: _offset,
      );
      
      final List<Transaction> newTransactions = result['transactions'];
      
      setState(() {
        _transactions.addAll(newTransactions);
        _hasMore = result['has_more'] ?? false;
        _offset = _transactions.length;
      });
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래내역'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTransactions(isRefresh: true),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

Widget _buildBody() {
    // 첫 로딩 중
    if (_transactions.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 에러 발생
    if (_transactions.isEmpty && _hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('데이터를 불러오는데 실패했습니다'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadTransactions(isRefresh: true),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 데이터 없음
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              '거래내역이 없습니다',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '엑셀 파일을 업로드해주세요',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ExcelUploadButton(
              onUploadSuccess: () => _loadTransactions(isRefresh: true),
            ),
          ],
        ),
      );
    }

    // 리스트 표시
    return ListView.builder(
      controller: _scrollController,
      itemCount: _transactions.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 맨 아래 로딩 인디케이터
        if (index == _transactions.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildTransactionTile(_transactions[index]);
      },
    );
  }

  Widget _buildTransactionTile(Transaction tx) {
    final isExpense = tx.amount < 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense 
              ? Colors.red.shade100 
              : Colors.green.shade100,
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          tx.description.isEmpty ? '내역 없음' : tx.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tx.date),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tx.category,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isExpense ? "-" : "+"}${_currencyFormat.format(tx.amount.abs())}원',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpense ? Colors.red : Colors.green,
            fontSize: 16,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}