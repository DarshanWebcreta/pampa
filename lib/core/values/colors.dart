import 'package:flutter/material.dart';

class AppColor {
  static const Color primaryColor = Color(0xFF5A1837);

  // ── Auth module colors ──────────────────────────────────────────────────────
  static const Color authButton = Color(0xFF5A1837);   // dark wine/maroon
  static const Color authBg     = Color(0xFFF5E6ED);   // light blush pink
  // ────────────────────────────────────────────────────────────────────────────
  static const  black = Colors.black;
  static const  darkGrey = Color(0xFF323232);
  static const  lightBitRed = Color(0xFFFFF5F4);
  static Color  lightPrimaryClr = primaryColor.withValues(alpha: 0.1);


  static const bgcolor = Color(0xFFf5f5f5);
  static  LinearGradient gradiant({List<Color>? colors }) {
    return LinearGradient(

      colors:colors?? [
        Color(0xFFA2E0DD), // bottom color
        bgcolor, // upper color bottom color
      ],
      begin: Alignment.topCenter,

      end: Alignment.bottomCenter,
    );
  }

  static const Color darkBgColor = Color(0xFFE2ECEB);
  static  Color greyWithOpacity = grey.withValues(alpha: 0.4);
  static const Color grey = Color(0xFF888888);
  static const Color lightBitgrey = Color(0xFFf7faf7);
  static const Color lightGrey = Color(0xFFEFEFEF);
  static const Color lightGreen = Color(0xFFe4f5eb);
  static const Color btnGrey = Color(0xFFF5F5F5);
  static const Color inactivesub = Color(0xFFd1ebdb);
  static const Color inactive = Color(0xFFf56e6e);
  static const Color lightPurple = Color(0xFFE7E6FF);
  static const Color purple = Color(0xFFD4D2FF);
  static const Color darkGreen = Color(0xFF2B7672);
  static const Color active = Color(0xFFe8fff3);
  static const Color invoice = Color(0xFFFF755F);
  static  Color lightRed = Colors.red.withValues(alpha: 0.2);
  static const Color mediumGrey = Color(0xFFd1d1d1);
  static const Color green = Color(0xFF59AC40);

  static const Color lightGreentxt = Color(0xFF006400);
  static const Color orange = Colors.orange;
  static const Color lightOrange =  Color(0xFFfff0cc);
  static const Color lightRedtxt = Color(0xFFf1416c);
  static const Color onlineClr = Colors.green;

  static const Color lightblueTxt = Color(0xFF009ef7);
  static const Color blueclr = Color(0xFFf1faff);
  static const Color offline = Colors.red;
  static const Color blue = Color(0xFF04AFFF);
  static const Color offtab = Color(0xFF9C9C9C);
  static const Color white = Colors.white;

  static const Color red = Colors.red;
  static const Color deepRed = Color(0xFFA31616);
  static const Color transperent = Colors.transparent;
  static const Color processing = Color(0xFFC9EC5D);
  static const Color homeLable = Color(0xFFCFF8FF);
  static const Color editClr = Color(0xFF5A63FF);


  static const Color bitLightPurple = Color(0xFFE7E6FF);
  static const Color darkPurple = Color(0xFF0F05FF);
  static const Color bitDarkPurple = Color(0xFFA19DFF);
  static const Color bitPurple = Color(0xFF7F79FF);


  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFfff0eb); // light blue
      case 'cancelled':
        return  lightRed; // light red
      case 'delivered':
        return const Color(0xFFe8fff3); // light green
      case 'modified':
        return const Color(0xFFfff0eb); // light orange
      default:
        return Colors.grey.shade200;
    }
  }


  static Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA500); // blue
      case 'cancelled':
        return const Color(0xFFf1416c); // red
      case 'delivered':
        return const Color(0xFF50cd89); // green
      case 'modified':
        return const Color(0xFFFFA500); // orange
      default:
        return Colors.black87;
    }
  }
}
