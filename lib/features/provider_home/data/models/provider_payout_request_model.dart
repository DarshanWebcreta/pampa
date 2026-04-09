class ProviderPayoutRequestModel {
  ProviderPayoutRequestModel({
    required this.id,
    required this.providerId,
    required this.amount,
    required this.status,
    this.providerNotes,
    this.adminNotes,
    this.processedBy,
    this.processedAt,
    required this.createdAt,
  });

  final int id;
  final int providerId;
  final String amount;
  final String status;
  final String? providerNotes;
  final String? adminNotes;
  final int? processedBy;
  final String? processedAt;
  final String createdAt;

  factory ProviderPayoutRequestModel.fromMap(Map<String, dynamic> map) {
    return ProviderPayoutRequestModel(
      id: map['id'] as int? ?? 0,
      providerId: map['provider_id'] as int? ?? 0,
      amount: map['amount']??'',
      status: map['status']?.toString() ?? 'pending',
      providerNotes: map['provider_notes']?.toString(),
      adminNotes: map['admin_notes']?.toString(),
      processedBy: map['processed_by'] as int?,
      processedAt: map['processed_at']?.toString(),
      createdAt: map['created_at']?.toString() ?? '',
    );
  }
}
