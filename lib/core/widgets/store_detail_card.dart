import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_card_widget.dart';
import 'package:pampa/core/widgets/custom_icon_widget.dart';
import 'package:pampa/core/widgets/rounded_button.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
class StoreDetailCard extends StatelessWidget {
  const StoreDetailCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CardWidget(elevation: 1,child: Padding(

      padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 14),
      child: Row(spacing: 4,crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('Krishna General Store',fontSize: FontSizes.regular,fontWeight: FontWeights.semiBold,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Padding(

                      padding: const EdgeInsets.only(top: 2),
                      child: CustomIconWidget(icon: Icons.location_on_outlined,iconSize: 14,iconClr: AppColor.darkGrey,),
                    ),
                    Expanded(
                      child: AppText(maxLines: 10,'Flat No. 302, Shanti Apartments  MG Road,Andheri East  Mumbai,Maharashtra – 400069',fontSize: FontSizes.small,fontWeight: FontWeights.regular,
                        color: AppColor.darkGrey,),
                    ),

                  ],
                )
              ],
            ),
          ),
          Row(
            spacing: 9,
            children: [
              RoundedButton(iconSize: 20,bgColor: AppColor.lightPrimaryClr,onTap: () {

              }, icon: CupertinoIcons.phone,radius:8 ,
                iconColor: AppColor.primaryColor,),
              RoundedButton(iconSize: 20,bgColor: AppColor.lightPrimaryClr,onTap: () {

              }, icon: CupertinoIcons.location,radius:8 ,
                iconColor: AppColor.primaryColor,)
            ],
          )
        ],),
    ));
  }
}