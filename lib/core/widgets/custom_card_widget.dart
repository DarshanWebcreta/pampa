import 'package:flutter/material.dart';
import 'package:pampa/core/values/colors.dart';

class CardWidget extends StatelessWidget {
  final double radius ;
  final double elevation;
  final Widget child;
  final Color color;
  const CardWidget({
    super.key,
    required this.child,
    this.color = AppColor.white,
    this.radius = 12,
    this.elevation = 0
  });

  @override
  Widget build(BuildContext context) {
    return Card(margin: EdgeInsets.zero,color: color,shadowColor: AppColor.white,shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(radius),),
      elevation: elevation,child:child,);
  }
}