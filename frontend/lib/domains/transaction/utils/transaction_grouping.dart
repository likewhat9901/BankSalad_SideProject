import '../transaction.dart';

class TransactionGrouping {
  /// 날짜별로 거래내역을 그룹화하고 리스트 아이템 형태로 변환
  /// 반환: [{'type': 'header', 'date': '2024-12-07'}, {'type': 'transaction', 'transaction': ...}, ...]
  static List<Map<String, dynamic>> groupByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    
    for (var tx in transactions) {
      final dateOnly = tx.date.split(' ')[0];
      grouped.putIfAbsent(dateOnly, () => []).add(tx);
    }
    
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    
    final List<Map<String, dynamic>> result = [];
    for (var date in sortedDates) {
      result.add({'type': 'header', 'date': date});
      for (var tx in grouped[date]!) {
        result.add({'type': 'transaction', 'transaction': tx});
      }
    }
    
    return result;
  }
}