import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../widgets/excel_upload_button.dart';
import '../widgets/month_selector.dart';

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
    setState(() {
      _selectedMonth += delta;    // delta만큼 월 변경 (-1: 이전월, +1: 다음월)
      if (_selectedMonth > 12) {
        _selectedMonth = 1;    // 12월 넘으면 다음 해 1월
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;    // 1월 미만이면 전 해 12월
        _selectedYear--;
      }
    });
    _loadMonthlyData();    // 월 변경 후 월별 데이터 다시 로드
  }

  // 월별 데이터 로드 (통계 + 거래내역)
  Future<void> _loadMonthlyData() async {
    setState(() {
      _isLoading = true;          // 로딩 시작
      _hasError = false;          // 에러 초기화
      _transactions.clear();      // 거래내역 리스트 초기화
      _offset = 0;                // 페이지네이션 오프셋 초기화
      _hasMore = true;            // 더 불러올 데이터가 있는지 여부 초기화
      _monthlyStats = null;       // 월별 통계 데이터 초기화
    });

    try {
      // 1. 월별 통계 로드
      final stats = await ApiService.getMonthlyStats(_selectedYear, _selectedMonth);
      setState(() => _monthlyStats = stats);    // 통계 저장

      // 2. 해당 월 거래내역 로드
      await _loadTransactions(isRefresh: true);    // 첫 로딩이므로 isRefresh: true
    } catch (e) {
      setState(() => _hasError = true);       // 에러 발생 시 플래그 설정
    } finally {
      setState(() => _isLoading = false);     // 로딩 종료
    }
  }

  // 해당 월의 시작 날짜 계산 (예: 2024-12-01)
  String get _startDate => '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-01';

  // 해당 월의 마지막 날짜 계산 (예: 2024-12-31)
  String get _endDate {
    final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0).day;    // 다음 달 0일 = 이번 달 마지막 날
    return '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-$lastDay';    // 예: 2024-12-31
  }

  // 거래내역 로드 (페이지네이션)
  Future<void> _loadTransactions({bool isRefresh = false}) async {
    if (_isLoading && !isRefresh) return;    // 로딩 중이면 추가 로드 방지
    setState(() => _isLoading = true);    // 로딩 시작

    try {
      final result = await ApiService.getTransactionsPaginated(
        limit: _limit,           // 한 번에 불러올 개수
        offset: _offset,         // 건너뛸 개수
        startDate: _startDate,   // 시작 날짜
        endDate: _endDate,       // 끝 날짜
      );
      
      final List<Transaction> newTransactions = result['transactions'];
      
      setState(() {
        _transactions.addAll(newTransactions);    // 기존 리스트에 추가
        _hasMore = result['has_more'] ?? false;   // 더 불러올 데이터 있는지 확인
        _offset = _transactions.length;           // 오프셋 업데이트
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

  // 통계 카드
  Widget _buildStatsCard() {
    final stats = _monthlyStats!;
    final totalIncome = stats['total_income'] ?? 0;       // 총 수입 (수입 합계)
    final totalExpense = stats['total_expense'] ?? 0;     // 총 지출 (지출 합계)
    final balance = stats['balance'] ?? 0;                // 순 잔액 (수입 - 지출)

    return Card(
      margin: const EdgeInsets.all(12),    // 여백
      child: Padding(
        padding: const EdgeInsets.all(16),    // 패딩
        child: Column(
          children: [    // 수입, 지출, 잔액 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,    // 양쪽 정렬
              children: [
                _buildStatItem('수입', totalIncome, Colors.green),    // 수입 표시
                Container(width: 1, height: 40, color: Colors.grey.shade300),    // 구분선
                _buildStatItem('지출', totalExpense, Colors.red),    // 지출 표시
              ],
            ),
            const Divider(height: 24),    // 구분선
            Row(
              mainAxisAlignment: MainAxisAlignment.center,    // 중앙 정렬
              children: [
                const Text('순수입  ', style: TextStyle(fontSize: 16)),    // 순수입 텍스트
                Text(
                  '${balance >= 0 ? '+' : ''}${_currencyFormat.format(balance)}원',    // 순수입 금액 표시 (양수: +, 음수: -)
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.blue : Colors.red,    // 순수입 색상 (양수: 파랑, 음수: 빨강)
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 통계 아이템 (수입/지출 표시용)
  Widget _buildStatItem(String label, int amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),    // 라벨 텍스트
        const SizedBox(height: 4),    // 여백
        Text(
          '${_currencyFormat.format(amount)}원',    // 금액 표시
          style: TextStyle(
            fontSize: 18,    // 폰트 크기
            fontWeight: FontWeight.bold,    // 폰트 굵기
            color: color,    // 색상 (수입: 초록, 지출: 빨강)
          ),
        ),
      ],
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

    // 리스트 표시
    return ListView.builder(
      controller: _scrollController,    // 스크롤 컨트롤러
      itemCount: _transactions.length + (_hasMore ? 1 : 0) + (_monthlyStats != null ? 1 : 0),    // 거래내역 개수 + 더 불러올 데이터 있는지 여부
      itemBuilder: (context, index) {
        // 통계 카드 (첫 번째 아이템)
        if (_monthlyStats != null && index == 0) {
          return _buildStatsCard();
        }

        // 거래내역 인덱스 조정 (통계 카드가 있으면 -1)
        final transactionIndex = _monthlyStats != null ? index - 1 : index;

        // 맨 아래 로딩 인디케이터 (더 불러올 데이터가 있을 때)
        if (_hasMore && transactionIndex == _transactions.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),    // 로딩 스피너
          );
        }
        return _buildTransactionTile(_transactions[transactionIndex]);    // 거래내역 타일
      },
    );
  }

  // 카테고리별 아이콘과 색상 반환
  Map<String, dynamic> _getCategoryIcon(String category) {
    final c = category.toLowerCase();
    final map = {
      // 수입 카테고리
      '급여': {'icon': Icons.account_balance_wallet, 'color': Colors.green},
      '지원금': {'icon': Icons.attach_money, 'color': Colors.green},
      '금융수입': {'icon': Icons.payments, 'color': Colors.green},

      // 지출 카테고리
      '식사': {'icon': Icons.restaurant, 'color': Colors.orange},
      '카페/간식': {'icon': Icons.local_cafe, 'color': Colors.brown},
      '술/유흥': {'icon': Icons.local_bar, 'color': Colors.purple},
      '의복/미용': {'icon': Icons.checkroom, 'color': Colors.pink},
      '문화/여가': {'icon': Icons.movie, 'color': Colors.blue},
      '교통': {'icon': Icons.directions_car, 'color': Colors.teal},
      '생활': {'icon': Icons.shopping_cart, 'color': Colors.indigo},
      '의료/건강': {'icon': Icons.local_hospital, 'color': Colors.red},
      '주거/통신': {'icon': Icons.home, 'color': Colors.cyan},
      '할부': {'icon': Icons.credit_card, 'color': Colors.red},
      '경조사': {'icon': Icons.celebration, 'color': Colors.pink},
      '교육': {'icon': Icons.school, 'color': Colors.blue},
      '기타': {'icon': Icons.category, 'color': Colors.grey},
    };
    
    for (var key in map.keys) {
      if (c.contains(key)) return map[key]!;
    }
    return {'icon': Icons.category, 'color': Colors.grey};
  }

  Widget _buildTransactionTile(Transaction tx) {
    final isExpense = tx.amount < 0;    // 지출 여부 (음수면 지출)
    final cat = _getCategoryIcon(tx.category);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),    // 여백
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cat['color'].withOpacity(0.2),  // 수정
          child: Icon(cat['icon'], color: cat['color']),  // 수정
        ),
        title: Text(    // 내용
          tx.description.isEmpty ? '내역 없음' : tx.description,    // 내용이 없으면 '내역 없음' 표시
          maxLines: 1,    // 최대 1줄
          overflow: TextOverflow.ellipsis,    // 줄 바꿈 방지
        ),
        subtitle: Column(    // 하위 텍스트
          crossAxisAlignment: CrossAxisAlignment.start,    // 왼쪽 정렬
          children: [
            Text(tx.date),    // 날짜
            Container(
              margin: const EdgeInsets.only(top: 4),    // 여백
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),    // 패딩
              decoration: BoxDecoration(    // 배경
                color: Colors.grey.shade200,    // 회색 배경
                borderRadius: BorderRadius.circular(12),    // 라운드 코너
              ),
              child: Text(
                '${tx.category} | ${tx.paymentMethod}',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Text(    // 트레일링 텍스트 
          '${isExpense ? "-" : "+"}${_currencyFormat.format(tx.amount.abs())}원',
          style: TextStyle(
            fontWeight: FontWeight.bold,    // 폰트 굵기
            color: isExpense ? Colors.red : Colors.green,    // 색상 (지출: 빨강, 수입: 초록)
            fontSize: 16,    // 폰트 크기
          ),
        ),    // 텍스트 스타일
        isThreeLine: true,    // 세 줄 표시
      ),
    );
  }
}