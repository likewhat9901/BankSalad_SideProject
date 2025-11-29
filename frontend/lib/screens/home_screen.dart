import 'package:flutter/material.dart';
import '../widgets/excel_upload_button.dart';

class HomeScreen extends StatelessWidget {  // StatefulWidget → StatelessWidget
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뱅크샐러드'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '뱅크샐러드에 오신 것을 환영합니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('하단 탭에서 거래내역을 확인하세요'),
            const SizedBox(height: 32),
            const ExcelUploadButton(),  // 공통 위젯 사용
          ],
        ),
      ),
    );
  }
}