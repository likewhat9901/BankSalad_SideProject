import 'dart:convert';
import 'package:http/http.dart' as http;

import 'logger_service.dart';
import '../models/transaction.dart';
import '../models/overspending_pattern.dart';


class ApiService {
  // 로컬 개발 시 - Android 에뮬레이터는 localhost 주소로 10.0.2.2를 사용
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// 엑셀 파일 업로드
  static Future<Map<String, dynamic>> uploadExcel(String filePath, String fileName) async {
    final uri = Uri.parse('$baseUrl/upload/excel');
    
    LoggerService.info('파일 업로드 시작: $fileName');
    
    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      LoggerService.info('업로드 응답 - 상태코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        LoggerService.info('파일 업로드 성공: $fileName');
        return json.decode(response.body);
      } else {
        LoggerService.error('업로드 실패: ${response.statusCode}');
        throw Exception('파일 업로드 실패: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      LoggerService.error('업로드 오류', e, stackTrace);
      rethrow;
    }
  }

  /// 거래내역 조회
  static Future<Map<String, dynamic>> getTransactionsPaginated({
    int limit = 50,
    int offset = 0,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (category != null) queryParams['category'] = category;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/transactions/').replace(queryParameters: queryParams);

    // 🔹 요청 시작 로그
    LoggerService.debug('API 요청 시작: $uri');
    LoggerService.debug('요청 파라미터: $queryParams');
    
    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 응답 시간 초과');
        },
      );
      
      // 🔹 응답 상태 로그
      LoggerService.info('응답 수신 - 상태코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);    // 백엔드 응답: { "transactions": [...], "total_count": 100, "has_more": true }
        
        final List<dynamic> txList = data['transactions'] ?? [];
        final List<Transaction> transactions = 
          txList.map((json) => Transaction.fromJson(json)).toList();
        
        // 🔹 성공 로그
        LoggerService.debug('거래내역 ${txList.length}건 로드 완료');
        
        return {
          'transactions': transactions,
          'total_count': (data['total_count'] ?? 0).toInt(),
          'has_more': (data['has_more'] ?? false),
        };
      } else {
        // 🔹 HTTP 에러 로그
        LoggerService.warning('API 오류 응답: ${response.statusCode}');
        LoggerService.debug('응답 본문: ${response.body}');
        
        throw Exception('거래내역을 불러오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // 🔹 예외 발생 로그 (네트워크 오류 등)
      LoggerService.error('API 호출 실패: $uri', e, stackTrace);
      rethrow;
    }
  }

  /// 과소비 패턴 분석
  static Future<List<OverspendingPattern>> getOverspendingPatterns() async {
    final uri = Uri.parse('$baseUrl/analysis/overspending');
    
    LoggerService.debug('과소비 분석 API 요청: $uri');
    
    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );
      
      LoggerService.info('응답 수신 - 상태코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> patternList = data['patterns'];
        
        LoggerService.debug('과소비 패턴 ${patternList.length}건 로드 완료');
        
        return patternList
            .map((json) => OverspendingPattern.fromJson(json))
            .toList();
      } else {
        LoggerService.warning('API 오류 응답: ${response.statusCode}');
        throw Exception('과소비 분석 실패: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      LoggerService.error('API 호출 실패: $uri', e, stackTrace);
      rethrow;
    }
  }
}