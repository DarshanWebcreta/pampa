import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/data/models/provider_payout_request_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_payout_method_provider.dart';

class ProviderPayoutMethodScreen extends StatefulWidget {
  const ProviderPayoutMethodScreen({super.key});

  @override
  State<ProviderPayoutMethodScreen> createState() =>
      _ProviderPayoutMethodScreenState();
}

class _ProviderPayoutMethodScreenState
    extends State<ProviderPayoutMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderPayoutMethodProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProviderPayoutMethodProvider>();
    final error = await provider.createRequest(
      amount: _amountCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    if (error != null && error.isNotEmpty) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: error,
        success: false,
      );
      return;
    }
    _amountCtrl.clear();
    _notesCtrl.clear();
    FunctionalComponent.showSnackBar(
      context: context,
      title: 'Payout request submitted successfully.',
      success: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderPayoutMethodProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F2F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: AppText(
              'Payout Method',
              fontSize: 18,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
          ),
          body: RefreshIndicator(
            onRefresh: provider.refresh,
            color: AppColor.authButton,
            child: _buildBody(provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(ProviderPayoutMethodProvider provider) {
    if (provider.status == ProviderPayoutStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.authButton),
      );
    }
    if (provider.status == ProviderPayoutStatus.error) {
      return _PayoutState(
        icon: Icons.wifi_off_rounded,
        message: provider.error.isNotEmpty
            ? provider.error
            : 'Failed to load payout requests.',
        actionLabel: 'Retry',
        onTap: provider.refresh,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 26),
      children: [
        _RequestCard(
          formKey: _formKey,
          amountCtrl: _amountCtrl,
          notesCtrl: _notesCtrl,
          creating: provider.creating,
          onSubmit: _submit,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            AppText(
              'Payout Requests',
              fontSize: 18,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
            const Spacer(),
            AppText(
              '${provider.total} total',
              fontSize: 12,
              color: AppColor.grey,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (provider.requests.isEmpty)
          const _EmptyRequests()
        else ...[
          ...provider.requests.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RequestItem(item: item),
            ),
          ),
          if (provider.hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton(
                onPressed: provider.loadingMore ? null : provider.loadMore,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: provider.loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Load more'),
              ),
            ),
        ],
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.formKey,
    required this.amountCtrl,
    required this.notesCtrl,
    required this.creating,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController amountCtrl;
  final TextEditingController notesCtrl;
  final bool creating;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEDFE4)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Create payout request',
              fontSize: 16,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 6),
            AppText(
              'Submit payout amount and optional note.',
              fontSize: 12,
              color: AppColor.grey,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            _InputField(
              label: 'Amount',
              hint: '200.00',
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                final amount = double.tryParse(value.trim());
                if (amount == null || amount < 1) return 'Minimum amount is 1';
                return null;
              },
            ),
            const SizedBox(height: 10),
            _InputField(
              label: 'Notes (Optional)',
              hint: 'Monthly payout',
              controller: notesCtrl,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                if (value.length > 500) return 'Max 500 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: creating ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  disabledBackgroundColor: AppColor.authButton.withValues(
                    alpha: 0.6,
                  ),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  const _RequestItem({required this.item});

  final ProviderPayoutRequestModel item;

  @override
  Widget build(BuildContext context) {
    final statusLower = item.status.toLowerCase();
    final bg = switch (statusLower) {
      'approved' => const Color(0xFFE8F7ED),
      'rejected' => const Color(0xFFFDECEC),
      _ => const Color(0xFFFFF4E5),
    };
    final fg = switch (statusLower) {
      'approved' => const Color(0xFF1F8F4C),
      'rejected' => Colors.red.shade700,
      _ => const Color(0xFFB26A00),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEDFE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                '\$${double.parse(item.amount).toStringAsFixed(2)}',
                fontSize: 18,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppText(
            _formatDate(item.createdAt),
            fontSize: 12,
            color: AppColor.grey,
          ),
          if ((item.providerNotes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            AppText(
              item.providerNotes!.trim(),
              fontSize: 13,
              color: AppColor.darkGrey,
              maxLines: 3,
            ),
          ],
          if ((item.adminNotes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            AppText(
              'Admin: ${item.adminNotes!.trim()}',
              fontSize: 12,
              color: AppColor.grey,
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      return DateFormat(
        'dd MMM yyyy, hh:mm a',
      ).format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          fontSize: 12,
          fontWeight: FontWeights.semiBold,
          color: AppColor.darkGrey,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFFFFEFE),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF0DDE5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColor.authButton),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEDFE4)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 38,
            color: AppColor.grey,
          ),
          const SizedBox(height: 10),
          AppText(
            'No payout requests yet',
            fontSize: 14,
            fontWeight: FontWeights.semiBold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 4),
          AppText(
            'Your submitted requests will show up here.',
            fontSize: 12,
            color: AppColor.grey,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PayoutState extends StatelessWidget {
  const _PayoutState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColor.grey),
            const SizedBox(height: 16),
            AppText(
              message,
              fontSize: 14,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 4,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.authButton,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
