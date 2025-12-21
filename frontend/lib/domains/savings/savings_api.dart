import '../savings/savings_opportunity.dart';
import '../../core/api/api_client.dart';

class SavingsApi {

  /// 절약 기회 분석 (Top 3)
  static Future<List<SavingsOpportunity>> getSavingsOpportunities({
    int? year,
    int? month,
  }) async {
    final query = <String, String>{};
    if (year != null && month != null) {
      query['year'] = year.toString();
      query['month'] = month.toString();
    }

    final data = await BaseApiClient.get(
      '/savings/opportunities',
      queryParams: query.isEmpty ? null : query,
      logMessage: '절약 기회 분석 API 요청',
    );

    final List<dynamic> opportunityList = data['opportunities'] ?? [];
    return opportunityList
        .map((json) => SavingsOpportunity.fromJson(json))
        .toList();
  }
}