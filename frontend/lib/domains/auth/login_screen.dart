// frontend/lib/domains/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../../core/widgets/common/password_field.dart';
import 'widgets/auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 8),
                _buildFindAccountLinks(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 16),
                _buildSignupLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 빌드 헬퍼 메서드들
  Widget _buildHeader() {
    return const Column(
      children: [
        Icon(
          Icons.account_circle,
          size: 80,
          color: Colors.blue,
        ),
        SizedBox(height: 24),
        Text(
          '로그인',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: '아이디',
        hintText: '아이디를 입력하세요',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '아이디를 입력하세요';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return PasswordField(
      controller: _passwordController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호를 입력하세요';
        }
        return null;
      },
    );
  }

  Widget _buildFindAccountLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('아이디 찾기 기능 준비 중')),
            );
          },
          child: const Text('아이디 찾기'),
        ),
        const Text('|'),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('비밀번호 찾기 기능 준비 중')),
            );
          },
          child: const Text('비밀번호 찾기'),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return AuthButton(
      onPressed: _handleLogin,
      isLoading: _isLoading,
      text: '로그인',
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('계정이 없으신가요? '),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignupScreen(),
              ),
            );
          },
          child: const Text('회원가입'),
        ),
      ],
    );
  }

  // 비즈니스 로직
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 백엔드 API 연결
      // await AuthApi.login(
      //   username: _usernameController.text,
      //   password: _passwordController.text,
      // );

      // 임시: 성공 시 홈으로 이동
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 성공')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}