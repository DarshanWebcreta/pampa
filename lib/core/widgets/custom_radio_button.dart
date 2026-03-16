import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_card_widget.dart';
import 'package:pampa/core/widgets/custom_icon_widget.dart';
import 'package:pampa/core/widgets/text_widget.dart';

class CustomRadioButton extends StatelessWidget {
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const CustomRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child:CardWidget(

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 6),
          child: Row(

            spacing: 6,
            children: [
             CustomIconWidget(icon: selected?Icons.radio_button_checked:Icons.radio_button_off),
              AppText( value)
            ],
          ),
        ),
      ),
    );
  }
}
