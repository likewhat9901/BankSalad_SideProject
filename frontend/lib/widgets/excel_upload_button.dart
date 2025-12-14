import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api/upload_api.dart';
import '../services/logger_service.dart';

class ExcelUploadButton extends StatefulWidget {
  final VoidCallback? onUploadSuccess;  // 업로드 성공 후 콜백

  const ExcelUploadButton({super.key, this.onUploadSuccess});

  @override
  State<ExcelUploadButton> createState() => _ExcelUploadButtonState();
}

class _ExcelUploadButtonState extends State<ExcelUploadButton> {
  bool _isUploading = false;

  Future<void> _pickAndUploadExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        LoggerService.info('파일 선택 취소됨');
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        throw Exception('파일 경로를 가져올 수 없습니다');
      }

      setState(() => _isUploading = true);

      final response = await UploadApi.uploadExcel(file.path!, file.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${response['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUploadSuccess?.call();  // 콜백 호출
      }
    } catch (e) {
      LoggerService.error('업로드 실패', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 업로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : _pickAndUploadExcel,
      icon: _isUploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload_file),
      label: Text(_isUploading ? '업로드 중...' : '엑셀 파일 업로드'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }
}