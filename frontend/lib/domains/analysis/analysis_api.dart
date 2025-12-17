import 'overspending_pattern.dart';
import '../../core/api/api_client.dart';

class AnalysisApi {
  /// 과소비 패턴 분석
  static Future<List<OverspendingPattern>> getOverspendingPatterns({
    int? year,
    int? month,
  }) async {
    final query = <String, String>{};
    if (year != null && month != null) {
      query['year'] = year.toString();
      query['month'] = month.toString();
    }

    final data = await BaseApiClient.get(
      '/analysis/overspending',
      queryParams: query.isEmpty ? null : query,
      logMessage: '과소비 분석 API 요청',
    );

    final List<dynamic> patternList = data['patterns'];
    return patternList
        .map((json) => OverspendingPattern.fromJson(json))
        .toList();
  }

  /// 과소비 규칙 조회
  static Future<List<Map<String, dynamic>>> getOverspendingRules() async {
    final data = await BaseApiClient.get(
      '/analysis/rules',
      logMessage: '과소비 규칙 조회',
    );

    final List<dynamic> rulesList = data['rules'] ?? [];
    return rulesList.cast<Map<String, dynamic>>();
  }

  /// 과소비 규칙 전체 수정
  static Future<void> updateOverspendingRules(
    List<Map<String, dynamic>> rules,
  ) async {
    await BaseApiClient.put(
      '/analysis/rules',
      {'rules': rules},
      logMessage: '과소비 규칙 수정',
    );
  }

  /// 과소비 규칙 추가
  static Future<Map<String, dynamic>> createOverspendingRule(
    Map<String, dynamic> rule,
  ) async {
    final data = await BaseApiClient.post(
      '/analysis/rules',
      rule,
      logMessage: '과소비 규칙 추가',
    );
    return data['rule'] as Map<String, dynamic>;
  }

  /// 과소비 규칙 단일 수정
  static Future<Map<String, dynamic>> updateOverspendingRule(
    int ruleId,
    Map<String, dynamic> rule,
  ) async {
    final data = await BaseApiClient.put(
      '/analysis/rules/$ruleId',
      rule,
      logMessage: '과소비 규칙 수정',
    );
    return data['rule'] as Map<String, dynamic>;
  }

  /// 과소비 규칙 삭제
  static Future<void> deleteOverspendingRule(int ruleId) async {
    await BaseApiClient.delete(
      '/analysis/rules/$ruleId',
      logMessage: '과소비 규칙 삭제',
    );
  }
}