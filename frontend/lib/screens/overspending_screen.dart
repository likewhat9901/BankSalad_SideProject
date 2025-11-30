import 'package:flutter/material.dart';
import '../models/overspending_pattern.dart';

class OverspendingScreen extends StatefulWidget {
  const OverspendingScreen({super.key});

  @override
  State<OverspendingScreen> createState() => _OverspendingScreenState();
}

class _OverspendingScreenState extends State<OverspendingScreen> {
  bool isLoading = true;
  
  // ============ Mock 데이터 (나중에 API로 교체) ============
  final List<OverspendingPattern> mockPatterns = [
    OverspendingPattern(category: '배달음식', amount: 450000, percentage: 35.0, month: '2024-11'),
    OverspendingPattern(category: '택시', amount: 280000, percentage: 22.0, month: '2024-11'),
    OverspendingPattern(category: '쇼핑', amount: 320000, percentage: 25.0, month: '2024-11'),
    OverspendingPattern(category: '유흥', amount: 230000, percentage: 18.0, month: '2024-11'),
  ];

  final List<Map<String, dynamic>> mockFlowData = [
    {'month': '2024-09', 'total': 850000},
    {'month': '2024-10', 'total': 1100000},
    {'month': '2024-11', 'total': 1280000},
  ];
  // ========================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: 나중에 ApiService.getOverspending() 호출로 교체
    await Future.delayed(const Duration(milliseconds: 500)); // 로딩 시뮬레이션
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('과소비 패턴 분석'),
        backgroundColor: Colors.redAccent.shade100,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                    const SizedBox(height: 20),
                    _buildFlowSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // 요약 카드
  Widget _buildSummaryCard() {
    final totalOverspending = mockPatterns.fold<int>(0, (sum, p) => sum + p.amount);
    
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
                const Text('이번 달 과소비', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatCurrency(totalOverspending),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red.shade700),
            ),
            const Text('평균 대비 초과 지출', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // 패턴별 리스트 (흐름 표현)
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
            ...mockPatterns.map((pattern) => _buildPatternItem(pattern)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(OverspendingPattern pattern) {
    final colors = {
      '배달음식': Colors.orange,
      '택시': Colors.blue,
      '쇼핑': Colors.purple,
      '유흥': Colors.pink,
    };
    final color = colors[pattern.category] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(pattern.category, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Text(_formatCurrency(pattern.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          // 비율 바
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pattern.percentage / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${pattern.percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // 월별 흐름 섹션
  Widget _buildFlowSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📈 월별 과소비 추이', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // 간단한 바 차트 (fl_chart 없이)
            ...mockFlowData.map((data) => _buildFlowBar(data)),
            const SizedBox(height: 12),
            const Text(
              '💡 지난 3개월간 과소비가 증가하는 추세입니다',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowBar(Map<String, dynamic> data) {
    final maxAmount = mockFlowData.map((d) => d['total'] as int).reduce((a, b) => a > b ? a : b);
    final ratio = (data['total'] as int) / maxAmount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(data['month'].toString().substring(5) + '월', style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.red.shade400],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatCurrency(data['total']),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
  }
}