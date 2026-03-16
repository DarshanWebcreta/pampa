import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/colors.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final Widget? suffixBtn;
  final Widget? prefix;
  final Function(String)? onChanged;
  final String hintText;
  final List<TextInputFormatter>? inputFormatter;
  final Color fillColor;
  final double radius;
  final BorderSide? borderSide;
  final FocusNode? focusNode;
  final Color fontClr;
  final bool verPad;
  final bool errorDisplay;
  final bool obscureText;
  final bool readOnly;
  final bool autovalidate;
  final TextCapitalization textCapitalization;
  final TextInputAction action;
  final TextInputType textInput;
  final Color shadowColor;
  final Color hintColor;
  final FontWeight hintFontWeight;
  final double shadow;
  final double fieldHeight;
  final double hintSize;
  final int maxLine;
  final String? Function(String?)? validator;
  final Color focusColor;
  final Color enableColor;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.label = '',
    this.suffixBtn,
    this.prefix,
    this.onChanged,
    required this.hintText,
     this.inputFormatter ,
    required this.fillColor,
    this.radius = 8,
    this.borderSide,
    this.focusNode,
    this.fontClr = AppColor.grey,
    this.verPad = false,
    this.errorDisplay = false,
    this.obscureText = false,
    this.readOnly = false,
    this.autovalidate = false,
    this.textCapitalization = TextCapitalization.words,
    this.action = TextInputAction.next,
    required this.textInput,
    this.shadowColor = Colors.transparent,
    this.hintColor = AppColor.grey,
    this.hintFontWeight = FontWeight.w500,
    this.shadow = 1,
    this.fieldHeight = 12,
    this.hintSize = 12,
    this.maxLine = 1,
    this.validator,
    required this.focusColor,
    required this.enableColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FunctionalComponent. labelWidget(label),
          ),
        TextFormField(
          readOnly: readOnly,
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLine,
          obscureText: obscureText,
          autovalidateMode:
          autovalidate ? AutovalidateMode.onUserInteraction : null,
          keyboardType: textInput,
          style: customTextStyle(size: 12, weight: FontWeight.w500,clr: fontClr),
          textInputAction: action,
          textCapitalization: hintText.contains('Email')
              ? TextCapitalization.none
              : textCapitalization,
          inputFormatters: inputFormatter,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: prefix,
            suffixIcon: suffixBtn,
            fillColor: fillColor,
            filled: true,
            errorStyle: TextStyle(
              fontSize: errorDisplay ? 12 : 0,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: verPad ? 0 : fieldHeight,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: enableColor),
              borderRadius: BorderRadius.circular(radius),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: focusColor),
              borderRadius: BorderRadius.circular(radius),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: const BorderSide(color: AppColor.red),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: borderSide ?? BorderSide.none,
            ),
            hintText: hintText,
            hintStyle: customTextStyle(

              clr: hintColor,
              size: hintSize,
              weight: hintFontWeight,
            ),
          ),
        ),
      ],
    );
  }
}
