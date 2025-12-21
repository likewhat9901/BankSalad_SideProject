import 'package:flutter/material.dart';
import 'savings_opportunity.dart';
import 'savings_api.dart';
import '../../core/logger/logger_service.dart';
import '../../core/widgets/common/loading_widget.dart';
import '../../core/widgets/common/error_widget.dart';
import '../../core/widgets/common/empty_widget.dart';
import '../transaction/widgets/month_selector.dart';
import 'widgets/savings_card.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<SavingsOpportunity> opportunities = [];
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('절약 추천'),
        backgroundColor: Colors.green.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
        onRetry: _loadData,
      );
    }

    if (opportunities.isEmpty) {
      return const EmptyWidget(
        icon: Icons.savings,
        message: '절약 기회가 없습니다\n이미 절약하고 계시네요! 🎉',
        iconColor: Colors.green,
        iconSize: 48,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: opportunities.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SavingsCard(
              opportunity: opportunities[index],
              rank: index + 1,
              year: _selectedYear,
              month: _selectedMonth,
            ),
          );
        },
      ),
    );
  }

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
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await SavingsApi.getSavingsOpportunities(
        year: _selectedYear,
        month: _selectedMonth,
      );
      if (!mounted) return;
      setState(() {
        opportunities = result;
        isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Savings', '절약 기회 로드 실패', e);
      if (!mounted) return;
      setState(() {
        errorMessage = '데이터를 불러올 수 없습니다';
        isLoading = false;
      });
    }
  }
}