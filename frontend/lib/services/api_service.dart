import 'dart:convert';
import 'package:http/http.dart' as http;

import 'logger_service.dart';
import '../models/transaction.dart';


class ApiService {
  // 로컬 개발 시 - Android 에뮬레이터는 localhost 주소로 10.0.2.2를 사용
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<List<Transaction>> getTransactions({
    int limit = 50,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (category != null) queryParams['category'] = category;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/transactions/').replace(queryParameters: queryParams);

    // 🔹 요청 시작 로그
    LoggerService.debug('📤 API 요청 시작: $uri');
    LoggerService.trace('요청 파라미터: $queryParams');
    
    try {
      final response = await http.get(uri);
      
      // 🔹 응답 상태 로그
      LoggerService.info('📥 응답 수신 - 상태코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> txList = data['transactions'];
        
        // 🔹 성공 로그
        LoggerService.debug('✅ 거래내역 ${txList.length}건 로드 완료');
        
        return txList.map((json) => Transaction.fromJson(json)).toList();
      } else {
        // 🔹 HTTP 에러 로그
        LoggerService.warning('⚠️ API 오류 응답: ${response.statusCode}');
        LoggerService.debug('응답 본문: ${response.body}');
        
        throw Exception('거래내역을 불러오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // 🔹 예외 발생 로그 (네트워크 오류 등)
      LoggerService.error('❌ API 호출 실패: $uri', e, stackTrace);
      rethrow;
    }
  }
}