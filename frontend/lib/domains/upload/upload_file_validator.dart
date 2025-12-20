import 'dart:io';
import '../../core/logger/logger_service.dart';

class FileValidator {
  static void validateFile(String filePath, String fileName) {
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

    LoggerService.debug('Upload', '파일 검증 완료: $fileName ($fileSize bytes)');
  }
}