import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/formatters/currency_formatter.dart';

/// 월별 과소비 추이 데이터 포인트
class MonthlyOverspendingPoint {
  final int year;
  final int month;
  final int totalAmount;

  MonthlyOverspendingPoint({
    required this.year,
    required this.month,
    required this.totalAmount,
  });

  String get label => '$month월';
}

/// 기간 선택 타입
enum TrendPeriod {
  sixMonths('6개월'),
  oneYear('1년');

  final String label;
  const TrendPeriod(this.label);
}

/// 과소비 추이 그래프 카드 위젯
class OverspendingTrendCard extends StatelessWidget {
  final List<MonthlyOverspendingPoint> trend;
  final bool isLoading;
  final TrendPeriod selectedPeriod;
  final Function(TrendPeriod) onPeriodChanged;

  const OverspendingTrendCard({
    super.key,
    required this.trend,
    required this.isLoading,
    this.selectedPeriod = TrendPeriod.sixMonths,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        elevation: 4,
        child: SizedBox(
          height: 220,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (trend.isEmpty) {
      return Card(
        elevation: 4,
        child: SizedBox(
          height: 220,
          child: const Center(
            child: Text('과소비 기록이 없습니다.'),
          ),
        ),
      );
    }

    // 그래프 데이터 포인트 생성
    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < trend.length; i++) {
      final y = trend[i].totalAmount.toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) maxY = y;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 제목과 기간 선택 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '과소비 추이',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // 기간 선택 버튼
                SegmentedButton<TrendPeriod>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,  // 컴팩트 모드로 크기 줄이기
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),  // 패딩 더 줄이기
                    minimumSize: const Size(30, 24),  // 높이를 24로 설정
                    textStyle: const TextStyle(fontSize: 11),  // 텍스트 더 작게
                  ),
                  segments: const [
                    ButtonSegment(
                      value: TrendPeriod.sixMonths,
                      label: Text('6개월'),
                    ),
                    ButtonSegment(
                      value: TrendPeriod.oneYear,
                      label: Text('1년'),
                    ),
                  ],
                  selected: {selectedPeriod},
                  onSelectionChanged: (Set<TrendPeriod> newSelection) {
                    onPeriodChanged(newSelection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (trend.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY == 0 ? 1 : maxY * 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: maxY == 0
                            ? 1
                            : (maxY / 3).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final v = value.toInt();
                          if (v == 0) return const Text('0');
                          final formatted = CurrencyFormatter.format(v);
                          return Text(
                            formatted.replaceAll('원', ''),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              trend[idx].label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.redAccent,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}