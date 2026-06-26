import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_pricing_provider.dart';

class ProviderPricingScreen extends StatefulWidget {
  const ProviderPricingScreen({super.key});

  @override
  State<ProviderPricingScreen> createState() => _ProviderPricingScreenState();
}

class _ProviderPricingScreenState extends State<ProviderPricingScreen> {
  final _generalPricingFormKey = GlobalKey<FormState>();

  late final TextEditingController _perKmCtrl;
  late final TextEditingController _distanceCtrl;
  late final TextEditingController _priorityFeeCtrl;
  late final TextEditingController _depositCtrl;

  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, TextEditingController> _durationControllers = {};

  @override
  void initState() {
    super.initState();
    _perKmCtrl = TextEditingController();
    _distanceCtrl = TextEditingController();
    _priorityFeeCtrl = TextEditingController();
    _depositCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderPricingProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _perKmCtrl.dispose();
    _distanceCtrl.dispose();
    _priorityFeeCtrl.dispose();
    _depositCtrl.dispose();
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _durationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(ProviderPricingProvider provider) {
    if (_perKmCtrl.text != provider.perKmCharge) {
      _perKmCtrl.text = provider.perKmCharge;
    }
    if (_distanceCtrl.text != provider.maxServiceDistance) {
      _distanceCtrl.text = provider.maxServiceDistance;
    }
    if (_priorityFeeCtrl.text != provider.priorityFee) {
      _priorityFeeCtrl.text = provider.priorityFee;
    }
    if (_depositCtrl.text != provider.depositRequired) {
      _depositCtrl.text = provider.depositRequired;
    }

    for (final draft in provider.services) {
      _priceControllers.putIfAbsent(
        draft.service.id,
        () => TextEditingController(text: draft.price),
      );
      _durationControllers.putIfAbsent(
        draft.service.id,
        () => TextEditingController(text: draft.duration),
      );
      if (_priceControllers[draft.service.id]!.text != draft.price) {
        _priceControllers[draft.service.id]!.text = draft.price;
      }
      if (_durationControllers[draft.service.id]!.text != draft.duration) {
        _durationControllers[draft.service.id]!.text = draft.duration;
      }
    }
  }

  Future<void> _saveGeneralPricing() async {
    if (!_generalPricingFormKey.currentState!.validate()) return;

    final provider = context.read<ProviderPricingProvider>();
    provider.updateGeneralPricing(
      perKmCharge: _perKmCtrl.text.trim(),
      maxServiceDistance: _distanceCtrl.text.trim(),
      priorityFee: _priorityFeeCtrl.text.trim(),
      depositRequired: _depositCtrl.text.trim(),
    );

    final error = await provider.saveGeneralPricing();
    if (!mounted) return;

    if (error != null && error.isNotEmpty) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: error,
        success: false,
      );
      return;
    }

