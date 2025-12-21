import 'package:flutter/material.dart';
import '../../core/utils/device/app_launcher_service.dart';
import '../../core/routing/app_route.dart';
import '../upload/widgets/excel_upload_button.dart';
import '../personality/spending_personality_api.dart';
import '../personality/spending_personality.dart';
import '../personality/widgets/spending_personality_card.dart';
import '../../core/logger/logger_service.dart';
import '../../core/widgets/common/loading_widget.dart';
import '../../core/widgets/common/error_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SpendingPersonality? _personality;
  bool _isLoadingPersonality = false;
  String? _personalityError;

  @override
  void initState() {
    super.initState();
    _loadPersonality();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뱅크드레싱'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          _buildLoginButton(context),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 64),
            // 기존 콘텐츠
            Padding(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 16),
                  ExcelUploadButton(
                    onUploadSuccess: () {
                      // 업로드 성공 시 소비 성향 다시 로드
                      _loadPersonality();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 소비 성향 카드
            if (_isLoadingPersonality)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LoadingWidget(),
              )
            else if (_personalityError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorStateWidget(
                  message: _personalityError!,
                  onRetry: _loadPersonality,
                ),
              )
            else if (_personality != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SpendingPersonalityCard(personality: _personality!),
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

  Future<void> _loadPersonality() async {
    setState(() {
      _isLoadingPersonality = true;
      _personalityError = null;
    });

    try {
      final personality = await SpendingPersonalityApi.getSpendingPersonality();
      if (!mounted) return;
      setState(() {
        _personality = personality;
        _isLoadingPersonality = false;
      });
    } catch (e) {
      LoggerService.error('Home', '소비 성향 로드 실패', e);
      if (!mounted) return;
      setState(() {
        _personalityError = '소비 성향을 불러올 수 없습니다';
        _isLoadingPersonality = false;
      });
    }
  }
}