import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_card_widget.dart';

import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/widgets/title_with_rate.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';

class ProductDetailInfo extends StatelessWidget {
  const ProductDetailInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(spacing:20 ,children: [
      ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(8),
        child: SizedBox(
          height: 74,
          width:64 ,
          child: CardWidget(radius:12 ,child: Column(children: [
            SizedBox(height: 56,child: FunctionalComponent.cachedNetworkImage(radius: 0,'https://www.jiomart.com/images/product/original/rvavloaden/pink-square-coconut-milk-shampoo-anti-dandruff-and-hair-fall-daily-care-damage-repair-all-hair-types-men-and-women-200-ml-pack-of-2-product-images-orvavloaden-p600982566-1-202304271411.jpg?im=Resize=(420,420)'),),
            Expanded(
              child: ColoredBox(
                color: AppColor.lightPrimaryClr,
                child: Center(
                  child: AppText(
                    '400ml',
                    fontSize: FontSizes.nano,
                    color: AppColor.primaryColor,
                    fontWeight: FontWeights.regular,
                  ),
                ),
              ),
            ),
          ],)),
        ),
      ),

      Expanded(
        child: Column(
          spacing: 10,
          children: [
            AppText('vaseline body lotion intensive care deep restore 40ml ',
              fontSize: FontSizes.small,fontWeight: FontWeights.medium,maxLines: 2,),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TitleWithRate(title: "Rate",price: '48',),
                  TitleWithRate(title: "MRP",price: '48',),
                  TitleWithRate(title: "Margin",price: '48',isMargin: true,),
                  TitleWithRate(title: "Qty",price: '48',),
                ],
              ),
            )

          ],
        ),
      )
    ],);
  }
}