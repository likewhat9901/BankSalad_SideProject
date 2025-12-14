import 'dart:io';
import '../logger_service.dart';
import 'base_api_client.dart';

class UploadApi {
  /// 엑셀 파일 업로드
  static Future<Map<String, dynamic>> uploadExcel(
    String filePath,
    String fileName,
  ) async {
    // 파일 검증
    _validateFile(filePath, fileName);

    LoggerService.info('파일 업로드 시작: $fileName');

    // 파일 업로드
    final result = await BaseApiClient.postMultipart(
      '/upload/excel',
      filePath,
      fileName,
      logMessage: '엑셀 파일 업로드 API 요청: $fileName',
    );

    // 결과 검증 및 처리
    return _processUploadResult(result, fileName);
  }

  /// 파일 검증
  static void _validateFile(String filePath, String fileName) {
    final file = File(filePath);
    
    if (!file.existsSync()) {
      throw Exception('파일을 찾을 수 없습니다: $filePath');
    }

    // 확장자 검증
    if (!fileName.toLowerCase().endsWith('.xlsx') && 
        !fileName.toLowerCase().endsWith('.xls')) {
      throw Exception('엑셀 파일만 업로드 가능합니다 (.xlsx, .xls)');
    }

    // 파일 크기 검증 (예: 10MB 제한)
    final fileSize = file.lengthSync();
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (fileSize > maxSize) {
      throw Exception('파일 크기는 10MB를 초과할 수 없습니다');
    }

    LoggerService.debug('파일 검증 완료: $fileName (${fileSize} bytes)');
  }

  /// 업로드 결과 처리
  static Map<String, dynamic> _processUploadResult(
    Map<String, dynamic> result,
    String fileName,
  ) {
    // 결과 검증
    if (result['status'] != 'success') {
      throw Exception('파일 업로드 실패: ${result['message'] ?? '알 수 없는 오류'}');
    }

    LoggerService.info('파일 업로드 성공: $fileName');
    return result;
  }
}