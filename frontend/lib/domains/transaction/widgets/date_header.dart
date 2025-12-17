import 'package:flutter/material.dart';

class DateHeader extends StatelessWidget {
  final String date;  // "2024-12-07" 형식

  const DateHeader({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.parse(date);
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][dateTime.weekday % 7];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '${dateTime.month}월 ${dateTime.day}일 ($weekday)',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}