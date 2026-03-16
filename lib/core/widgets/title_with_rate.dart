
import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/strings.dart';

class TitleWithRate extends StatelessWidget {
  const TitleWithRate({
    super.key,
    required this.title, this.isMargin =  false,required this.price,this.displayCurrency =  true,
    this.titleSize = FontSizes.small,
    this.priceSize = FontSizes.small,
    this.titleWeight = FontWeights.regular,
    this.priceWeight = FontWeights.semiBold,
  });
  final String title;
  final String price;
  final bool isMargin ;
  final bool displayCurrency ;
  final double titleSize;
  final double priceSize;
  final FontWeight titleWeight;
  final FontWeight  priceWeight;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       AppText(title,fontSize:titleSize , maxLines: 1,color: AppColor.grey,fontWeight: titleWeight,),
        AppText(fontSize:priceSize ,'${isMargin?"":displayCurrency?AppStrings.currencySymbol:""}$price',maxLines: 1,color: isMargin?AppColor.green:AppColor.black,fontWeight: priceWeight,),
//${isMargin?"%":''}
      ],
    );
  }
}