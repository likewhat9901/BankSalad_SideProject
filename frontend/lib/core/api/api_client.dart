import 'dart:convert';                         // JSON 인코딩/디코딩용
import 'package:http/http.dart' as http;       // HTTP 클라이언트 패키지
import '../logger/logger_service.dart';        // 공통 로거
import 'api_config.dart';                      // baseUrl, timeout 설정

// 모든 HTTP 요청을 공통으로 처리하는 클라이언트
class BaseApiClient {
  // ========== 공개 API 메서드 ==========

  /// GET 요청 공통 처리
  static Future<Map<String, dynamic>> get(
    String endpoint, {                        // 예: '/analysis/overspending'
    Map<String, String>? queryParams,         // 쿼리 파라미터 (year, month 등)
    String? logMessage,                       // 로그에 남길 커스텀 메시지
  }) async {
    // 처리 흐름: URI 생성 → GET 요청 → 응답 검증 → JSON 파싱
    // 에러: 모든 예외는 로깅 후 rethrow

    // URI 생성 (baseUrl + endpoint + 쿼리 파라미터)
    final uri = _buildUri(endpoint, queryParams: queryParams);
    LoggerService.debug('API', logMessage ?? 'GET 요청: $uri');

    try {
      // GET 요청 보내기 + 타임아웃 설정
      final response = await http.get(uri).timeout(
        ApiConfig.timeout,
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );

      // 응답 처리 (상태 코드 검증, JSON 파싱, 에러 처리)
      return _handleResponse(response, [200]);
    } catch (e, stackTrace) {
      // 모든 예외를 로깅 후 rethrow
      _handleError(uri, e, stackTrace, 'GET 요청 실패');
    }
  }

