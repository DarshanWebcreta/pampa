import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_card_widget.dart';
import 'package:pampa/core/widgets/custom_divider.dart';
import 'package:pampa/core/widgets/product_detail_card.dart';
import 'package:pampa/core/widgets/text_widget.dart';

import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';

class ProductWithVarient extends StatelessWidget {
  const ProductWithVarient({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            ProductDetailInfo(),
            CustomDivider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                ...['','','',].map((e) => CardWidget(
                  color: AppColor.primaryColor,
                  radius: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18,vertical: 4),
                    child: AppText("200 ml",color: AppColor.white,fontSize: FontSizes.mini,),
                  ),
                ))
              ],
            )
          ],
        ),
      ),
    );
  }
}