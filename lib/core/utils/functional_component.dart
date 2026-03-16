import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/imagepath.dart';
import 'package:pampa/core/values/strings.dart';
import 'package:pampa/core/widgets/custom_button.dart';
import 'package:pampa/core/widgets/custom_card_widget.dart';
import 'package:pampa/core/widgets/custom_divider.dart';
import 'package:pampa/core/widgets/custom_icon_widget.dart';
import 'package:pampa/core/widgets/custom_image.dart';
import 'package:pampa/core/widgets/rounded_button.dart';
import 'package:pampa/core/widgets/text_field_widget.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:toastification/toastification.dart';

class FunctionalComponent {
  FunctionalComponent._();
  static void changeStatusBarColor({Color ? color}){
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: color??AppColor.primaryColor, // status bar color
      statusBarBrightness: Brightness.light, // For iOS: (dark icons)
    ));

  }
  static Widget floatingActionButton({required VoidCallback  onTap}) {
    return RoundedButton(iconColor: AppColor.white,iconSize: 32,bgColor: AppColor.primaryColor,onTap:onTap, icon: Icons.add);
  }
  static void showSnackBar({required BuildContext context,required String title,required bool success}) {
    toastification.dismissAll(delayForAnimation:false);
    toastification.show(

        padding: EdgeInsets.symmetric(horizontal: 16),
        dragToClose: true,

        alignment: Alignment.topCenter,
        backgroundColor:success?AppColor.lightGreentxt:AppColor.inactive,
        closeOnClick: true,
        dismissDirection: DismissDirection.horizontal,

        showProgressBar: false,

        icon: Icon(
          success == true ? Icons.check : Icons.cancel,

          size: 20,
          color: AppColor.white,

        ),

        borderSide: BorderSide.none,
        //  alignment: Alignment.bottomRight,
        closeButtonShowType:CloseButtonShowType.onHover ,
        context: context, // optional if you use ToastificationWrapper
        title: AppText(title,maxLines: 5,color: AppColor.white,fontWeight: FontWeight.w500,fontSize: 13,),
        autoCloseDuration: const Duration(seconds: 3));

  }

  static Widget searchProduct() {
    return CustomTextFormField(
        hintText: "Search Products", fillColor: AppColor.white,
        suffixBtn: SizedBox(
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [

              CustomDivider(direction: DividerDirection.vertical,thickness: 1,length: 30,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomIconWidget(icon: CupertinoIcons.search,iconSize: 24,iconClr: AppColor.grey,),
              )
            ],
          ),
        ),
        textInput: TextInputType.name, focusColor: AppColor.transperent, enableColor: AppColor.transperent);
  }
  static Widget totalBillCardForSummary(
      {
        required String totalRefund,
        required String totalAmount,
        required String refunded,
        required String remainingRefund,
        required bool isRefund,
      }) {
    return  Column(
      children: [
        customRow(
            title: "Grand Total Amount",
            amount: totalAmount,
            titleClr: AppColor.black),



        if(isRefund)  Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: customRow(title: 'Refunded', amount:refunded),
        ),

        if(isRefund)  customRow(title: 'Remainig Refund', amount:remainingRefund),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: customRow(title: 'Delivery Charges', amount:"Free",valClr: AppColor.lightGreentxt),
        ),
        CustomDivider(),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                  'Total Payable',
                  fontSize: FontSizes.small,
                  fontWeight: FontWeights.bold,
                  color: AppColor.grey),
              AppText(
                  "${AppStrings.currencySymbol}${(double.parse(totalAmount)- double.parse(totalRefund)).toStringAsFixed(2)}",
                  fontSize: 11,
                  fontWeight: FontWeights.bold,
                  color: AppColor.black),
            ],
          ),
        )
      ],
    );
  }
  static Widget customRow(
      {required String title,
        required String amount,
        Color titleClr = AppColor.grey,
        Color valClr = AppColor.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
            title, fontSize: FontSizes.small, fontWeight:FontWeights.medium, color: titleClr),
        AppText(
            amount=="Free"?"Free":"${AppStrings.currencySymbol}$amount",
            fontSize: FontSizes.small,
            fontWeight: FontWeights.bold,
            color: valClr),
      ],
    );
  }
  static dynamic cachedNetworkImage(
      String url,
      {double radius = 4.0,
        BoxFit fit = BoxFit.fill,}) {
    return CachedNetworkImage(

      imageUrl: url,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          image: DecorationImage(
            image: imageProvider,
            fit: fit,

          ),
        ),
      ),
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicator(
            color: AppColor.grey,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => AssetImageView(path: ImageStrings.placeHolder),);
  }
  static Widget storeViewTab({required String title,required int index, required int currentTab, required VoidCallback ontap}) {
    return InkWell(
      splashColor: AppColor.transperent,
      onTap: ontap,
      child: CardWidget(
        elevation: 0,
        radius: 12,
        color: currentTab==index?AppColor.white:AppColor.transperent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: AppText(title,fontSize: FontSizes.small,
              fontWeight: FontWeights.semiBold ,),
          ),
        ),
      ),
    );
  }
  static  Future<dynamic> bottomSheet({required BuildContext context,required double height,required Widget child,Color? barrierClr,bool isDismissible =  true,bool canPop =  true,required String title,String descriptrion = ''}) {

    return showModalBottomSheet(
      backgroundColor: AppColor.white,
      isDismissible: isDismissible,
      enableDrag: canPop,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      barrierColor:barrierClr,
      context:context,
      isScrollControlled: true,
      builder: (context) => PopScope(
        canPop: canPop,
        child: Padding(
          padding: EdgeInsets.only(

            bottom: MediaQuery.of(context).viewInsets.bottom,


          ),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child:Stack(
              alignment: AlignmentGeometry.bottomCenter,
              children: [
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if(title.isNotEmpty)   Padding(
                      padding: const EdgeInsets.only(right: 10,left: 16,top: 8,bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(title,fontSize: FontSizes.regular,fontWeight: FontWeights.semiBold,),
                          RoundedButton(icon: CupertinoIcons.clear_thick,iconSize: 20,onTap: () {

                          },)
                        ],
                      ),
                    ),
                    CustomDivider(),
                    child,


                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: CustomButtonWithText(radius: 8,txtColor: AppColor.grey, txt: "Cancel",
                            callback: () {

                            },color: AppColor.lightGrey,),
                        ),
                        Expanded(
                          child: CustomButtonWithText(radius: 8, txt: "Done",
                            callback: () {

                            },color: AppColor.primaryColor,),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ),
        ),
      ),
    );
  }

  static Widget paymentLabelCard({required String amount}) {
    return CardWidget(elevation: 0.5,child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment:  CrossAxisAlignment.start,
            children: [
              AppText("Total Outstanding",
                fontSize: FontSizes.regular,
                fontWeight: FontWeights.medium,color: AppColor.darkGrey,),
              AppText("Rs $amount",
                fontSize: FontSizes.large,
                fontWeight: FontWeights.bold,)
            ],
          ),
          RoundedButton(radius: 12,bgColor: AppColor.lightPrimaryClr,onTap: () {

          }, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppText(AppStrings.currencySymbol,fontSize:FontSizes.large,
              color: AppColor.primaryColor,fontWeight: FontWeight.bold,),
          ),)
        ],
      ),
    ));
  }
  static Widget labelWidget(String label, {double bottomPadding = 0}) {
    final bool requiredField = label.contains("*");

    return Padding(
      padding:  EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          AppText(
            label.replaceAll("*", ""),
            fontSize: 12,
            fontWeight: FontWeights.semiBold,
            color: AppColor.black,
          ),
          AppText(
            requiredField ? "" : " (Optional)",
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: requiredField ? AppColor.red : AppColor.black,
          ),
        ],
      ),
    );
  }
}
