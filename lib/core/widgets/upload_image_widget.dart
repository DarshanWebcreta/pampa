import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pampa/core/widgets/custom_button.dart';
import 'package:pampa/core/widgets/custom_icon_widget.dart';
import 'package:pampa/core/widgets/dotted_border.dart';
import 'package:pampa/core/widgets/rounded_button.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
class UploadImageWidget extends StatelessWidget {
  final String title;
  final String description;
  final bool scanner;
  const UploadImageWidget({
    super.key,
    required this.title,
     this.scanner =  false,
    required this.description ,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedBorderPainter(
          radius: 16,
          color: AppColor.primaryColor,
          dashGap: 2
      ),
      child: Container(
        width: double.infinity,
        color: AppColor.lightPrimaryClr,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            scanner?CustomIconWidget(icon: Icons.qr_code_2_sharp,iconSize: 150,):RoundedButton(icon: CupertinoIcons.camera,iconSize: 26,
              iconColor: AppColor.primaryColor,bgColor: AppColor.lightPrimaryClr,),

            const SizedBox(height: 10),
             AppText(
              "Upload $title Image",
              fontSize: FontSizes.medium,fontWeight:  FontWeights.semiBold,
            ),
            const SizedBox(height: 5),
             AppText(
             description,

              fontSize: FontSizes.small,fontWeight:  FontWeights.medium,
              color: AppColor.grey,
            ),

            const SizedBox(height: 15),
            SizedBox(
                height: 32,width: 120,
                child: CustomButtonWithText(color: AppColor.primaryColor,radius: 100, txt: "Take a Photo"))
          ],
        ),
      ),
    );
  }
}