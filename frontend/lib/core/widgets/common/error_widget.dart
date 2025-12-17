import 'package:flutter/material.dart';

/// 공통 에러 위젯
/// 에러 아이콘, 메시지, 다시 시도 버튼을 표시합니다.
class ErrorStateWidget extends StatelessWidget {
  final String message;  // 에러 메시지
  final VoidCallback onRetry;  // 다시 시도 콜백
  final IconData? icon;  // 커스텀 아이콘 (기본: error_outline)
  final double? iconSize;  // 아이콘 크기 (기본: 48)

  const ErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.error_outline,
            size: iconSize ?? 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}