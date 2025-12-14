import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../widgets/excel_upload_button.dart';
import '../widgets/month_selector.dart';
import '../widgets/monthly_stats_card.dart';
import '../widgets/transaction_tile.dart';
import '../services/api/transaction_api.dart';
import '../services/api/stats_api.dart';



class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final List<Transaction> _transactions = [];    // 거래내역 리스트
  final ScrollController _scrollController = ScrollController();    // 스크롤 컨트롤러 (무한 스크롤용)
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'ko_KR');    // 금액 포맷터 (천단위 콤마)

  // 월 선택 상태
  int _selectedYear = DateTime.now().year;    // 선택된 연도 (기본: 올해)
  int _selectedMonth = DateTime.now().month;  // 선택된 월 (기본: 이번 달)

  // 월별 통계
  Map<String, dynamic>? _monthlyStats;    // 월별 통계 데이터 (수입, 지출, 잔액)

  bool _isLoading = false;          // 로딩 중인지 여부
  bool _hasMore = true;             // 더 불러올 데이터가 있는지 여부 (페이지네이션)
  bool _hasError = false;           // 에러 발생 여부
  int _offset = 0;                  // 현재까지 불러온 데이터 개수 (페이지네이션용)
  static const int _limit = 30;     // 한 번에 불러올 거래내역 개수

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();    // 화면 생성 시 월별 데이터 로드(초기 데이터 로드)
    _scrollController.addListener(_onScroll);    // 스크롤 리스너 등록 (무한 스크롤용)
  }

  @override
  void dispose() {
    _scrollController.dispose();      // 스크롤 컨트롤러 해제 (메모리 누수 방지)
    super.dispose();
  }

  void _onScroll() {
    // 스크롤이 끝에서 200픽셀 이내로 가까워지면 추가 데이터 로드
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadTransactions();    // 추가 데이터 로드 (무한 스크롤용)
    }
  }

  // 월 변경
  void _changeMonth(int delta) {
    // 새로운 날짜 계산 (delta만큼 월 변경)
    final newDate = DateTime(_selectedYear, _selectedMonth + delta);    // Dart의 DateTime 생성자는 월이 범위를 벗어나면 연도를 자동으로 조정
    setState(() { // 월 변경 시 상태 업데이트
      _selectedYear = newDate.year;    // 연도 업데이트
      _selectedMonth = newDate.month;    // 월 업데이트
    });
    _loadMonthlyData();    // 월 변경 후 월별 데이터 다시 로드
  }

  // 상태 초기화
  void _resetState() {
    _isLoading = true;        // 로딩 플래그 초기화
    _hasError = false;        // 에러 플래그 초기화
    _transactions.clear();    // 거래내역 리스트 초기화
    _offset = 0;              // 페이지네이션 오프셋 초기화
    _hasMore = true;          // 더 불러올 데이터가 있는지 여부 초기화
    _monthlyStats = null;     // 월별 통계 데이터 초기화
  }

  // 월별 데이터 로드 (통계 + 거래내역)
  Future<void> _loadMonthlyData() async {
    setState(_resetState); 

    try {
      // 1. 월별 통계 로드
      final stats = await StatsApi.getMonthlyStats(_selectedYear, _selectedMonth);
      setState(() => _monthlyStats = stats);    // 통계 저장

      // 2. 해당 월 거래내역 로드
      await _loadTransactions(isRefresh: true);    // 첫 로딩이므로 isRefresh: true
    } catch (e) {
      setState(() => _hasError = true);       // 에러 발생 시 플래그 설정
    } finally {
      setState(() => _isLoading = false);     // 로딩 종료
    }
  }

  // 해당 월의 시작/끝 날짜를 한 번에 계산
  DateTime get _selectedMonthStart => DateTime(_selectedYear, _selectedMonth, 1);
  DateTime get _selectedMonthEnd => DateTime(_selectedYear, _selectedMonth + 1, 0);
  
  String get _startDate => '${_selectedMonthStart.year}-${_selectedMonthStart.month.toString().padLeft(2, '0')}-01';
  String get _endDate => '${_selectedMonthEnd.year}-${_selectedMonthEnd.month.toString().padLeft(2, '0')}-${_selectedMonthEnd.day}';

  // 거래내역 로드 (페이지네이션)
  Future<void> _loadTransactions({bool isRefresh = false}) async {
    if (_isLoading && !isRefresh) return;    // 로딩 중이면 추가 로드 방지
    setState(() => _isLoading = true);    // 로딩 시작

    try {
      final result = await TransactionApi.getTransactionsPaginated(
        limit: _limit,           // 한 번에 불러올 개수
        offset: isRefresh ? 0 : _offset,         // 건너뛸 개수
        startDate: _startDate,   // 시작 날짜
        endDate: _endDate,       // 끝 날짜
      );
      
      final List<Transaction> newTransactions = result['transactions'];
      
      setState(() {
      if (isRefresh) {
        // 새로고침일 때는 기존 리스트를 완전히 교체
        _transactions.clear();
        _transactions.addAll(newTransactions);
        _offset = newTransactions.length;
      } else {
        // 추가 로드일 때만 기존 리스트에 추가
        _transactions.addAll(newTransactions);
        _offset = _transactions.length;
      }
      _hasMore = result['has_more'] ?? false;
    });
    } catch (e) {
      setState(() => _hasError = true);    // 에러 발생 시 플래그 설정
    } finally {
      setState(() => _isLoading = false);    // 로딩 종료
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래내역'),    // 타이틀
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,    // 테마 색상
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),    // 새로고침 아이콘
            onPressed: _loadMonthlyData,    // 새로고침 버튼
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),    // 월 선택기 
          Expanded(child: _buildBody()),    // 메인 컨텐츠 (통계 카드, 거래내역 리스트)
        ],
      ),
    );
  }

  // 월 선택기
  Widget _buildMonthSelector() {
    return MonthSelector(
      year: _selectedYear,
      month: _selectedMonth,
      onPrev: () => _changeMonth(-1),    // 이전 버튼 클릭 시
      onNext: () => _changeMonth(1),     // 다음 버튼 클릭 시
    );
  }

  // 통계 카드 - 위젯으로 분리(monthly_stats_card.dart)
    Widget _buildStatsCard() {
    return MonthlyStatsCard(
      stats: _monthlyStats!,    // 월별 통계 데이터
      currencyFormat: _currencyFormat,    // 금액 포맷터
    );
  }

    // 날짜별로 거래내역 그룹화
  List<Map<String, dynamic>> _groupTransactionsByDate() {
    final Map<String, List<Transaction>> grouped = {};
    
    for (var tx in _transactions) {
      // 날짜에서 날짜 부분만 추출 (예: "2024-12-07 11:30:00" -> "2024-12-07")
      final dateOnly = tx.date.split(' ')[0];
      if (!grouped.containsKey(dateOnly)) {
        grouped[dateOnly] = [];
      }
      grouped[dateOnly]!.add(tx);
    }
    
    // 날짜 순서대로 정렬 (최신순)
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    
    // 날짜 헤더와 거래내역을 함께 반환
    final List<Map<String, dynamic>> result = [];
    for (var date in sortedDates) {
      result.add({'type': 'header', 'date': date});
      for (var tx in grouped[date]!) {
        result.add({'type': 'transaction', 'transaction': tx});
      }
    }
    
    return result;
  }

  // 날짜 헤더 위젯
  Widget _buildDateHeader(String date) {
    // 날짜 포맷팅 (예: "2024-12-07" -> "12월 7일 (월)")
    final dateTime = DateTime.parse(date);
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][dateTime.weekday % 7];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '${dateTime.month}월 ${dateTime.day}일 ($weekday)',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _buildBody() {
    // 첫 로딩 중
    if (_transactions.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());    // 로딩 스피너
    }

    // 에러 발생
    if (_transactions.isEmpty && _hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),    // 에러 아이콘
            const SizedBox(height: 16),
            const Text('데이터를 불러오는데 실패했습니다'),    // 에러 메시지
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMonthlyData,
              child: const Text('다시 시도'),
            ),    // 다시 시도 버튼
          ],
        ),
      );
    }

    // 데이터 없음
    if (_transactions.isEmpty && !_isLoading) {
      return Center(    // 데이터 없음: 체크 아이콘과 메시지
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(    // 체크 아이콘 (거래내역 아이콘)
              Icons.receipt_long_outlined,
              size: 80,    // 크기
              color: Colors.grey.shade400,    // 색상
            ),
            const SizedBox(height: 24),    // 여백
            Text(
              '$_selectedMonth월 거래내역이 없습니다',    // 메시지
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,    // 색상
              ),
            ),
            const SizedBox(height: 8),    // 여백
            Text(
              '엑셀 파일을 업로드해주세요',    // 메시지
              style: TextStyle(color: Colors.grey.shade500),    // 색상
            ),
            const SizedBox(height: 24),    // 여백
            ExcelUploadButton(    // 엑셀 파일 업로드 버튼
              onUploadSuccess: _loadMonthlyData,    // 업로드 성공 시 데이터 다시 로드
            ),
          ],
        ),
      );
    }

    // 날짜별로 그룹화된 데이터
    final groupedData = _groupTransactionsByDate();
    final statsOffset = _monthlyStats != null ? 1 : 0;
    final loadingOffset = _hasMore ? 1 : 0;

    // 리스트 표시
    return ListView.builder(
      controller: _scrollController,    // 스크롤 컨트롤러
      itemCount: statsOffset + groupedData.length + loadingOffset,
      itemBuilder: (context, index) {
        // 통계 카드 (첫 번째 아이템)
        if (_monthlyStats != null && index == 0) {
          return _buildStatsCard();
        }

        // 날짜별 그룹화된 데이터 인덱스
        final dataIndex = index - statsOffset;

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
          return _buildDateHeader(item['date']);
        } else {
          // 거래내역 타일 - 위젯으로 분리(transaction_tile.dart)
          return TransactionTile(
            transaction: item['transaction'],    // 거래내역 데이터
            currencyFormat: _currencyFormat,    // 금액 포맷터
            onUpdate: _loadMonthlyData,    // 수정 시 데이터 다시 로드
          );
        }
      },
    );
  }
}