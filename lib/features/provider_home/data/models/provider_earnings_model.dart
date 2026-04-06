class WalletData {
  final double availableForPayout;
  final double pending;
  final double totalEarned;
  final double totalWithdrawn;

  WalletData({
    required this.availableForPayout,
    required this.pending,
    required this.totalEarned,
    required this.totalWithdrawn,
  });

  factory WalletData.fromMap(Map<String, dynamic> map) => WalletData(
        availableForPayout:
            (map['available_for_payout'] as num?)?.toDouble() ?? 0,
        pending: (map['pending'] as num?)?.toDouble() ?? 0,
        totalEarned: (map['total_earned'] as num?)?.toDouble() ?? 0,
        totalWithdrawn: (map['total_withdrawn'] as num?)?.toDouble() ?? 0,
      );
}

class ChartDay {
  final String day;
  final String date;
  final double earned;

  ChartDay({required this.day, required this.date, required this.earned});

  factory ChartDay.fromMap(Map<String, dynamic> map) => ChartDay(
        day: map['day'] as String? ?? '',
        date: map['date'] as String? ?? '',
        earned: (map['earned'] as num?)?.toDouble() ?? 0,
      );
}

class EarningsWeeklyData {
  final double total;
  final double growth;
  final String weekStart;
  final String weekEnd;
  final List<ChartDay> chart;

  EarningsWeeklyData({
    required this.total,
    required this.growth,
    required this.weekStart,
    required this.weekEnd,
    required this.chart,
  });

  factory EarningsWeeklyData.fromMap(Map<String, dynamic> map) =>
      EarningsWeeklyData(
        total: (map['total'] as num?)?.toDouble() ?? 0,
        growth: (map['growth'] as num?)?.toDouble() ?? 0,
        weekStart: map['week_start'] as String? ?? '',
        weekEnd: map['week_end'] as String? ?? '',
        chart: (map['chart'] as List<dynamic>?)
                ?.map((e) => ChartDay.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class EarningsServiceBreakdown {
  final int serviceId;
  final String serviceName;
  final int count;
  final double total;

  EarningsServiceBreakdown({
    required this.serviceId,
    required this.serviceName,
    required this.count,
    required this.total,
  });

  factory EarningsServiceBreakdown.fromMap(Map<String, dynamic> map) =>
      EarningsServiceBreakdown(
        serviceId: map['service_id'] as int? ?? 0,
        serviceName: map['service_name'] as String? ?? '',
        count: map['count'] as int? ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
      );
}

class EarningsTransaction {
  final String customerName;
  final String serviceName;
  final String? serviceCategory;
  final double amount;
  final String status;
  final String date;

  EarningsTransaction({
    required this.customerName,
    required this.serviceName,
    this.serviceCategory,
    required this.amount,
    required this.status,
    required this.date,
  });

  factory EarningsTransaction.fromMap(Map<String, dynamic> map) =>
      EarningsTransaction(
        customerName: map['customer_name'] as String? ?? '',
        serviceName: map['service_name'] as String? ?? '',
        serviceCategory: map['service_category'] as String?,
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        status: map['status'] as String? ?? '',
        date: map['date'] as String? ?? '',
      );
}

class EarningsPaymentStructure {
  final double depositsCollected;
  final double finalPayments;

  EarningsPaymentStructure({
    required this.depositsCollected,
    required this.finalPayments,
  });

  factory EarningsPaymentStructure.fromMap(Map<String, dynamic> map) =>
      EarningsPaymentStructure(
        depositsCollected:
            (map['deposits_collected'] as num?)?.toDouble() ?? 0,
        finalPayments: (map['final_payments'] as num?)?.toDouble() ?? 0,
      );
}

class ProviderEarningsModel {
  final WalletData wallet;
  final EarningsWeeklyData thisWeek;
  final List<EarningsServiceBreakdown> serviceBreakdown;
  final List<EarningsTransaction> recentTransactions;
  final EarningsPaymentStructure paymentStructure;

  ProviderEarningsModel({
    required this.wallet,
    required this.thisWeek,
    required this.serviceBreakdown,
    required this.recentTransactions,
    required this.paymentStructure,
  });

  factory ProviderEarningsModel.fromMap(Map<String, dynamic> data) =>
      ProviderEarningsModel(
        wallet: WalletData.fromMap(data['wallet'] as Map<String, dynamic>),
        thisWeek: EarningsWeeklyData.fromMap(
            data['this_week'] as Map<String, dynamic>),
        serviceBreakdown: (data['service_breakdown'] as List<dynamic>?)
                ?.map((e) => EarningsServiceBreakdown.fromMap(
                    e as Map<String, dynamic>))
                .toList() ??
            [],
        recentTransactions: (data['recent_transactions'] as List<dynamic>?)
                ?.map((e) =>
                    EarningsTransaction.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        paymentStructure: EarningsPaymentStructure.fromMap(
            data['payment_structure'] as Map<String, dynamic>),
      );
}