    FunctionalComponent.showSnackBar(
      context: context,
      title: 'Pricing settings updated successfully.',
      success: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderPricingProvider>(
      builder: (context, provider, _) {
        _syncControllers(provider);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F3F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: AppText(
              'Pricing',
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

  Widget _buildBody(ProviderPricingProvider provider) {
    switch (provider.status) {
      case ProviderPricingStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColor.authButton),
        );
      case ProviderPricingStatus.error:
        return _PricingState(
          icon: Icons.wifi_off_rounded,
          message: provider.error.isNotEmpty
              ? provider.error
              : 'Failed to load pricing settings.',
          actionLabel: 'Retry',
          onTap: () => provider.initialize(forceRefresh: true),
        );
      case ProviderPricingStatus.empty:
        return _PricingState(
          icon: Icons.design_services_outlined,
          message:
              'No services available yet. Add services first to price them here.',
          actionLabel: 'Refresh',
          onTap: () => provider.initialize(forceRefresh: true),
        );
      case ProviderPricingStatus.initial:
        return const SizedBox.shrink();
      case ProviderPricingStatus.success:
        final groups = provider.groupedServices;
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
          children: [
            Form(
              key: _generalPricingFormKey,
              child: _TopIntro(
                perKmCtrl: _perKmCtrl,
                distanceCtrl: _distanceCtrl,
                priorityFeeCtrl: _priorityFeeCtrl,
                depositCtrl: _depositCtrl,
                saving: provider.savingGeneralPricing,
                onSave: _saveGeneralPricing,
              ),
            ),
            const SizedBox(height: 16),
            ...groups.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CategoryPricingGroup(
                  categoryName: entry.key,
                  drafts: entry.value,
                  priceControllers: _priceControllers,
                  durationControllers: _durationControllers,
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _TopIntro extends StatelessWidget {
  const _TopIntro({
    required this.perKmCtrl,
    required this.distanceCtrl,
    required this.priorityFeeCtrl,
    required this.depositCtrl,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController perKmCtrl;
  final TextEditingController distanceCtrl;
  final TextEditingController priorityFeeCtrl;
  final TextEditingController depositCtrl;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBDDE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Set your pricing',
            fontSize: 24,
            fontWeight: FontWeights.bold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 6),
          AppText(
            'Set a starting price. You can customize per client.',
            fontSize: 13,
            color: AppColor.grey,
            maxLines: 2,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PricingField(
                  controller: perKmCtrl,
                  label: 'Per miles charge',
                  hint: '15',
                  prefix: '\$',
                  validator: _numberValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PricingField(
                  controller: distanceCtrl,
                  label: 'Max distance (miles)',
                  hint: '25',
                  validator: _intValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PricingField(
                  controller: priorityFeeCtrl,
                  label: 'Priority fee (%)',
                  hint: '10',
                  validator: _percentValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PricingField(
                  controller: depositCtrl,
                  label: 'Deposit required (%)',
                  hint: '20',
                  validator: _percentValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.authButton,
                disabledBackgroundColor: AppColor.authButton.withValues(
                  alpha: 0.6,
                ),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Pricing Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPricingGroup extends StatelessWidget {
  const _CategoryPricingGroup({
    required this.categoryName,
    required this.drafts,
    required this.priceControllers,
    required this.durationControllers,
  });

  final String categoryName;
  final List<ServicePricingDraft> drafts;
  final Map<int, TextEditingController> priceControllers;
  final Map<int, TextEditingController> durationControllers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E3EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
            child: AppText(
              categoryName,
              fontSize: 16,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
          ),
          ...drafts.map(
            (draft) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServicePricingCard(
                draft: draft,
                priceController: priceControllers[draft.service.id]!,
                durationController: durationControllers[draft.service.id]!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicePricingCard extends StatelessWidget {
  const _ServicePricingCard({
    required this.draft,
    required this.priceController,
    required this.durationController,
  });

  final ServicePricingDraft draft;
  final TextEditingController priceController;
  final TextEditingController durationController;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderPricingProvider>();
    final originalPrice = draft.service.price.trim();
    final originalDuration = draft.service.duration > 0
        ? '${draft.service.duration}'
        : '';
    final isDirty =
        draft.price.trim() != originalPrice ||
        draft.duration.trim() != originalDuration;
    final isUpdating = provider.isUpdatingService(draft.service.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDirty ? const Color(0xFF2D9CFF) : const Color(0xFFF0E3E8),
          width: isDirty ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            draft.service.serviceName,
            fontSize: 15,
            fontWeight: FontWeights.semiBold,
            color: AppColor.darkGrey,
          ),
          const SizedBox(height: 4),
          AppText(
            '${draft.service.formattedPrice} base',
            fontSize: 12,
            color: AppColor.grey,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PricingField(
                  controller: priceController,
                  label: 'Your Price *',
                  hint: '85',
                  prefix: '\$',
                  validator: _numberValidatorRequired,
                  onChanged: (value) =>
                      provider.updateServicePrice(draft.service.id, value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PricingField(
                  controller: durationController,
                  label: 'Duration (min) *',
                  hint: '60',
                  validator: _intValidatorRequired,
                  onChanged: (value) =>
                      provider.updateServiceDuration(draft.service.id, value),
                ),
              ),
            ],
          ),
          if (isDirty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isUpdating
                        ? null
                        : () {
                            provider.resetServiceDraft(draft.service.id);
                            priceController.text = originalPrice;
                            durationController.text = originalDuration;
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : () async {
                            final priceError = _numberValidatorRequired(
                              priceController.text,
                            );
                            final durationError = _intValidatorRequired(
                              durationController.text,
                            );
                            if (priceError != null || durationError != null) {
                              FunctionalComponent.showSnackBar(
                                context: context,
                                title: priceError ?? durationError!,
                                success: false,
                              );
                              return;
                            }

                            final error = await provider.updateServicePricing(
                              serviceId: draft.service.id,
                              price: priceController.text,
                              duration: durationController.text,
                            );
                            if (!context.mounted) return;
                            if (error != null && error.isNotEmpty) {
                              FunctionalComponent.showSnackBar(
                                context: context,
                                title: error,
                                success: false,
                              );
                              return;
                            }
                            FunctionalComponent.showSnackBar(
                              context: context,
                              title: '${draft.service.serviceName} updated.',
                              success: true,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.authButton,
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: isUpdating
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
                            'Update',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PricingField extends StatelessWidget {
  const _PricingField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.onChanged,
    this.prefix,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label.replaceAll('*', '').trim(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColor.grey,
            ),
            children: [
              if (label.contains('*'))
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix != null ? '$prefix ' : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: const Color(0xFFFFFEFE),
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

class _PricingState extends StatelessWidget {
  const _PricingState({
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

String? _numberValidator(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = double.tryParse(value.trim());
  if (parsed == null || parsed < 0) {
    return 'Invalid';
  }
  return null;
}

String? _intValidator(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed < 0) {
    return 'Invalid';
  }
  return null;
}

String? _numberValidatorRequired(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return _numberValidator(value);
}

String? _intValidatorRequired(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return _intValidator(value);
}

String? _percentValidator(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed < 0 || parsed > 100) {
    return '0-100';
  }
  return null;
}
