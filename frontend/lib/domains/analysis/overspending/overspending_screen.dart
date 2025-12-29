import 'package:flutter/material.dart';
import 'overspending_pattern.dart';
import '../analysis_api.dart';
import '../../../core/logger/logger_service.dart';
import '../../../core/widgets/common/loading_widget.dart';
import '../../../core/widgets/common/error_widget.dart';
import '../../../core/widgets/common/empty_widget.dart';
import '../../transaction/widgets/month_selector.dart';
import '../../../core/routing/app_route.dart';
import 'widgets/overspending_trend_card.dart';
import 'widgets/overspending_summary_card.dart';
import 'widgets/overspending_pattern_list.dart';
import '../recurring/recurring_spending_pattern.dart';
import '../recurring/widgets/recurring_spending_card.dart';
import '../time_analysis/time_spending_pattern.dart';
import '../time_analysis/widgets/time_spending_card.dart';
import '../../personality/spending_personality_api.dart';
import '../../personality/spending_personality.dart';
import '../../personality/widgets/spending_personality_card.dart';

class OverspendingScreen extends StatefulWidget {
  const OverspendingScreen({super.key});

  @override
  State<OverspendingScreen> createState() => _OverspendingScreenState();
}

class _OverspendingScreenState extends State<OverspendingScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<OverspendingPattern> patterns = [];
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // 추이 데이터
  List<MonthlyOverspendingPoint> _trend = [];
  bool _isTrendLoading = false;
  TrendPeriod _trendPeriod = TrendPeriod.sixMonths;

  // 반복 소비 패턴 데이터
  List<RecurringSpendingPattern> _recurringPatterns = [];
  bool _isRecurringLoading = false;

  // 시간대 소비 패턴 데이터
  List<TimeSpendingPattern> _timePatterns = [];
  bool _isTimeAnalysisLoading = false;

  // 소비 성향 데이터
  SpendingPersonality? _personality;
  bool _isLoadingPersonality = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTrend();
    _loadRecurringPatterns();
    _loadTimeAnalysis();
    _loadPersonality();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('과소비 패턴 분석'),
        backgroundColor: Colors.redAccent.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadData();
              _loadTrend();
              _loadRecurringPatterns();
              _loadTimeAnalysis();
            },
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
  
  // ========== 빌드 헬퍼 메서드들 ==========
  
  // 월 선택기 빌드
  Widget _buildMonthSelector() {
    return MonthSelector(
      year: _selectedYear,
      month: _selectedMonth,
      onPrev: () => _changeMonth(-1),
      onNext: () => _changeMonth(1),
    );
  }
  
  // 본문 빌드
  Widget _buildBody() {
    if (isLoading) {
      return const LoadingWidget();
    }

    if (errorMessage != null) {
      return ErrorStateWidget(
        message: errorMessage!,
        onRetry: () {
          _loadData();
          _loadTrend();
        },
      );
    }

    if (patterns.isEmpty) {
      return const EmptyWidget(
        icon: Icons.check_circle_outline,
        message: '과소비 패턴이 감지되지 않았습니다 🎉',
        iconColor: Colors.green,
        iconSize: 48,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildContentCards(),
      ),
    );
  }

  // 콘텐츠 카드 빌드
  Widget _buildContentCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 소비 성향 카드
        _buildPersonalityCard(),
        const SizedBox(height: 20),
        // 과소비 요약 카드
        OverspendingSummaryCard(patterns: patterns),
        const SizedBox(height: 20),
        // 과소비 추이 카드
        OverspendingTrendCard(
          trend: _trend,
          isLoading: _isTrendLoading,
          selectedPeriod: _trendPeriod,
          onPeriodChanged: _onTrendPeriodChanged,
        ),
        const SizedBox(height: 20),
        // 과소비 패턴 리스트 카드
        OverspendingPatternList(
          patterns: patterns,
          onSettingsPressed: _handleSettingsPressed,
        ),
        const SizedBox(height: 20),
        // 반복 소비 패턴 카드
        RecurringSpendingCard(
          patterns: _recurringPatterns,
          isLoading: _isRecurringLoading,
        ),
        const SizedBox(height: 20),
        TimeSpendingCard(
          patterns: _timePatterns,
          isLoading: _isTimeAnalysisLoading,
          year: _selectedYear,
          month: _selectedMonth,
        ),
      ],
    );
  }

  // ========== 이벤트 핸들러 ==========
  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadData();
    _loadTrend();
    _loadRecurringPatterns();
    _loadTimeAnalysis();
  }

  // 과소비 추이 기간 변경
  void _onTrendPeriodChanged(TrendPeriod period) {
    setState(() {
      _trendPeriod = period;
    });
    _loadTrend();
  }

  // 과소비 규칙 설정 화면 이동
  void _handleSettingsPressed() {
    Navigator.pushNamed(context, AppRoutes.overspendingRules)
      .then((_) {
        _loadData();
        _loadTrend();
      });
  }

  // ========== 비즈니스 로직 ==========

  // 소비 성향 로드 함수
  Future<void> _loadPersonality() async {
    setState(() => _isLoadingPersonality = true);
    try {
      final personality = await SpendingPersonalityApi.getSpendingPersonality();
      if (!mounted) return;
      setState(() {
        _personality = personality;
        _isLoadingPersonality = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPersonality = false);
    }
  }

  // 소비 성향 카드 빌드
  Widget _buildPersonalityCard() {
    if (_isLoadingPersonality) {
      return const LoadingWidget();
    }
    if (_personality == null) {
      return const SizedBox.shrink();
    }
    return SpendingPersonalityCard(personality: _personality!);
  }

  // 과소비 데이터 로드
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await AnalysisApi.getOverspendingPatterns(
        year: _selectedYear,
        month: _selectedMonth,
      );
      if (!mounted) return;
      setState(() {
        patterns = result;
        isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Analysis', '과소비 데이터 로드 실패', e);
      if (!mounted) return;
      setState(() {
        errorMessage = '데이터를 불러올 수 없습니다';
        isLoading = false;
      });
    }
  }

  // 과소비 추이 로드
  Future<void> _loadTrend() async {
    setState(() {
      _isTrendLoading = true;
    });

    try {
      final base = DateTime(_selectedYear, _selectedMonth, 1);
      final List<MonthlyOverspendingPoint> points = [];
      
      // 기간에 따라 개월 수 결정
      final monthCount = _trendPeriod == TrendPeriod.sixMonths ? 6 : 12;
      
      for (int i = monthCount - 1; i >= 0; i--) {
        final d = DateTime(base.year, base.month - i, 1);
        final list = await AnalysisApi.getOverspendingPatterns(
          year: d.year,
          month: d.month,
        );
        final total = list.fold<int>(
          0,
          (sum, p) => sum + p.totalAmount,
        );
        points.add(MonthlyOverspendingPoint(
          year: d.year,
          month: d.month,
          totalAmount: total,
        ));
      }

      if (!mounted) return;
      setState(() {
        _trend = points;
        _isTrendLoading = false;
      });
    } catch (e, stackTrace) {
      LoggerService.error('Analysis', '과소비 추이 로드 실패', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _trend = [];
        _isTrendLoading = false;
      });
    }
  }

  // 반복 소비 패턴 로드
  Future<void> _loadRecurringPatterns() async {
    setState(() => _isRecurringLoading = true);

    try {
      final result = await AnalysisApi.getRecurringSpendingPatterns(
        year: _selectedYear,
        month: _selectedMonth,
        minCount: 3,  // 최소 3회 이상 반복
      );
      if (!mounted) return;
      setState(() {
        _recurringPatterns = result;
        _isRecurringLoading = false;
      });
    } catch (e) {
      LoggerService.error('Analysis', '반복 소비 패턴 로드 실패', e);
      if (!mounted) return;
      setState(() {
        _recurringPatterns = [];
        _isRecurringLoading = false;
      });
    }
  }

  // 시간대 소비 분석 로드
  Future<void> _loadTimeAnalysis() async {
    setState(() => _isTimeAnalysisLoading = true);

    try {
      final result = await AnalysisApi.getTimeBasedSpending(
        year: _selectedYear,
        month: _selectedMonth,
      );
      if (!mounted) return;
      setState(() {
        _timePatterns = result;
        _isTimeAnalysisLoading = false;
      });
    } catch (e) {
      LoggerService.error('Analysis', '시간대 소비 분석 로드 실패', e);
      if (!mounted) return;
      setState(() {
        _timePatterns = [];
        _isTimeAnalysisLoading = false;
      });
    }
  }
}