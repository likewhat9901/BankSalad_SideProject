import 'package:flutter/material.dart';
import '../services/app_launcher_service.dart';

class HomeScreen extends StatelessWidget {  // StatefulWidget → StatelessWidget
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뱅크드레싱'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1, // 테두리 두께 조절 가능
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.asset(
                'assets/images/banksalad_app_icon.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '뱅크샐러드 보조도구 입니다.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('뱅크샐러드 앱에서 엑셀파일을 다운로드 해주세요.'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await AppLauncherService.openBankSalad();
                // 패키지가 알아서 처리함 (앱 없으면 스토어로)
              },
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
            )
          ],
        ),
      ),
    );
  }
}