// frontend/lib/domains/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/widgets/common/password_field.dart';
import '../../core/auth/auth_service.dart';
import 'widgets/auth_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildPasswordConfirmField(),
                const SizedBox(height: 32),
                _buildSignupButton(),
                const SizedBox(height: 16),
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 빌드 헬퍼 메서드들
  Widget _buildHeader() {
    return const Text(
      '회원가입',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
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
        if (value.length < 4) {
          return '아이디는 4자 이상이어야 합니다';
        }
        return null;
      },
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
        if (value.length < 6) {
          return '비밀번호는 6자 이상이어야 합니다';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordConfirmField() {
    return PasswordField( 
      controller: _passwordConfirmController,
      labelText: '비밀번호 확인',
      hintText: '비밀번호를 다시 입력하세요',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호 확인을 입력하세요';
        }
        if (value != _passwordController.text) {
          return '비밀번호가 일치하지 않습니다';
        }
        return null;
      },
    );
  }

  Widget _buildSignupButton() {
    return AuthButton(
      onPressed: _handleSignup,
      isLoading: _isLoading,
      text: '회원가입',
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('이미 계정이 있으신가요? '),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('로그인'),
        ),
      ],
    );
  }

  // 비즈니스 로직
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입 성공'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다';
          break;
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다';
          break;
        case 'invalid-email':
          errorMessage = '이메일 형식이 올바르지 않습니다';
          break;
        default:
          errorMessage = '회원가입 실패: ${e.message}';
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
          content: Text('회원가입 실패: $e'),
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
}