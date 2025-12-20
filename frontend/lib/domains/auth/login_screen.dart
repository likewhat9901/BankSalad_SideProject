// frontend/lib/domains/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routing/app_route.dart';
import '../../core/widgets/common/password_field.dart';
import '../../core/auth/auth_service.dart';
import 'widgets/auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
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
                _buildEmailField(),
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: '이메일',
        hintText: '이메일을 입력하세요',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '이메일을 입력하세요';
        }
        if (!value.contains('@')) {
          return '올바른 이메일 형식이 아닙니다';
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
          onPressed: _handlePasswordReset,
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
            Navigator.pushNamed(context, AppRoutes.signup);
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
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 성공'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = '등록되지 않은 이메일입니다';
          break;
        case 'wrong-password':
          errorMessage = '비밀번호가 잘못되었습니다';
          break;
        case 'invalid-email':
          errorMessage = '이메일 형식이 올바르지 않습니다';
          break;
        case 'user-disabled':
          errorMessage = '비활성화된 계정입니다';
          break;
        case 'too-many-requests':
          errorMessage = '너무 많은 시도가 있었습니다. 나중에 다시 시도해주세요';
          break;
        default:
          errorMessage = '로그인 실패: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호 재설정 이메일을 발송했습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이메일 발송 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}