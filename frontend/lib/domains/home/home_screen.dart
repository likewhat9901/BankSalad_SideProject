import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/device/app_launcher_service.dart';
import '../../core/routing/app_route.dart';
import '../upload/widgets/excel_upload_button.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뱅크드레싱(Beta)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          _buildLoginButton(context),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBody(),
            
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        const SizedBox(height: 128),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 위젯
              _buildLogo(),
              const SizedBox(height: 24),
              // 타이틀 위젯
              Text(
                '당신의 과소비를 분석하세요.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              // 설명 위젯
              const Text('뱅크샐러드 앱에서 엑셀파일을 다운로드 받아 업로드 해주세요.'),
              const SizedBox(height: 32),
              // 뱅크샐러드 앱 열기 버튼
              _buildBankSaladButton(),
              const SizedBox(height: 16),
              // 엑셀 파일 업로드 버튼
              ExcelUploadButton(
                onUploadSuccess: () {
                },
              ),
              const SizedBox(height: 16),
              // 문의하기 버튼
              _buildInquiryButton(),
              const SizedBox(height: 32),
              // 개인정보 처리방침 링크
              _buildPrivacyPolicyLink(),
            ],
          ),
        ),
      ],
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

  // 문의하기 버튼 분리
  Widget _buildInquiryButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.inquiry);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mail_outline, size: 20),
          SizedBox(width: 8),
          Text('문의하기'),
        ],
      ),
    );
  }

  // 개인정보 처리방침 링크 위젯
  Widget _buildPrivacyPolicyLink() {
    return TextButton(
      onPressed: () async {
        const url = 'https://thorn-trip-9a5.notion.site/BankDressing-2d805c9cb68b80529fe2d37ec27fc867?source=copy_link';  // 실제 URL로 변경
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: const Text(
        '개인정보 처리방침',
        style: TextStyle(
          color: Colors.grey,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}