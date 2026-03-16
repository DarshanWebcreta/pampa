class ApiStrings {
  ApiStrings._();

  static const String host = 'https://springgreen-goat-999550.hostingersite.com';
  static const String baseUrl = '$host/api/';

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
  static const String bookings = "bookings";
  static const String providers = "providers";
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
}