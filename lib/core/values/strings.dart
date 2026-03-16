class AppStrings{
  AppStrings._();
  static const homepageTitle = 'title';
  static const String currencySymbol = '₹';
  static const bool log = true;


  static  void setCategoryTitle(String title) {
    categoryTitle = title;
  }
  static  void setTrialListTitle(String title) {
    trialListing = title;
  }
  static  void setUpcomingOrderTitle(String title) {
    upcomingOrder = title;
  }static  void setBrandTitle(String title) {
    brandTitle = title;
  }


  static  void setBestSellerTitle(String title) {
    bestSeller = title;
  }
  static  void setNewArrivals(String title) {
    newArrival = title;
  }

  static  void setSeasonalProductTitle(String title) {
    seasonalProductTitle = title;
  }

  static const String referText = 'Share with a few , Benefit together.';
  static  String categoryTitle = "Categories";
  static  String trialListing = "Sample Products";
  static  String brandTitle = "Our Brands";
  static  String upcomingOrder = "Upcoming Orders";
  static  String bestSeller = "Best Sellers";
  static  String newArrival = "New Arrivals";
  static  String seasonalProductTitle = "Seasonal Products";
  static const String orderPageError = 'No order found!';
  static const String emptyOrderData = 'No orders yet for this date or status. Check back after placing an order.';
  static const String noPaymentMethod = "No payment methods are available. Please contact your merchant.";
  static const String postPaidMessageForCart = "Balance will be deducted from your wallet.";

  static const String subscriptionPlanBilingTitle = "Subscription billing";
  static const String allProduct = 'All Products';
  static const String locationDialogTitle = 'Location Services Disabled.';
  static const String locationDialogDescription = 'Do you want to enable location services to proceed?';

  static const String productDetails = "Product details";

  static const String cartRemoveTitle = "Product deleted.";
  static const String cartDescriptionWhenDelete = "Your product has been successfully deleted from cart.";

  static const String attributeTitle = "Customize as per your taste";
  static const String easeBuzzMissingParams = 'The required parameter is missing from the vendor. Please contact your vendor for assistance.';
  static const String renewSubscription = "Re-New Subscription";

  static const String featurTitle = 'Featured Products';
  static const String preferenceTitle = "My Preferences";
  static const String vactionModeAction = "You’re currently on vacation mode! You can’t perform this action right now.";
  static const String orderTitle = "My Orders";
  static const String productNotAvailabel = "This product is not available at the moment. Please try again later.";
  static const String productOutOfStock = "We're sorry! This product is currently out of stock. Please check back later.";
  static const String productUnavailable = "Oops! This product is not available at the moment.";
  static const String billingHistoryTitle = 'Billing History';
  static const String rechargeHistoryTitle ="Recharge History";
  static const String subScriptionTitle = 'My Subscription';
  static const String helpTitle = "Help";
  static const String success = 'success';


  static const String emptyProductListMessage = "Unfortunately,This product is unavailable right now. Please try again later!";
  static const String futurePermanentSub = 'Your subscription will be updated with the new quantity from';

  static const String tagforTodayPermanentSub = 'Your subscription will be updated with the new quantity from today.';
  static const String nextDayOFTommorow = 'Your subscription will be updated with the new quantity from next day of tomorrow.';
  static const String modifySubTitle = 'you can modify your subscription for a time being or permanently';
  static const String tagforPermanentSub = 'Your subscription will be updated with the new quantity from tomorrow.';
  static const String orderpage = 'My Orders';
  static const String wallettitle = 'My Wallet';
  static const String cart = 'My Cart';
  static const String cartTitle = 'All items for the day';
  static const String placeOrder = 'Place Order';
  static const String updateOrder = 'Update Quantity';
  static const String updateAppMessage = "New update available! Get the latest features and improvements now.";
  static const String forceUpdateAppMessage = "Important update required! Please update the app to continue using it.";
  static const String emailDescription = 'Please enter a valid email address. Your account will be linked and managed through this email only.';
  static const String paymentProcess = '"Please stay on this screen until your payment is complete"';
  // static const String uID = '2';
  static const String iso = 'IN';
  static const String referEarnTitle = 'Refer & earn';
  static const String sharAndEarn = 'Share & earn';
  static const String termsTitle = 'Terms of Service';
  static const String privacyPolicyTitle = 'Privacy Policy';
  static const String referTitle = 'Rewards Benefits : ';
  static const String emptyAttributeTitle = "No Attribute found!";
  static const String emptyAttributeDescription = "Please try again later or contact support if you need assistance.";

  static const String maintenaceTitle = "We're under maintenance";
  static const String mainTenaceDescription = 'Our app is under maintenance and will be back shortly. Thank you for your patience!';
  static const String components = 'country:$iso';
  static const String shareApp = "Welcome to [Your App Name], your one-stop shop for all your dairy needs. Whether you're craving fresh milk, creamy cheese, rich butter, tangy buttermilk, or pure ghee, we've got it all. Our app offers a seamless shopping experience with a wide variety of high-quality milk-based products. Enjoy the convenience of ordering your favorite dairy items straight from your phone and having them delivered right to your doorstep.";
  static const List lst = [
    //every_day,alternate_day,every_3_day,nth_day,one_time,day_wise
    "every_day",
    "alternate_day",
    "every_3_day",
    "day_wise"
  ];

  static const Map<String, int> daysMap = {
    "sunday": DateTime.sunday,
    "monday": DateTime.monday,
    "tuesday": DateTime.tuesday,
    "wednesday": DateTime.wednesday,
    "thursday": DateTime.thursday,
    "friday": DateTime.friday,
    "saturday": DateTime.saturday,
  };

  static const List categories = [
    'assets/images/category.png',
    'assets/images/veggi.png',
    'assets/images/choco.png',
    'assets/images/cake.png',
    'assets/images/juice.png',
  ];static const List bottomNavBars = [
    "Home",
    "Stores",
    "SKU",
    "Distributor",
    "Attendance",
  ];
  static const List dayName = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
  static const List img = [
    'https://media.istockphoto.com/id/535489242/photo/pouring-milk-in-the-glass-on-the-background-of-nature.jpg?s=612x612&w=0&k=20&c=bqBubtMFs_kv9z0OZVLunl3NFTb_XAVKiw8v1hO1T80=',
    'https://images-prod.healthline.com/hlcmsresource/images/AN_images/healthiest-cheese-1296x728-swiss.jpg',
    'https://t4.ftcdn.net/jpg/06/32/64/95/360_F_632649552_4Gi6jOlnbDllG1qyjKo53lzdFDJNDfhq.jpg',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTi_fgJqimTPJqKPwPUNI8NUew1YwDNl8JpRQ&s',
    'https://vamshifarms.com/cdn/shop/files/gheefalling_2048x.jpg?v=1717574447',
  ];

  // Profile Strings
  static const String myProfile = "My Profile";
  static const String totalStores = "Total stores";
  static const String totalSales = "Total Sales";
  static const String thisMonth = "This Month";
  static const String performance = "Performance";
  static const String basicDetails = "Basic Details";
  static const String territory = "Territory";
  static const String emailAddress = "e-mail address";
  static const String contactNumber = "contact number";
}