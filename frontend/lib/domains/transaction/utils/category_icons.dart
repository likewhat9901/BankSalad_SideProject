import 'package:flutter/material.dart';

/// 카테고리별 아이콘과 색상 맵
class CategoryIcons {
  static const Map<String, Map<String, dynamic>> icons = {
    '미분류': {'icon': Icons.help_outline, 'color': Colors.grey},
    
    // 수입 카테고리
    '급여': {'icon': Icons.account_balance_wallet, 'color': Colors.green},
    '지원금': {'icon': Icons.attach_money, 'color': Colors.green},
    '금융수입': {'icon': Icons.payments, 'color': Colors.green},

    // 지출 카테고리
    '식사': {'icon': Icons.restaurant, 'color': Colors.orange},
    '카페/간식': {'icon': Icons.local_cafe, 'color': Colors.brown},
    '술/유흥': {'icon': Icons.local_bar, 'color': Colors.purple},
    '의복/미용': {'icon': Icons.checkroom, 'color': Colors.pink},
    '문화/여가': {'icon': Icons.movie, 'color': Colors.blue},
    '교통': {'icon': Icons.directions_car, 'color': Colors.teal},
    '생활': {'icon': Icons.shopping_cart, 'color': Colors.indigo},
    '의료/건강': {'icon': Icons.local_hospital, 'color': Colors.red},
    '주거/통신': {'icon': Icons.home, 'color': Colors.cyan},
    '할부': {'icon': Icons.credit_card, 'color': Colors.red},
    '경조사': {'icon': Icons.celebration, 'color': Colors.pink},
    '교육': {'icon': Icons.school, 'color': Colors.blue},
    '기타': {'icon': Icons.category, 'color': Colors.grey},
  };

  /// 카테고리명으로 아이콘과 색상 반환
  static Map<String, dynamic> getIcon(String category) {
    final c = category.toLowerCase();
    for (var key in icons.keys) {
      if (c.contains(key)) return icons[key]!;
    }
    return {'icon': Icons.category, 'color': Colors.grey};
  }
}