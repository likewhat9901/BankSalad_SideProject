import 'package:flutter/material.dart';
import '../../core/utils/device/app_launcher_service.dart';
import '../../core/routing/app_route.dart';
import '../upload/widgets/excel_upload_button.dart';

class HomeScreen extends StatelessWidget {  // StatefulWidget → StatelessWidget
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뱅크드레싱'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 로그인 버튼 추가
          _buildLoginButton(context),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(),
            const SizedBox(height: 24),
            Text(
              '뱅크샐러드 보조도구 입니다.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('뱅크샐러드 앱에서 엑셀파일을 다운로드 해주세요.'),
            const SizedBox(height: 32),
            _buildBankSaladButton(),
            const SizedBox(height: 16),  // 추가: 버튼 사이 여백
            ExcelUploadButton(  // 추가: 엑셀 파일 업로드 버튼
              onUploadSuccess: () {
                // 업로드 성공 시 할 일 (선택사항)
                // 예: 거래내역 화면으로 이동하거나 메시지 표시
              },
            ),
          ],
        ),
      ),
    );
  }

  // 로그인 버튼 분리
  Widget _buildLoginButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.login);
      },
      icon: const Icon(Icons.login),
      label: const Text('로그인'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
      ),
    );
  }

  // 로고 위젯 분리
  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Image.asset(
        'assets/images/banksalad_app_icon.png',
        width: 80,
        height: 80,
      ),
    );
  }

  // 뱅크샐러드 열기 버튼 분리
  Widget _buildBankSaladButton() {
    return ElevatedButton(
      onPressed: () => AppLauncherService.openBankSalad(),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/Google_PlayStore_favicon.png',
            width: 25,
            height: 25,
          ),
          const SizedBox(width: 8),
          const Text('뱅크샐러드 열기 (Play Store)'),
        ],
      ),
    );
  }
}