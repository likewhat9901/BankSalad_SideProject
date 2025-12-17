// 웹용 stub - 실제로는 호출되지 않음 (kIsWeb 체크로 보호됨)
class FileValidator {
  static void validateFile(String filePath, String fileName) {
    // 웹에서는 호출되지 않음
    throw UnsupportedError('validateFile은 웹에서 사용할 수 없습니다');
  }
}