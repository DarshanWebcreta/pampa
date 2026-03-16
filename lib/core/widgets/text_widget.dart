import 'package:flutter/material.dart';
import 'package:pampa/core/theme/app_colors.dart';
import 'package:pampa/core/values/app_text_value.dart';

import 'package:flutter/material.dart';
import 'package:pampa/core/theme/app_colors.dart';
import 'package:pampa/core/values/app_text_value.dart';

class AppText extends StatelessWidget {
  final String txt;
  final String? fontFamily;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? align;
  final TextDecoration decoration;
  final int? maxLines;

  const AppText(
      this.txt, {
        super.key,
        this.fontSize,
        this.fontFamily,
        this.fontWeight,
        this.color,
        this.decoration =TextDecoration.none,
        this.align,
        this.maxLines = 1,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      txt,
      textAlign: align?? TextAlign.start,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: customTextStyle(
        size: fontSize ?? FontSizes.regular,
        weight: fontWeight ?? FontWeights.regular,
        clr: color ?? AppColors.black,
        fontFamily: fontFamily,
          decor:decoration

      ),
    );
  }
}

TextStyle customTextStyle({double size = 12,Color clr = Colors.white,FontWeight weight= FontWeight.w400,TextDecoration decor= TextDecoration.none,
String?fontFamily}) {
  return TextStyle(
    //openSans
      color: clr,
      fontSize: size,
      decoration: decor,
      fontWeight: weight,
      fontFamily: fontFamily??'Inter'
  );
}

