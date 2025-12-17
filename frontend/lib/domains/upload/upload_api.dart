import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/logger/logger_service.dart';
import '../../core/api/api_client.dart';

// 조건부 import: 모바일에서는 실제 구현, 웹에서는 stub
import 'upload_file_validator.dart' if (dart.library.html) 'upload_file_validator_stub.dart' as validator;

class UploadApi {
  /// 엑셀 파일 업로드 (모바일용 - 파일 경로 사용)
  static Future<Map<String, dynamic>> uploadExcel(
    String filePath,
    String fileName,
  ) async {
    // 확장자 검증 (웹/모바일 공통)
    _validateFileName(fileName);

    // 파일 검증 (모바일에서만)
    if (!kIsWeb) {
      validator.FileValidator.validateFile(filePath, fileName);
    }

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

  /// 엑셀 파일 업로드 (웹용 - 바이트 사용)
  static Future<Map<String, dynamic>> uploadExcelBytes(
    Uint8List fileBytes,
    String fileName,
  ) async {
    // 파일 검증
    _validateFileBytes(fileBytes, fileName);

    LoggerService.info('파일 업로드 시작: $fileName');

    // 파일 업로드
    final result = await BaseApiClient.postMultipartBytes(
      '/upload/excel',
      fileBytes,
      fileName,
      logMessage: '엑셀 파일 업로드 API 요청: $fileName',
    );

    // 결과 검증 및 처리
    return _processUploadResult(result, fileName);
  }

  /// 파일명 검증 (확장자만 체크 - 웹/모바일 공통)
  static void _validateFileName(String fileName) {
    if (!fileName.toLowerCase().endsWith('.xlsx') && 
        !fileName.toLowerCase().endsWith('.xls')) {
      throw Exception('엑셀 파일만 업로드 가능합니다 (.xlsx, .xls)');
    }
  }

  /// 파일 검증 (웹용)
  static void _validateFileBytes(Uint8List fileBytes, String fileName) {
    // 확장자 검증
    _validateFileName(fileName);

    // 파일 크기 검증 (예: 10MB 제한)
    final fileSize = fileBytes.length;
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (fileSize > maxSize) {
      throw Exception('파일 크기는 10MB를 초과할 수 없습니다');
    }

    LoggerService.debug('파일 검증 완료: $fileName ($fileSize bytes)');
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