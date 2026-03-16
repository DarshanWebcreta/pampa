import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_icon_widget.dart';
import 'package:pampa/core/widgets/elevation_custom_button.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';


class TextWithButton extends StatelessWidget {
  final String value;
  final VoidCallback onpressed;
  final IconData icon;
  final double iconSize;
  final double space;
  const TextWithButton({super.key,this.space = 0,this.iconSize = 18,required this.value,required this.icon,required this.onpressed});

  @override
  Widget build(BuildContext context) {
    return ElevationCustomButton(onPressed:onpressed ,height: 30,bgColor: AppColor.white,widget: Padding(
      padding: const EdgeInsets.only(right: 6,left: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: space,

        children: [
          AppText(value,fontWeight: FontWeights.medium, fontSize: FontSizes.small,color: AppColor.black,),
          CustomIconWidget(icon: icon,iconSize: iconSize,)
        ],
      ),
    ));
  }
}
