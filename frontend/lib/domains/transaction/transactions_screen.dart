import 'package:flutter/material.dart';
import 'transaction.dart';
import '../upload/widgets/excel_upload_button.dart';
import 'widgets/month_selector.dart';
import 'widgets/monthly_stats_card.dart';
import 'widgets/transaction_tile.dart';
import 'widgets/date_header.dart';  // 추가
import 'transaction_api.dart';
import 'stats_api.dart';
import '../../core/widgets/common/loading_widget.dart';
import '../../core/widgets/common/error_widget.dart';
import '../../core/widgets/common/empty_widget.dart';
import 'utils/date_utils.dart';  // 추가
import 'utils/transaction_grouping.dart';  // 추가

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final List<Transaction> _transactions = [];
  final ScrollController _scrollController = ScrollController();

  // 월 선택 상태
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // 월별 통계
  Map<String, dynamic>? _monthlyStats;

  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;
  int _offset = 0;
  static const int _limit = 30;

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            onPressed: _loadMonthlyData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // 월 선택기
  Widget _buildMonthSelector() {
    return MonthSelector(
      year: _selectedYear,
      month: _selectedMonth,
      onPrev: () => _changeMonth(-1),
      onNext: () => _changeMonth(1),
    );
  }

  // 통계 카드
  Widget _buildStatsCard() {
    return MonthlyStatsCard(
      stats: _monthlyStats!,
    );
  }

  // 리스트 아이템 빌더 (분리)
  Widget _buildListItem(BuildContext context, int index, List<Map<String, dynamic>> groupedData) {
    final statsOffset = _monthlyStats != null ? 1 : 0;
    final dataIndex = index - statsOffset;

    // 통계 카드 (첫 번째 아이템)
    if (_monthlyStats != null && index == 0) {
      return _buildStatsCard();
    }

    // 맨 아래 로딩 인디케이터
    if (_hasMore && dataIndex == groupedData.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 날짜 헤더 또는 거래내역 타일
    final item = groupedData[dataIndex];
    if (item['type'] == 'header') {
      return DateHeader(date: item['date']);  // 변경: 위젯 사용
    } else {
      return TransactionTile(
        transaction: item['transaction'],
        onUpdate: _loadMonthlyData,
      );
    }
  }

  Widget _buildBody() {
    // 첫 로딩 중
    if (_transactions.isEmpty && _isLoading) {
      return const LoadingWidget();
    }

    // 에러 발생
    if (_transactions.isEmpty && _hasError) {
      return ErrorStateWidget(
        message: '데이터를 불러오는데 실패했습니다',
        onRetry: _loadMonthlyData,
        icon: Icons.error_outline,
        iconSize: 64,
      );
    }

    // 데이터 없음
    if (_transactions.isEmpty && !_isLoading) {
      return EmptyWidget(
        icon: Icons.receipt_long_outlined,
        message: '$_selectedMonth월 거래내역이 없습니다',
        subMessage: '엑셀 파일을 업로드해주세요',
        action: ExcelUploadButton(
          onUploadSuccess: _loadMonthlyData,
        ),
      );
    }

    // 날짜별로 그룹화된 데이터
    final groupedData = TransactionGrouping.groupByDate(_transactions);  // 변경: 유틸리티 사용
    final statsOffset = _monthlyStats != null ? 1 : 0;
    final loadingOffset = _hasMore ? 1 : 0;

    // 리스트 표시
    return ListView.builder(
      controller: _scrollController,
      itemCount: statsOffset + groupedData.length + loadingOffset,
      itemBuilder: (context, index) => _buildListItem(context, index, groupedData),  // 변경: 메서드 분리
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadTransactions();
    }
  }

  // 월 변경
  void _changeMonth(int delta) {
    final newDate = DateTime(_selectedYear, _selectedMonth + delta);
    setState(() {
      _selectedYear = newDate.year;
      _selectedMonth = newDate.month;
    });
    _loadMonthlyData();
  }

  // 상태 초기화
  void _resetState() {
    _isLoading = true;
    _hasError = false;
    _transactions.clear();
    _offset = 0;
    _hasMore = true;
    _monthlyStats = null;
  }

  // 월별 데이터 로드 (통계 + 거래내역)
  Future<void> _loadMonthlyData() async {
    setState(_resetState);

    try {
      // 1. 월별 통계 로드
      final stats = await StatsApi.getMonthlyStats(_selectedYear, _selectedMonth);
      setState(() => _monthlyStats = stats);

      // 2. 해당 월 거래내역 로드
      await _loadTransactions(isRefresh: true);
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 거래내역 로드 (페이지네이션)
  Future<void> _loadTransactions({bool isRefresh = false}) async {
    if (_isLoading && !isRefresh) return;
    setState(() => _isLoading = true);

    try {
      final result = await TransactionApi.getTransactionsPaginated(
        limit: _limit,
        offset: isRefresh ? 0 : _offset,
        startDate: TransactionDateUtils.getStartDateString(_selectedYear, _selectedMonth),  // 변경
        endDate: TransactionDateUtils.getEndDateString(_selectedYear, _selectedMonth),  // 변경
      );
      
      final List<Transaction> newTransactions = result['transactions'];
      
      setState(() {
        if (isRefresh) {
          _transactions.clear();
          _transactions.addAll(newTransactions);
          _offset = newTransactions.length;
        } else {
          _transactions.addAll(newTransactions);
          _offset = _transactions.length;
        }
        _hasMore = result['has_more'] ?? false;
      });
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}