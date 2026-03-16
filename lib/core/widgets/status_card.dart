import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_card_widget.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';

class StatusCard extends StatelessWidget {
  final String status;

  const StatusCard({
    required this.status,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CardWidget(color: AppColor.lightGreen,elevation: 0,child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 2),
      child: AppText(status,color: AppColor.green,fontWeight: FontWeights.bold,fontSize: FontSizes.nano,),
    ));
  }
}