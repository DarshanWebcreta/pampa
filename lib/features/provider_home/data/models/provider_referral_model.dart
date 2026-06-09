class ReferralRefereeModel {
  final String refereeName;
  final String refereeEmail;
  final String registeredAt;
  final String status;
  final double creditEarned;
  final bool credited;
  final String? creditedAt;

  ReferralRefereeModel({
    required this.refereeName,
    required this.refereeEmail,
    required this.registeredAt,
    required this.status,
    required this.creditEarned,
    required this.credited,
    this.creditedAt,
  });

  factory ReferralRefereeModel.fromJson(Map<String, dynamic> json) {
    return ReferralRefereeModel(
      refereeName: json['referee_name'] as String? ?? '',
      refereeEmail: json['referee_email'] as String? ?? '',
      registeredAt: json['registered_at'] as String? ?? '',
      status: json['status'] as String? ?? '',
      creditEarned: (json['credit_earned'] as num?)?.toDouble() ?? 0.0,
      credited: json['credited'] as bool? ?? false,
      creditedAt: json['credited_at'] as String?,
    );
  }
}

class ProviderReferralModel {
  final int totalReferrals;
  final double totalValue;
  final List<ReferralRefereeModel> referralsList;

  ProviderReferralModel({
    required this.totalReferrals,
    required this.totalValue,
    required this.referralsList,
  });

  factory ProviderReferralModel.fromJson(Map<String, dynamic> json) {
    return ProviderReferralModel(
      totalReferrals: json['total_referrals'] as int? ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      referralsList: (json['referrals_list'] as List<dynamic>?)
              ?.map((e) => ReferralRefereeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
