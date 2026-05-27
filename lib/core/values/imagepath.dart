class ImagePaths {
  ImagePaths._();
  //    "assets/images/home.svg",
  //     "assets/images/order.svg",
  //     "assets/images/subscription.svg",
  //     "assets/images/wallete.svg",
  //     "assets/images/cart.svg"
  static const imagePath = 'assets/images/';
  static const svgPath = 'assets/svgs/';
  static const lottieAnimationPath = 'assets/animations/';


}


class ImageStrings {
  ImageStrings._();
  static const String splash = '${ImagePaths.imagePath}splash_screen.webp';
  static const String appDesignLogo = '${ImagePaths.imagePath}app_design_logo.png';
  static const String googleLogo = '${ImagePaths.imagePath}google.png';
  static const String logoWithName = '${ImagePaths.imagePath}delivrise_logo_with_name.png';
  static const String placeHolder = '${ImagePaths.imagePath}place_holder.png';
  static const String location = '${ImagePaths.svgPath}location.svg';
  static const String cash = '${ImagePaths.svgPath}cash.svg';
  static const String cheque = '${ImagePaths.svgPath}cheque.svg';
  static const String scanner = '${ImagePaths.svgPath}scanner.svg';
  static const String storeHome = '${ImagePaths.svgPath}store_home.svg';
  static const String clock = '${ImagePaths.svgPath}clock.svg';
  static const String mail = '${ImagePaths.svgPath}mail.svg';
  static const String offer = '${ImagePaths.svgPath}offer.svg';
  static const String checkMark = '${ImagePaths.svgPath}check-mark.svg';
  static const String checkRound = '${ImagePaths.svgPath}check-round.svg';

  static const String attendance   = '${ImagePaths.svgPath}attendance.svg';
  static const String distributor  = '${ImagePaths.svgPath}distributor.svg';
  static const String home         = '${ImagePaths.svgPath}home.svg';
  static const String coupon         = '${ImagePaths.svgPath}coupon.svg';
  static const String sku          = '${ImagePaths.svgPath}sku.svg';
  static const String store        = '${ImagePaths.svgPath}store.svg';
  static const String profile      = '${ImagePaths.svgPath}home.svg'; // Placeholder


  static List<String> get bottomNavIcons => [
    home,
    store,
    sku,
    distributor,
    attendance
  ];

}