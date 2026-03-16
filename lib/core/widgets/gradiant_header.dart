
import 'package:flutter/material.dart';

import 'package:pampa/core/values/colors.dart';


class GradiantHeader extends StatelessWidget {
  final double height;
  final double extraHeight;
  const GradiantHeader({super.key,this.height = 150, this.extraHeight = 0});

  @override
  Widget build(BuildContext context) {
    return   SizedBox(
        height: height + extraHeight,
        width: double.infinity,
        child: Container(

          decoration: BoxDecoration(
            gradient: AppColor.gradiant( // slightly darker teal)
            ),
          ),
        ));
  }
}
