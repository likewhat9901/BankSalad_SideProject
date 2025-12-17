import 'package:flutter/material.dart';

/// 공통 로딩 위젯
/// 화면 중앙에 로딩 스피너를 표시합니다.
class LoadingWidget extends StatelessWidget {
  final String? message;  // 선택적 메시지 (예: "데이터를 불러오는 중...")
  
  const LoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (message != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    return const Center(child: CircularProgressIndicator());
  }
}