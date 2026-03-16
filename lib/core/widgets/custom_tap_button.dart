
import 'package:flutter/material.dart';


class CustomTapButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hitPadding; // controls tap area

  const CustomTapButton({
    super.key,
    required this.child,
    this.onTap,
    this.hitPadding = 10, // default extra tap area
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(hitPadding),
        child: Center(child: child),
      ),
    );
  }
}
