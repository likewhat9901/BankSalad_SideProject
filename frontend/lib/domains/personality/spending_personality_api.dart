
import 'spending_personality.dart';
import '../../core/api/api_client.dart';

class SpendingPersonalityApi {
  /// 소비 성향 분석 (MBTI 스타일)
  static Future<SpendingPersonality> getSpendingPersonality({
    int? year,
    int? month,
  }) async {
    final query = <String, String>{};
    if (year != null && month != null) {
      query['year'] = year.toString();
      query['month'] = month.toString();
    }

    final data = await BaseApiClient.get(
      '/personality',
      queryParams: query.isEmpty ? null : query,
      logMessage: '소비 성향 분석 API 요청',
    );

    return SpendingPersonality.fromJson(data);
  }
}