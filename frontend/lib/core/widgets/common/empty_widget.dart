import 'package:flutter/material.dart';

/// 공통 빈 상태 위젯
/// 데이터가 없을 때 표시하는 위젯입니다.
class EmptyWidget extends StatelessWidget {
  final String message;  // 메시지
  final IconData icon;  // 아이콘
  final Color? iconColor;  // 아이콘 색상 (기본: grey.shade400)
  final double? iconSize;  // 아이콘 크기 (기본: 64)
  final String? subMessage;  // 부가 메시지 (선택)
  final Widget? action;  // 액션 위젯 (예: 버튼)

  const EmptyWidget({
    super.key,
    required this.message,
    required this.icon,
    this.iconColor,
    this.iconSize,
    this.subMessage,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize ?? 64,
            color: iconColor ?? Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              subMessage!,
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}