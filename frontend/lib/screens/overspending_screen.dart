import 'package:flutter/material.dart';
import '../models/overspending_pattern.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';


class OverspendingScreen extends StatefulWidget {
  const OverspendingScreen({super.key});

  @override
  State<OverspendingScreen> createState() => _OverspendingScreenState();
}

class _OverspendingScreenState extends State<OverspendingScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<OverspendingPattern> patterns = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getOverspendingPatterns();
      setState(() {
        patterns = result;
        isLoading = false;
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
        title: const Text('과소비 패턴 분석'),
        backgroundColor: Colors.redAccent.shade100,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (patterns.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            SizedBox(height: 16),
            Text('과소비 패턴이 감지되지 않았습니다 🎉', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),
            _buildPatternList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalAmount = patterns.fold<int>(0, (sum, p) => sum + p.totalAmount);
    final totalReasons = patterns.fold<int>(0, (sum, p) => sum + p.reasons.length);

    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 8),
                const Text('과소비 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatCurrency(totalAmount),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red.shade700),
            ),
            Text('${patterns.length}개 카테고리, $totalReasons개 패턴 감지', 
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔥 과소비 카테고리', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...patterns.map((pattern) => _buildPatternItem(pattern)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(OverspendingPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(pattern.category, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(_formatCurrency(pattern.totalAmount),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          // 사유 리스트
          ...pattern.reasons.map((reason) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(_getReasonIcon(reason.type), size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(reason.message, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  IconData _getReasonIcon(String type) {
    switch (type) {
      case 'high_frequency':
        return Icons.repeat;
      case 'high_amount':
        return Icons.attach_money;
      case 'high_monthly':
        return Icons.calendar_month;
      default:
        return Icons.info_outline;
    }
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
  }
}