import 'package:flutter/material.dart';


enum DividerDirection { horizontal, vertical }

class CustomDivider extends StatelessWidget {
  final double thickness;
  final double length;
  final Color color;
  final DividerDirection direction;

  const CustomDivider({
    super.key,
    this.thickness = 1.0,
    this.length = double.infinity,
    this.color = const Color(0xFFE0E0E0),
    this.direction = DividerDirection.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: direction == DividerDirection.vertical
          ? thickness
          : length,
      height: direction == DividerDirection.horizontal
          ? thickness
          : length,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
