class BankDetailModel {
  final bool hasBankDetails;
  final String bankName;
  final String accountHolderName;
  final String maskedAccountNumber;
  final String routingNumber;
  final String accountType;
  final bool isVerified;

  BankDetailModel({
    required this.hasBankDetails,
    required this.bankName,
    required this.accountHolderName,
    required this.maskedAccountNumber,
    required this.routingNumber,
    required this.accountType,
    required this.isVerified,
  });

  factory BankDetailModel.fromJson(Map<String, dynamic> json) {
    // API might return details inside 'bank_detail' or directly in 'data'
    final data = json['bank_detail'] ?? json;
    
    return BankDetailModel(
      hasBankDetails: json['has_bank_details'] as bool? ?? (data['bank_name'] != null),
      bankName: data['bank_name'] as String? ?? '',
      accountHolderName: data['account_holder_name'] as String? ?? '',
      maskedAccountNumber: data['masked_account_number'] as String? ?? '',
      routingNumber: data['routing_number'] as String? ?? '',
      accountType: data['account_type'] as String? ?? 'checking',
      isVerified: data['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'masked_account_number': maskedAccountNumber,
      'routing_number': routingNumber,
      'account_type': accountType,
      'is_verified': isVerified,
    };
  }
}
