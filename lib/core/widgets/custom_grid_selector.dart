
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:pampa/core/widgets/custom_divider.dart';
import 'package:pampa/core/widgets/elevation_custom_button.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';


class CustomGridSelector<T> extends StatefulWidget {
  final String title;
  final List<T> options;
  final T selectedValue;
  final void Function(T value) onSelected;
  final String Function(T value)? labelBuilder;

  const CustomGridSelector({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.labelBuilder,
  });

  @override
  State<CustomGridSelector<T>> createState() => _CustomGridSelectorState<T>();
}

class _CustomGridSelectorState<T> extends State<CustomGridSelector<T>> {
  late T tempSelected;

  @override
  void initState() {
    super.initState();
    tempSelected = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: AppColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText( widget.title,fontWeight: FontWeights.medium, fontSize: FontSizes.medium).paddingSymmetric(
              vertical: 16
          ),
          CustomDivider(thickness: 1,color: AppColor.grey,).paddingOnly(bottom: 18),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true, // Required to avoid infinite height error in dialogs
            mainAxisSpacing: 8,
            crossAxisSpacing: 6,
            childAspectRatio: 2.5, // Adjust to control item width/height
            physics: const NeverScrollableScrollPhysics(),
            children: widget.options.map((value) {
              final isSelected = value == tempSelected;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    tempSelected = value;
                  });
                },
                child: Container(
                  padding:  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColor.primaryColor : AppColor.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                      child: AppText( widget.labelBuilder?.call(value) ?? value.toString(),color: isSelected ?AppColor.white:null ,fontWeight: FontWeights.medium, fontSize: FontSizes.small)
                  ),
                ),
              );
            }).toList(),
          ).paddingSymmetric(horizontal: 12),

          const SizedBox(height: 20),
          ElevationCustomButton(height: 52,width: double.infinity,title:"Done",fontClr: AppColor.white ,fontSize: FontSizes.regular,onPressed: () {
            Navigator.pop(context);
            widget.onSelected(tempSelected); // Call onSelected only on Done
          },).paddingAll(16)
        ],
      ),
    );
  }
}
