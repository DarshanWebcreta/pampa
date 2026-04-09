
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_icon_widget.dart';


import 'package:pampa/core/widgets/gradiant_header.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/utils/operation_method.dart';
import 'package:pampa/core/values/app_text_value.dart';



class CustomHeader extends StatelessWidget {
  final Widget? horiZontalWidget;
  final Widget? verticalWidget;
  final String title;
  final double height;
  final bool homeBack;
  final VoidCallback? onBackTap;
  const CustomHeader({
    super.key,
    this.horiZontalWidget,
    this.homeBack = true,
    this.verticalWidget,
    this.height = 56,
    this.onBackTap,
    required this.title
  });

  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        GradiantHeader(height: height, extraHeight: statusBarHeight,),
        Padding(
          padding: EdgeInsets.only(top: statusBarHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: title.isNotEmpty ? InkWell(onTap: onBackTap ?? () {
                            if(homeBack){
                            }
                            else {
                              OperationMethod.popPage(context);
                            }
                          }, child: Row(
                            spacing: 16,
                            children: [
                              const CustomIconWidget(icon: Icons.arrow_back, iconSize: 20,),
                              Flexible(child: AppText(title, fontWeight: FontWeight.w600, fontSize: FontSizes.medium, maxLines: 1,))
                            ],
                          ),) : SizedBox(),
                        ),
                      ),
                      horiZontalWidget ?? const SizedBox()
                    ],
                  ),
                ),
              ),
              verticalWidget ?? const SizedBox()
            ],
          ),
        ),
      ],
    );
  }
}