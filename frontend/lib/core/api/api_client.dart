import 'dart:convert';                         // JSON 인코딩/디코딩용
import 'dart:typed_data';                      // 바이트 배열(Uint8List) 타입
import 'package:http/http.dart' as http;       // HTTP 클라이언트 패키지
import '../logger/logger_service.dart';        // 공통 로거
import 'api_config.dart';                      // baseUrl, timeout 설정

// 모든 HTTP 요청을 공통으로 처리하는 클라이언트
class BaseApiClient {
    /// GET 요청 공통 처리
  static Future<Map<String, dynamic>> get(
    String endpoint, {                        // 예: '/analysis/overspending'
    Map<String, String>? queryParams,         // 쿼리 파라미터 (year, month 등)
    String? logMessage,                       // 로그에 남길 커스텀 메시지
  }) async {
    // baseUrl + endpoint 로 전체 URI 생성 후, 쿼리 파라미터 추가
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);

    LoggerService.debug(logMessage ?? 'API 요청: $uri');

    try {
      // GET 요청 보내기 + 타임아웃 설정
      final response = await http.get(uri).timeout(
        ApiConfig.timeout,
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );

      // 응답 상태코드 로깅
      LoggerService.info('응답 수신 - 상태코드: ${response.statusCode}');

      // 200 OK 일 때만 JSON 파싱
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // 200이 아닌 경우 경고 로그 + 예외
        LoggerService.warning('API 오류 응답: ${response.statusCode}');
        LoggerService.debug('응답 본문: ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // 네트워크 에러/파싱 에러 등 모든 예외를 로깅 후 재던짐
      LoggerService.error('API 호출 실패: $uri', e, stackTrace);
      rethrow;
    }
  }

  /// PUT 요청 공통 처리 (JSON Body)
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
        body: json.encode(body),          // Map → JSON 문자열
      ).timeout(                          // 타임아웃 설정
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
    String filePath,                          // 업로드할 파일 경로
    String fileName, {                        // 서버/로그에 남길 파일명
    String? logMessage,
    Map<String, String>? fields,             // 추가로 전송할 폼 필드 (옵션)
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

  /// POST (Multipart) 요청 공통 처리 (웹용 - 바이트 사용)
  static Future<Map<String, dynamic>> postMultipartBytes(
    String endpoint,
    Uint8List fileBytes,
    String fileName, {
    String? logMessage,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    LoggerService.debug(logMessage ?? 'Multipart API 요청: $uri');

    try {
      final request = http.MultipartRequest('POST', uri);
      
      // 바이트로 MultipartFile 생성
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

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