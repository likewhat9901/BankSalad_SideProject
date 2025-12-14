import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logger_service.dart';
import 'api_config.dart';

class BaseApiClient {
  /// GET 요청 공통 처리
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    String? logMessage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);

    LoggerService.debug(logMessage ?? 'API 요청: $uri');

    try {
      final response = await http.get(uri).timeout(
        ApiConfig.timeout,
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );

      LoggerService.info('응답 수신 - 상태코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        LoggerService.warning('API 오류 응답: ${response.statusCode}');
        LoggerService.debug('응답 본문: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      LoggerService.error('API 호출 실패: $uri', e, stackTrace);
      rethrow;
    }
  }

  /// PUT 요청 공통 처리
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? logMessage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    LoggerService.debug(logMessage ?? 'API 요청: $uri');

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(
        ApiConfig.timeout,
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );

      LoggerService.info('응답 수신 - 상태코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        LoggerService.warning('API 오류 응답: ${response.statusCode}');
        LoggerService.debug('응답 본문: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      LoggerService.error('API 호출 실패: $uri', e, stackTrace);
      rethrow;
    }
  }

  /// POST 요청 공통 처리 (JSON)
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? logMessage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    LoggerService.debug(logMessage ?? 'API 요청: $uri');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(
        ApiConfig.timeout,
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );

      LoggerService.info('응답 수신 - 상태코드: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        LoggerService.warning('API 오류 응답: ${response.statusCode}');
        LoggerService.debug('응답 본문: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      LoggerService.error('API 호출 실패: $uri', e, stackTrace);
      rethrow;
    }
  }

  /// POST (Multipart) 요청 공통 처리
  static Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    String filePath,
    String fileName, {
    String? logMessage,
    Map<String, String>? fields,  // 추가 필드가 필요한 경우
  }) async {
    // URI를 내부에서 생성
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    LoggerService.debug(logMessage ?? 'Multipart API 요청: $uri');

    try {
      // MultipartRequest 생성 시 URI를 올바르게 설정
      final request = http.MultipartRequest('POST', uri);
      request.files
          .add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

      // 추가 필드가 있으면 추가
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // 요청 전송
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      LoggerService.info('응답 수신 - 상태코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        LoggerService.error('API 오류 응답: ${response.statusCode}');
        LoggerService.error('응답 본문: ${response.body}');
        throw Exception('Multipart 요청 실패: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      LoggerService.error('Multipart 요청 실패: $uri', e, stackTrace);
      rethrow;
    }
  }

  /// DELETE 요청 공통 처리
  static Future<void> delete(
    String endpoint, {
    String? logMessage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    LoggerService.debug(logMessage ?? 'API 요청: $uri');

    try {
      final response = await http.delete(uri).timeout(
        ApiConfig.timeout,
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );

      LoggerService.info('응답 수신 - 상태코드: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        LoggerService.warning('API 오류 응답: ${response.statusCode}');
        LoggerService.debug('응답 본문: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      LoggerService.error('API 호출 실패: $uri', e, stackTrace);
      rethrow;
    }
  }
}