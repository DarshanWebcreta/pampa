import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/values/colors.dart';


class ElevationCustomButton extends StatelessWidget {
  final Widget? widget;
  final double? height;
  final double? width;
  final FontWeight weight;
  final VoidCallback? onPressed;
  final double fontSize;
  final double radius;
  final String? title;
  final Color bgColor;
  final bool isBorder;
  final Color? fontClr;
  final Color borderClr;
  const ElevationCustomButton({this.radius = 8,this.borderClr =  AppColor.primaryColor,super.key,this.isBorder =  false,this.fontClr =  AppColor.white,this.title,this.widget,this.fontSize=14,this.weight=FontWeight.w500,this.width,this.bgColor = AppColor.primaryColor,this.height = 52, this.onPressed,});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(

          style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,

              foregroundColor: AppColor.transperent,shadowColor: AppColor.transperent,elevation: 0,shape: RoundedRectangleBorder(
              side: isBorder?BorderSide(width: 1,color:borderClr):BorderSide.none,
              borderRadius: BorderRadiusGeometry.circular(radius)),
              backgroundColor: bgColor),onPressed:onPressed, child: widget??AppText(title??'',fontWeight: weight, fontSize: fontSize,color: fontClr,)),
    );
  }
}
