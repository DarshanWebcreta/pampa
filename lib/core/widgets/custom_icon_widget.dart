import 'package:flutter/material.dart';


import 'package:pampa/core/values/colors.dart';


class CustomIconWidget extends StatelessWidget {
  final IconData icon;
  final Color iconClr;
  final double iconSize;
  final VoidCallback ? ontap;
  final bool circleBackground;
  const CustomIconWidget({this.circleBackground =  false,super.key,this.ontap, required this.icon,  this.iconClr = AppColor.black,  this.iconSize =  20});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: ontap,
        child: Container(

            decoration: !circleBackground?null: const BoxDecoration(
                color: AppColor.lightGrey,
                shape: BoxShape.circle
            ),
            child: Padding(
              padding:  EdgeInsets.all(circleBackground?1:0),
              child: Icon(icon,color: iconClr,size: iconSize,),
            )));
  }
}
