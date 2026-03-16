import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_radio_button.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/theme/app_colors.dart';
import 'package:pampa/core/values/app_text_value.dart';

class CustomRadioGroup extends StatelessWidget {
  final String label;
  final String groupValue;
  final Function(String) onChanged;

  const CustomRadioGroup({
    super.key,
    required this.label,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          fontSize: FontSizes.regular,
          fontWeight: FontWeights.medium,
          color: AppColors.black,
        ),
        SizedBox(height: 6,),
        Row(
          spacing: 18,
          children: [

            CustomRadioButton(
              value: "Yes",
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            CustomRadioButton(
              value: "No",
              groupValue: groupValue,
              onChanged: onChanged,
            ),
          ],
        )
      ],
    );
  }
}