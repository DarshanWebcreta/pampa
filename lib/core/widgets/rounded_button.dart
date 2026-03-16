import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_card_widget.dart';
import 'package:pampa/core/widgets/custom_icon_widget.dart';
import 'package:pampa/core/widgets/svg_image.dart';
import 'package:pampa/core/values/colors.dart';

class RoundedButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData? icon;
  final String? svg;
  final double iconSize;
  final double radius;
  final Color iconColor;
  final Color bgColor;
  final Widget? child;
  const RoundedButton({
    super.key,
     this.onTap,
     this.icon,
     this.svg,
     this.child,
    this.iconSize = 24,
    this.radius = 30,
    this.bgColor = AppColor.white,
    this.iconColor = AppColor.black,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CardWidget(elevation: 0,color: bgColor,radius: radius,child:  Padding(
        padding: const EdgeInsets.all(8.0),
        child:
        svg!=null? SvgImage(path: svg??'',color: iconColor,height: iconSize,width: iconSize,):icon==null?child:
        CustomIconWidget(icon: icon!,iconSize: iconSize,iconClr: iconColor,),
      ),),
    );
  }
}