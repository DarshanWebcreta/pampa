import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/provider_home/data/models/provider_earnings_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_earnings_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_payout_method_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider_payout_method_screen.dart';

class ProviderEarningsTab extends StatefulWidget {
  const ProviderEarningsTab({super.key});

  @override
  State<ProviderEarningsTab> createState() => _ProviderEarningsTabState();
}

class _ProviderEarningsTabState extends State<ProviderEarningsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<ProviderEarningsProvider>().fetchEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: getIt<ProviderEarningsProvider>(),
      child: Consumer<ProviderEarningsProvider>(
        builder: (context, prov, _) {
          return ColoredBox(
            color: const Color(0xFFF5F5F7),
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                Container(
                  color: AppColor.white,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 20,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText(
                          'Earnings',
                          fontSize: 20,
                          fontWeight: FontWeights.bold,
                          color: AppColor.darkGrey,
                        ),
                      ),
                      // GestureDetector(
                      //   onTap: () {},
                      //   child: Container(
                      //     width: 36,
                      //     height: 36,
                      //     decoration: BoxDecoration(
                      //       color: AppColor.authBg,
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: const Icon(Icons.download_rounded,
                      //         size: 18, color: AppColor.darkGrey),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                // ── Body ──────────────────────────────────────────────────
                Expanded(
                  child: prov.loading
                      ? const Center(child: CircularProgressIndicator())
                      : prov.error.isNotEmpty && prov.earnings == null
                      ? _ErrorView(
                          message: prov.error,
                          onRetry: () => prov.fetchEarnings(),
                        )
                      : prov.earnings != null
                      ? RefreshIndicator(
                          onRefresh: prov.fetchEarnings,
                          child: _EarningsBody(earnings: prov.earnings!),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _EarningsBody extends StatelessWidget {
  final ProviderEarningsModel earnings;
  const _EarningsBody({required this.earnings});

  static String _fmt(double v) =>
      '\$${v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Available for Payout (dark card) ─────────────────────────────
        _PayoutCard(available: earnings.wallet.availableForPayout, fmt: _fmt),
        const SizedBox(height: 12),

        // ── Pending card ─────────────────────────────────────────────────
        _PendingCard(pending: earnings.wallet.pending, fmt: _fmt),
        const SizedBox(height: 20),

        // ── This Week ────────────────────────────────────────────────────
        _ThisWeekCard(weekly: earnings.thisWeek, fmt: _fmt),
        const SizedBox(height: 16),

        // ── Breakdown by Service ─────────────────────────────────────────
        if (earnings.serviceBreakdown.isNotEmpty) ...[
          _ServiceBreakdownCard(items: earnings.serviceBreakdown, fmt: _fmt),
          const SizedBox(height: 16),
        ],

        // ── Recent Transactions ──────────────────────────────────────────
        _RecentTransactionsCard(
          transactions: earnings.recentTransactions,
          fmt: _fmt,
        ),
        const SizedBox(height: 16),

        // ── Payment Structure ────────────────────────────────────────────
        // _PaymentStructureCard(structure: earnings.paymentStructure, fmt: _fmt),
      ],
    );
  }
}

// ─── Payout Card (dark) ───────────────────────────────────────────────────────

class _PayoutCard extends StatelessWidget {
  final double available;
  final String Function(double) fmt;
  const _PayoutCard({required this.available, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColor.authButton,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Available for Payout',
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeights.medium,
          ),
          const SizedBox(height: 8),
          Text(
            fmt(available),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: getIt<ProviderPayoutMethodProvider>(),
                      child: const ProviderPayoutMethodScreen(),
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Transfer to Bank',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pending Card ─────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final double pending;
  final String Function(double) fmt;
  const _PendingCard({required this.pending, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9EDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColor.authButton.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                'Pending',
                fontSize: 13,
                color: AppColor.grey,
                fontWeight: FontWeights.medium,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.authButton.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '2–3 days',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColor.authButton,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fmt(pending),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColor.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── This Week Card ───────────────────────────────────────────────────────────

class _ThisWeekCard extends StatelessWidget {
  final EarningsWeeklyData weekly;
  final String Function(double) fmt;
  const _ThisWeekCard({required this.weekly, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final growth = weekly.growth;
    final isPositive = growth >= 0;
    final growthColor = isPositive ? const Color(0xFF2E7D32) : Colors.red;
    final growthBg = isPositive
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    final growthIcon = isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final growthStr = '${isPositive ? '+' : ''}${growth.toInt()}%';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'This Week',
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: growthBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(growthIcon, size: 13, color: growthColor),
                    const SizedBox(width: 3),
                    Text(
                      growthStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: growthColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText(
            '${weekly.weekStart}  –  ${weekly.weekEnd}',
            fontSize: 12,
            color: AppColor.grey,
          ),
          const SizedBox(height: 18),
          _BarChart(data: weekly.chart),
        ],
      ),
    );
  }
}

// ─── Bar Chart ────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<ChartDay> data;
  const _BarChart({required this.data});

  static const double _chartH = 110.0;
  static const double _labelH = 20.0;
  static const double _gap = 6.0;
  static const double _barSpacing = 5.0;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data.map((d) => d.earned).fold(0.0, math.max);

    return LayoutBuilder(
      builder: (_, constraints) {
        return SizedBox(
          height: _chartH + _gap + _labelH,
          child: Column(
            children: [
              // ── Bar area ──────────────────────────────────────────────
              SizedBox(
                height: _chartH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(data.length, (i) {
                    final day = data[i];
                    final ratio = maxVal > 0 ? day.earned / maxVal : 0.0;
                    const labelReserve = 17.0; // label(14) + bottom padding(3)
                    final barH = ratio > 0
                        ? math.max((_chartH - labelReserve) * ratio, 14.0)
                        : 5.0;
                    final isActive = day.earned > 0;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i < data.length - 1 ? _barSpacing : 0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // amount label above active bar
                            if (isActive)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '\$${day.earned.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.authButton,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 14),
                            // bar
                            Container(
                              height: barH,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColor.authButton
                                    : AppColor.authButton.withValues(
                                        alpha: 0.15,
                                      ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: _gap),

              // ── Day labels ────────────────────────────────────────────
              SizedBox(
                height: _labelH,
                child: Row(
                  children: List.generate(data.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i < data.length - 1 ? _barSpacing : 0,
                        ),
                        child: Text(
                          data[i].day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColor.grey,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Service Breakdown Card ───────────────────────────────────────────────────

class _ServiceBreakdownCard extends StatelessWidget {
  final List<EarningsServiceBreakdown> items;
  final String Function(double) fmt;

  static const _dotColors = [
    Color(0xFF490335),
    Color(0xFF1A5A37),
    Color(0xFF1A3757),
    Color(0xFF571A5A),
    Color(0xFF5A4A1A),
    Color(0xFF1A5A5A),
  ];

  const _ServiceBreakdownCard({required this.items, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Breakdown by Service',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 14),
          ...List.generate(items.length, (i) {
            final item = items[i];
            final dot = _dotColors[i % _dotColors.length];
            return Padding(
              padding: EdgeInsets.only(bottom: i < items.length - 1 ? 14 : 0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          item.serviceName,
                          fontSize: FontSizes.regular,
                          fontWeight: FontWeights.semiBold,
                          color: AppColor.darkGrey,
                          maxLines: 1,
                        ),
                        AppText(
                          '${item.count} ${item.count == 1 ? 'service' : 'services'}',
                          fontSize: 12,
                          color: AppColor.grey,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    fmt(item.total),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColor.darkGrey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Recent Transactions Card ─────────────────────────────────────────────────

class _RecentTransactionsCard extends StatelessWidget {
  final List<EarningsTransaction> transactions;
  final String Function(double) fmt;

  const _RecentTransactionsCard({
    required this.transactions,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Recent Transactions',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: AppText(
                  'No transactions yet',
                  fontSize: FontSizes.regular,
                  color: AppColor.grey,
                ),
              ),
            )
          else
            ...List.generate(transactions.length, (i) {
              final tx = transactions[i];
              return Column(
                children: [
                  if (i > 0)
                    Divider(height: 1, color: AppColor.lightGrey, thickness: 1),
                  if (i > 0) const SizedBox(height: 12),
                  _TransactionRow(tx: tx, fmt: fmt),
                  if (i < transactions.length - 1) const SizedBox(height: 12),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final EarningsTransaction tx;
  final String Function(double) fmt;
  const _TransactionRow({required this.tx, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isCompleted = tx.status.toLowerCase() == 'credit';
    final statusColor = isCompleted ? Colors.green : Colors.red;
    final statusBg = isCompleted
        ? Colors.lightGreen.withValues(alpha: 0.1)
        : Colors.red.withValues(alpha: 0.1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColor.authButton.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            tx.customerName.isNotEmpty ? tx.customerName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColor.authButton,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tx.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColor.darkGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tx.serviceCategory != null)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.authButton.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tx.serviceCategory!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColor.authButton,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AppText(
                tx.serviceName,
                fontSize: 12,
                color: AppColor.grey,
                maxLines: 1,
              ),
              if (tx.date.isNotEmpty) ...[
                const SizedBox(height: 2),
                AppText(tx.date, fontSize: 11, color: AppColor.mediumGrey),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Amount + status
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              fmt(tx.amount),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.darkGrey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                tx.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Payment Structure Card ───────────────────────────────────────────────────

class _PaymentStructureCard extends StatelessWidget {
  final EarningsPaymentStructure structure;
  final String Function(double) fmt;

  const _PaymentStructureCard({required this.structure, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Payment Structure',
            fontSize: FontSizes.medium,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 14),
          _StructureRow(
            label: 'Deposits Collected',
            value: fmt(structure.depositsCollected),
          ),
          const SizedBox(height: 1),
          Divider(height: 20, color: AppColor.lightGrey, thickness: 1),
          _StructureRow(
            label: 'Final Payments',
            value: fmt(structure.finalPayments),
          ),
        ],
      ),
    );
  }
}

class _StructureRow extends StatelessWidget {
  final String label;
  final String value;
  const _StructureRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(label, fontSize: FontSizes.regular, color: AppColor.grey),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColor.darkGrey,
          ),
        ),
      ],
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColor.grey),
            const SizedBox(height: 16),
            AppText(
              message,
              fontSize: FontSizes.regular,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.authButton,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
