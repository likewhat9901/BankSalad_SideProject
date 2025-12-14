import 'package:flutter/material.dart';
import '../models/overspending_pattern.dart';
import '../services/api/analysis_api.dart';
import '../services/logger_service.dart';
import '../widgets/month_selector.dart';
import 'overspending_rules_screen.dart';

class OverspendingScreen extends StatefulWidget {
  const OverspendingScreen({super.key});

  @override
  State<OverspendingScreen> createState() => _OverspendingScreenState();
}

class _OverspendingScreenState extends State<OverspendingScreen> {
  bool isLoading = true;                      // 로딩 중인지 여부
  String? errorMessage;                       // 에러 메시지 (없으면 null)
  List<OverspendingPattern> patterns = [];    // 과소비 패턴 리스트 (카테고리별)
  int _selectedYear = DateTime.now().year;    // 선택된 연도 (기본: 올해)
  int _selectedMonth = DateTime.now().month;  // 선택된 월 (기본: 이번 달)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;    // delta만큼 월 변경 (-1: 이전월, +1: 다음월)
      if (_selectedMonth > 12) { _selectedMonth = 1; _selectedYear++; }         // 12월 넘으면 다음 해 1월
      else if (_selectedMonth < 1) { _selectedMonth = 12; _selectedYear--; }    // 1월 미만이면 전 해 12월
    });
    _loadData();    // 월 변경 후 데이터 다시 로드
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;      // 로딩 시작
      errorMessage = null;   // 에러 초기화
    });

    try {
      final result = await AnalysisApi.getOverspendingPatterns(
        year: _selectedYear,
        month: _selectedMonth,
      );
      setState(() {
        patterns = result;    // 성공 시 패턴 리스트 저장
        isLoading = false;    // 로딩 종료
      });
    } catch (e) {
      LoggerService.error('과소비 데이터 로드 실패', e);
      setState(() {
        errorMessage = '데이터를 불러올 수 없습니다';
        isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('과소비 패턴 분석'),    // 타이틀
        backgroundColor: Colors.redAccent.shade100,    // 빨간색 배경
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OverspendingRulesScreen(),
                ),
              ).then((_) {
                // 규칙 수정 후 데이터 새로고침
                _loadData();
              });
            },
            tooltip: '규칙 관리',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),            // 월 선택기
          Expanded(child: _buildBody()),    // 메인 컨텐츠
        ],
      ),
    );
  }

  // 월 선택기
  Widget _buildMonthSelector() {
    return MonthSelector(
      year: _selectedYear,
      month: _selectedMonth,
      onPrev: () => _changeMonth(-1),       // 이전 버튼 클릭 시
      onNext: () => _changeMonth(1),        // 다음 버튼 클릭 시
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());    // 로딩 중: 스피너
    }

    if (errorMessage != null) {
      return Center(    // 에러 발생: 에러 메시지와 다시 시도 버튼
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),    // 에러 아이콘
            const SizedBox(height: 16),
            Text(errorMessage!, style: TextStyle(color: Colors.grey.shade600)),    // 에러 메시지
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('다시 시도')),    // 다시 시도 버튼
          ],
        ),
      );
    }

    if (patterns.isEmpty) {
      return const Center(    // 과소비 패턴이 없음: 체크 아이콘과 메시지
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),    // 체크 아이콘
            SizedBox(height: 16),
            Text('과소비 패턴이 감지되지 않았습니다 🎉', style: TextStyle(fontSize: 16)),    // 메시지
          ],
        ),
      );
    }

    return RefreshIndicator(    // 과소비 패턴이 있음: 당겨서 새로고침 가능한 스크롤뷰
      onRefresh: _loadData,    // 새로고침 시 데이터 다시 로드
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),    // 스크롤 가능하도록 설정
        padding: const EdgeInsets.all(16),    // 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),    // 과소비 요약 카드
            const SizedBox(height: 20),
            _buildPatternList(),    // 과소비 패턴 리스트
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalAmount = patterns.fold<int>(0, (sum, p) => sum + p.totalAmount);         // 모든 패턴의 총 금액 합계
    final totalReasons = patterns.fold<int>(0, (sum, p) => sum + p.reasons.length);     // 모든 패턴의 총 사유 개수 합계

    return Card(    // 카드 위젯
      elevation: 4,    // 그림자 효과
      color: Colors.red.shade50,    // 빨간색 배경
      child: Padding(
        padding: const EdgeInsets.all(20),    // 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,    // 왼쪽 정렬
          children: [
            Row(
              children: [    // 경고 아이콘과 텍스트
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),    // 경고 아이콘
                const SizedBox(width: 8),    // 여백
                const Text('과소비 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),    // 텍스트
              ],
            ),
            const SizedBox(height: 12),    // 여백
            Text(
              _formatCurrency(totalAmount),    // 총 금액 표시
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red.shade700),    // 텍스트 스타일
            ),
            Text('${patterns.length}개 카테고리, $totalReasons개 패턴 감지',    // 텍스트
                style: const TextStyle(color: Colors.grey)),    // 텍스트 스타일
          ],
        ),
      ),
    );
  }

  Widget _buildPatternList() {
    return Card(    // 카드 위젯
      elevation: 4,    // 그림자 효과
      child: Padding(
        padding: const EdgeInsets.all(16),    // 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,    // 왼쪽 정렬
          children: [
            const Text('🔥 과소비 카테고리', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),    // 과소비 카테고리 텍스트
            const SizedBox(height: 16),    // 여백
            ...patterns.map((pattern) => _buildPatternItem(pattern)),    // 각 패턴 아이템 매핑(패턴 리스트를 순회하며 각 패턴을 _buildPatternItem 함수에 전달)
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(OverspendingPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),    // 여백
      padding: const EdgeInsets.all(12),    // 패딩
      decoration: BoxDecoration(
        color: Colors.grey.shade50,    // 회색 배경
        borderRadius: BorderRadius.circular(8),    // 라운드 코너
        border: Border.all(color: Colors.grey.shade200),    // 회색 테두리 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,    // 왼쪽 정렬
        children: [
          // 카테고리 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 20),    // 불 아이콘
                  const SizedBox(width: 8),    // 여백
                  Text(pattern.category, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),    // 카테고리 텍스트
                ],
              ),
              Text(_formatCurrency(pattern.totalAmount),      
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700)),   // 카테고리별 총액
            ],
          ),
          const SizedBox(height: 12),    // 여백
          // 사유 리스트
          ...pattern.reasons.map((reason) => Padding(   // 사유 리스트 매핑(사유 리스트를 순회하며 각 사유를 Padding 위젯에 전달)
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [    // 사유 아이콘과 텍스트
                Icon(_getReasonIcon(reason.type), size: 16, color: Colors.grey.shade600),    // 사유 아이콘
                const SizedBox(width: 8),    // 여백
                Expanded(
                  child: Text(reason.message, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),    // 사유 메시지
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  IconData _getReasonIcon(String type) {    // 사유 아이콘 반환
    switch (type) {
      case 'high_frequency':
        return Icons.repeat;    // 반복 아이콘
      case 'high_amount':
        return Icons.attach_money;    // 돈 아이콘
      case 'high_monthly':
        return Icons.calendar_month;    // 달 아이콘
      default:
        return Icons.info_outline;    // 정보 아이콘
    }
  }

  String _formatCurrency(int amount) {    // 금액 형식 변환
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';    // 천단위 콤마 추가
  }
}