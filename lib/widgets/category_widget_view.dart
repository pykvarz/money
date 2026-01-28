import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryWidgetView extends StatelessWidget {
  final Category category;

  const CategoryWidgetView({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Color(category.colorValue),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }
}
