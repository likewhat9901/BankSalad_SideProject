import 'package:flutter/material.dart';

/// 공통 비밀번호 입력 필드
/// obscureText 토글 기능이 내장되어 있습니다.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.labelText ?? '비밀번호',
        hintText: widget.hintText ?? '비밀번호를 입력하세요',
        prefixIcon: Icon(widget.prefixIcon ?? Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
        border: const OutlineInputBorder(),
      ),
      validator: widget.validator,
    );
  }
}