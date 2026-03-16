
import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/values/colors.dart';

class CustomButtonWithText extends StatelessWidget {
  final double elevation;
  final double radius;
  final double horiZontalPad;
  final double verticalPad;
  final double txtSize;
  final FontWeight weight;
  final Color? color;
  final bool visaVersa;
  final Color? txtColor;
  final String txt;
  final VoidCallback? callback;
  final Color borderClr;

  const CustomButtonWithText({
    super.key,
    this.elevation = 0,
    required this.radius,
    this.horiZontalPad = 0,
    this.verticalPad = 0,
    this.txtSize = 14,
    this.weight = FontWeight.w500,
    this.color,
    this.visaVersa = false,
    this.txtColor,
    required this.txt,
    this.callback,
    this.borderClr = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = AppColor.primaryColor;
    final Color buttonTxt = AppColor.white;

    return GestureDetector(
      onTap: callback,
      child: Material(
        elevation: elevation,
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: visaVersa ? primary : borderClr,
          ),
        ),
        color: visaVersa ? AppColor.transperent : (color ?? primary),
        child: Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(vertical:verticalPad,horizontal: horiZontalPad),
            child: AppText(
              txt,
              fontSize: txtSize,
              fontWeight: weight,
              color: visaVersa ? primary : (txtColor ?? buttonTxt),
            ),
          ),
        ),
      ),
    );
  }
}
