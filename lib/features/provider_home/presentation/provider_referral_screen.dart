import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/data/models/provider_referral_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_referral_provider.dart';

class ProviderReferralScreen extends StatefulWidget {
  const ProviderReferralScreen({super.key});

  @override
  State<ProviderReferralScreen> createState() => _ProviderReferralScreenState();
}

class _ProviderReferralScreenState extends State<ProviderReferralScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderReferralProvider>().fetchReferralStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderReferralProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9F3F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: AppText(
              'Referrals',
              fontSize: 18,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(ProviderReferralProvider provider) {
    if (provider.status == ReferralStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.authButton),
      );
    }

    if (provider.status == ReferralStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColor.grey),
              const SizedBox(height: 16),
              AppText(
                provider.error,
                fontSize: 14,
                color: AppColor.grey,
                align: TextAlign.center,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: provider.fetchReferralStats,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = provider.referralData;
    if (data == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      color: AppColor.authButton,
      onRefresh: provider.fetchReferralStats,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildStatsRow(data),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColor.darkGrey,
              ),
              const SizedBox(width: 8),
              AppText(
                'Referral History',
                fontSize: 15,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.referralsList.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.referralsList.length,
              itemBuilder: (context, index) {
                return _RefereeItemCard(referee: data.referralsList[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ProviderReferralModel data) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Referrals',
            value: '${data.totalReferrals}',
            icon: Icons.group_rounded,
            iconColor: const Color(0xFF5A1837),
            bgColor: const Color(0xFFF9EFF2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Credits Earned',
            value: '\$${data.totalValue.toStringAsFixed(2)}',
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFF00897B),
            bgColor: const Color(0xFFE0F2F1),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E4E8)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: AppColor.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          AppText(
            'No referrals yet',
            fontSize: 14,
            fontWeight: FontWeights.semiBold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 6),
          AppText(
            'Share your referral code with others to earn credits!',
            fontSize: 12,
            color: AppColor.grey,
            align: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E4E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColor.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColor.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefereeItemCard extends StatelessWidget {
  final ReferralRefereeModel referee;

  const _RefereeItemCard({required this.referee});

  @override
  Widget build(BuildContext context) {
    final isActive = referee.status.toLowerCase() == 'active';
    final statusColor = isActive ? const Color(0xFF2E7D32) : AppColor.grey;
    final statusBgColor = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referee.refereeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      referee.refereeEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+\$${referee.creditEarned.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      referee.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFF5EBEF)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registered: ${_formatDate(referee.registeredAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColor.grey,
                ),
              ),
              if (referee.credited)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: Color(0xFF00897B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      referee.creditedAt != null
                          ? 'Credited ${_formatDate(referee.creditedAt!)}'
                          : 'Credited',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00897B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Pending Credit',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFF57C00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      // Input formats e.g. "2026-06-09 13:12:00" or ISO format
      // Return a simpler representation like "Jun 9, 2026"
      final parts = dateStr.split(' ');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          final year = dateParts[0];
          final monthInt = int.tryParse(dateParts[1]);
          final day = dateParts[2];
          final months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          if (monthInt != null && monthInt >= 1 && monthInt <= 12) {
            return '${months[monthInt - 1]} ${int.parse(day)}, $year';
          }
        }
      }
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }
}
