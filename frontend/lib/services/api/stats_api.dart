import 'base_api_client.dart';

class StatsApi {
  /// 월별 통계 조회
  static Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    return await BaseApiClient.get(
      '/stats/monthly',
      queryParams: {
        'year': year.toString(),
        'month': month.toString(),
      },
      logMessage: '월별 통계 API 요청',
    );
  }
}