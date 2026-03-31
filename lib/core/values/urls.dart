class ApiStrings {
  ApiStrings._();

  static const String host = 'https://springgreen-goat-999550.hostingersite.com';

  /// Web client ID from Firebase Console → Authentication → Sign-in method → Google
  /// → Web SDK configuration → Web client ID.
  /// Also found in google-services.json under oauth_client[].client_id where client_type == 3.
  static const String googleServerClientId = '843557523861-t5ugqha6bm2qfdtilc49mh5rh8mdo4ae.apps.googleusercontent.com';
  static const String baseUrl = '$host/api/';
  static const String imageUrl = '$host/public';

  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';
  static const String authorization = 'Authorization';

  static const String applicationJson = 'application/json';
  static const String applicationXWWW = 'application/x-www-form-urlencoded';

  static const String locationApiURL =
      "https://maps.googleapis.com/maps/api/place/autocomplete/json";
}

class ApiPath {
  ApiPath._();

  /// ==============================
  /// CUSTOMER AUTH
  /// ==============================

  static const String register = "customer/register";
  static const String login = "customer/login";
  static const String googleLogin = "customer/social-login";
  static const String me = "customer/me";
  static const String logout = "customer/logout";

  /// ==============================
  /// SERVICES & CATEGORIES
  /// ==============================

  static const String categories = "categories";
  static const String services = "services";

  /// dynamic service details
  static String serviceDetails(int id) => "services/$id";

  /// ==============================
  /// BOOKINGS
  /// ==============================

  static const String createBooking = "bookings";
  static const String storeAddress = "customer/addresses";
  static const String getAddresses = "customer/addresses";
  static String updateAddress(int id) => "customer/addresses/$id";
  static String setDefaultAddress(int id) => "customer/addresses/$id/default";
  static String deleteAddress(int id) => "customer/addresses/$id";
  static const String bookings = "bookings";
  static const String providers = "providers";
  static const String availableProviders = "providers/available-providers";
  static String availableSlots(int providerId) =>
      "providers/$providerId/available-slots";

  static String bookingDetails(int id) => "bookings/$id";

  static String cancelBooking(int id) => "bookings/$id/cancel";

  /// ==============================
  /// PAYMENTS
  /// ==============================

  static const String stripeConfig = "payments/config";
  static const String createCheckoutSession = "payments/create-checkout-session";
  static const String pendingPayments = "payments/pending";
  static const String paymentsRetry = "payments/retry";
  static const String paymentOfBalance = "payments/pay-balance";

  static String retryPayment(int id) => "payments/retry/$id";

  static String payBalance(int bookingId) =>
      "payments/pay-balance/$bookingId";

  static const String paymentHistory = "payments/history";

  /// ==============================
  /// PROVIDER WALLET
  /// ==============================

  static const String providerWallet = "provider/wallet";
  static const String walletTransactions = "provider/wallet/transactions";

  static const String providerBankDetails = "provider/bank-details";
  static const String payoutRequests = "provider/payout-requests";

  /// ==============================
  /// MESSAGING
  /// ==============================

  static const String conversations = "messages/conversations";

  /// ==============================
  /// EXPLORE
  /// ==============================

  static const String explore = "explore";
}