  /// PUT 요청 공통 처리 (JSON Body)
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {  
    String? logMessage,           
  }) async {
    // 처리 흐름: URI 생성 → JSON 인코딩 → PUT 요청 → 응답 검증(200) → JSON 파싱
    // 에러: 모든 예외는 로깅 후 rethrow

    // baseUrl + endpoint 로 전체 URI 생성
    final uri = _buildUri(endpoint);
    LoggerService.debug('API', logMessage ?? 'PUT 요청: $uri');

    try {
      // PUT 요청 보내기 + 타임아웃 설정
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),          // Map → JSON 문자열
      ).timeout(                          // 타임아웃 설정
        ApiConfig.timeout,
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );

      // 응답 처리 (상태 코드 검증, JSON 파싱, 에러 처리)
      return _handleResponse(response, [200]);
    } catch (e, stackTrace) {
      // 모든 예외를 로깅 후 rethrow
      _handleError(uri, e, stackTrace, 'PUT 요청 실패');
    }
  }

  /// POST 요청 공통 처리 (JSON)
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? logMessage,
  }) async {
    // 처리 흐름: URI 생성 → JSON 인코딩 → POST 요청 → 응답 검증(200/201) → JSON 파싱
    // 에러: 모든 예외는 로깅 후 rethrow

    // baseUrl + endpoint 로 전체 URI 생성
    final uri = _buildUri(endpoint);
    LoggerService.debug('API', logMessage ?? 'POST 요청: $uri');

    try {
      // POST 요청 보내기 + 타임아웃 설정
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(
        ApiConfig.timeout,
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );

      // 응답 처리 (상태 코드 검증, JSON 파싱, 에러 처리)
      return _handleResponse(response, [200, 201]);
    } catch (e, stackTrace) {
      // 모든 예외를 로깅 후 rethrow
      _handleError(uri, e, stackTrace, 'POST 요청 실패');
    }
  }

  /// POST (Multipart) 요청 공통 처리 (모바일용 - 파일 경로 사용)
  static Future<Map<String, dynamic>> postMultipart(
    String endpoint,                          // 예: '/upload/excel'
    String filePath,                          // 업로드할 파일 경로
    String fileName, {                        // 서버/로그에 남길 파일명
    String? logMessage,                       // 로그에 남길 커스텀 메시지
    Map<String, String>? fields,              // 추가로 전송할 폼 필드 (옵션)
  }) async {
    // 처리 흐름: URI 생성 → MultipartRequest 생성(POST, URI) → 파일 추가(file, 파일 경로, 파일명) 
    //  → 추가 필드 추가 → 요청 전송 → 응답 검증(200) → JSON 파싱
    // 에러: 모든 예외는 로깅 후 rethrow

    // baseUrl + endpoint 로 전체 URI 생성
    final uri = _buildUri(endpoint);
    LoggerService.debug('API', logMessage ?? 'Multipart POST 요청: $uri');

    try {
      // MultipartRequest 생성(POST, URI)
      final request = http.MultipartRequest('POST', uri);
      // 파일 추가(file, 파일 경로, 파일명)
      request.files.add(
        // 파일 경로로 MultipartFile 생성
        await http.MultipartFile.fromPath(
          'file',
          filePath,
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

      // 응답 처리 (상태 코드 검증, JSON 파싱, 에러 처리)
      return _handleResponse(response, [200]);
    } catch (e, stackTrace) {
      // 네트워크 에러/파싱 에러 등 모든 예외를 로깅 후 rethrow
      _handleError(uri, e, stackTrace, 'Multipart POST 요청 실패');
    }
  }

  /// DELETE 요청 공통 처리
  static Future<void> delete(
    String endpoint, {
    String? logMessage,
  }) async {
    // 처리 흐름: URI 생성 → DELETE 요청 → 응답 검증(200/204) → void 반환
    // 에러: 모든 예외는 로깅 후 rethrow

    // baseUrl + endpoint 로 전체 URI 생성
    final uri = _buildUri(endpoint);

    LoggerService.debug('API', logMessage ?? 'DELETE 요청: $uri');

    try {
      // DELETE 요청 보내기 + 타임아웃 설정
      final response = await http.delete(uri).timeout(
        ApiConfig.timeout,
        onTimeout: () => throw Exception('서버 응답 시간 초과'),
      );

      // 응답 처리 (상태 코드 검증, JSON 파싱, 에러 처리)
      _handleResponse(response, [200, 204], parseJson: false);
    } catch (e, stackTrace) {
      // 네트워크 에러/파싱 에러 등 모든 예외를 로깅 후 rethrow
      _handleError(uri, e, stackTrace, 'DELETE 요청 실패');
    }
  }

  // ========== 공통 헬퍼 메서드 ==========

  /// URI 생성 (baseUrl + endpoint + 쿼리 파라미터)
  static Uri _buildUri(
    String endpoint, {
    Map<String, String>? queryParams,
  }) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    if (queryParams != null) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  /// 응답 처리 (상태 코드 검증, JSON 파싱, 에러 처리)
  static Map<String, dynamic> _handleResponse(
    http.Response response,
    List<int> successCodes, {
    bool parseJson = true,
  }) {
    LoggerService.info('API', '응답 수신 - 상태코드: ${response.statusCode}');

    if (successCodes.contains(response.statusCode)) {
      if (parseJson) {
        try {
          return json.decode(response.body);
        } catch (e) {
          LoggerService.error('API', 'JSON 파싱 실패: ${response.body.substring(0, 100)}', e);
          throw Exception('서버 응답을 파싱할 수 없습니다: $e');
        }
      }
      return {};
    } else {
      LoggerService.warning('API', 'API 오류 응답: ${response.statusCode}');
      LoggerService.warning('API', '응답 본문: ${response.body}');
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

  /// 에러 처리 (로깅 후 rethrow)
  static Never _handleError(
    Uri uri,
    dynamic e,
    StackTrace stackTrace,
    String errorPrefix,
  ) {
    LoggerService.error('API', '$errorPrefix: $uri', e, stackTrace);
    throw e;
  }

  
}