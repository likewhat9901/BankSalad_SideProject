import 'package:flutter/material.dart';
import 'overspending_pattern.dart';
import 'analysis_api.dart';
import '../../core/logger/logger_service.dart';
import '../../core/widgets/common/loading_widget.dart';
import '../../core/widgets/common/error_widget.dart';
import '../../core/widgets/common/empty_widget.dart';
import '../transaction/widgets/month_selector.dart';
import 'overspending_rules_screen.dart';
import 'widgets/overspending_trend_card.dart';
import 'widgets/overspending_summary_card.dart';
import 'widgets/overspending_pattern_list.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTrend();
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

  // 빌드 헬퍼 메서드들
  Widget _buildMonthSelector() {
    return MonthSelector(
      year: _selectedYear,
      month: _selectedMonth,
      onPrev: () => _changeMonth(-1),
      onNext: () => _changeMonth(1),
    );
  }

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

  Widget _buildContentCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverspendingTrendCard(
          trend: _trend,
          isLoading: _isTrendLoading,
          selectedPeriod: _trendPeriod,
          onPeriodChanged: _onTrendPeriodChanged,
        ),
        const SizedBox(height: 20),
        OverspendingSummaryCard(patterns: patterns),
        const SizedBox(height: 20),
        OverspendingPatternList(
          patterns: patterns,
          onSettingsPressed: _handleSettingsPressed,
        ),
      ],
    );
  }

  // 이벤트 핸들러
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
  }

  void _onTrendPeriodChanged(TrendPeriod period) {
    setState(() {
      _trendPeriod = period;
    });
    _loadTrend();
  }

  void _handleSettingsPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OverspendingRulesScreen(),
      ),
    ).then((_) {
      _loadData();
      _loadTrend();
    });
  }

  // 비즈니스 로직
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
      LoggerService.error('과소비 데이터 로드 실패', e);
      if (!mounted) return;
      setState(() {
        errorMessage = '데이터를 불러올 수 없습니다';
        isLoading = false;
      });
    }
  }

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
      LoggerService.error('과소비 추이 로드 실패', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _trend = [];
        _isTrendLoading = false;
      });
    }
  }
}