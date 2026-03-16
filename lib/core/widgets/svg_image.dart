


import 'package:flutter/material.dart';

import 'package:flutter_svg/svg.dart';

class SvgImage extends StatelessWidget {
  final String path;
  final double? height;
  final double? width;
  final Color? color;
  const SvgImage({super.key, this.color, this.height, this.width,required this.path});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(path,
        height: height,
        width: width,
        colorFilter:color!=null? ColorFilter.mode(color!, BlendMode.srcIn):null);
  }
}
