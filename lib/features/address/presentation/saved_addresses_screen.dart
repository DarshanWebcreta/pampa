import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/data/models/address_model.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AddressProvider>();
      if (p.fetchStatus == AddressFetchStatus.initial) {
        p.fetchAddresses();
      }
    });
  }

  void _openAddSheet([AddressModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AddressProvider>(),
        child: _AddressSheet(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address'),
        content: Text(
            'Remove "${address.addressName}" from your saved addresses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: TextStyle(color: AppColor.deepRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<AddressProvider>().deleteAddress(address.id);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<AddressProvider>().deleteError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.authBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColor.darkGrey),
        ),
        title: AppText(
          'Saved Addresses',
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
        centerTitle: false,
        actions: [
          GestureDetector(
            onTap: () => _openAddSheet(),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: const BoxDecoration(
                color: AppColor.authButton,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColor.white, size: 20),
            ),
          ),
        ],
      ),
      body: Consumer<AddressProvider>(
        builder: (context, provider, _) {
          if (provider.fetchStatus == AddressFetchStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColor.authButton),
            );
          }

          if (provider.fetchStatus == AddressFetchStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColor.authButton, size: 40),
                    const SizedBox(height: 12),
                    AppText(provider.fetchError,
                        fontSize: FontSizes.small,
                        color: AppColor.grey,
                        align: TextAlign.center,
                        maxLines: 3),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: provider.fetchAddresses,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColor.authButton,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AppText('Retry',
                            fontSize: FontSizes.small,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_outlined,
                      color: AppColor.authButton, size: 48),
                  const SizedBox(height: 12),
                  AppText('No saved addresses',
                      fontSize: FontSizes.regular,
                      fontWeight: FontWeights.semiBold,
                      color: AppColor.darkGrey),
                  const SizedBox(height: 6),
                  AppText('Tap + to add your first address',
                      fontSize: FontSizes.small, color: AppColor.grey),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColor.authButton,
            onRefresh: provider.fetchAddresses,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: provider.addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final address = provider.addresses[i];
                return _AddressCard(
                  address: address,
                  onEdit: () => _openAddSheet(address),
                  onDelete: () => _confirmDelete(address),
                  onSetDefault: address.isDefault
                      ? null
                      : () async {
                          final ok = await provider
                              .setDefaultAddress(address.id);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to set default.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Address card ─────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  IconData get _icon {
    final name = address.addressName.toLowerCase();
    if (name.contains('home')) return Icons.home_outlined;
    if (name.contains('work') || name.contains('office'))
      return Icons.work_outline_rounded;
    return Icons.location_on_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = address.isDefault;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: isDefault
            ? Border.all(
                color: AppColor.authButton.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        children: [
          // ── Top: icon + name + city ──────────────────────────────────────
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColor.authButton.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_icon, size: 20, color: AppColor.authButton),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppText(
                                address.addressName.isEmpty
                                    ? 'Address'
                                    : address.addressName,
                                fontSize: FontSizes.regular,
                                fontWeight: FontWeights.bold,
                                maxLines: 3,
                                color: AppColor.darkGrey,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColor.authButton
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: AppText(
                                  'Default',
                                  fontSize: 10,
                                  fontWeight: FontWeights.semiBold,
                                  color: AppColor.authButton,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          address.streetAddress,
                          fontSize: FontSizes.small,
                          color: AppColor.grey,
                          maxLines: 1,
                        ),
                        AppText(
                          [
                            address.city,
                            if ((address.state ?? '').isNotEmpty) address.state!,
                            address.zipCode,
                          ].where((s) => s.isNotEmpty).join(', '),
                          fontSize: FontSizes.small,
                          color: AppColor.grey,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────────
          Divider(height: 1, color: AppColor.lightGrey),

          // ── Bottom actions ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (onSetDefault != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSetDefault,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.darkGrey,
                        side: const BorderSide(color: AppColor.mediumGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(
                          fontSize: FontSizes.small,
                          fontWeight: FontWeights.semiBold,
                        ),
                      ),
                      child: const Text('Set as Default'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 16, color: AppColor.deepRed),
                  label: AppText(
                    'Delete',
                    fontSize: FontSizes.small,
                    fontWeight: FontWeights.semiBold,
                    color: AppColor.deepRed,
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add / Edit bottom sheet ──────────────────────────────────────────────────

class _AddressSheet extends StatefulWidget {
  final AddressModel? existing;

  const _AddressSheet({this.existing});

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _zipCtrl;
  bool _isDefault = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _nameCtrl = TextEditingController(text: a?.addressName ?? '');
    _streetCtrl = TextEditingController(text: a?.streetAddress ?? '');
    _cityCtrl = TextEditingController(text: a?.city ?? '');
    _zipCtrl = TextEditingController(text: a?.zipCode ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<AddressProvider>();
    bool ok;

    if (_isEditing) {
      ok = await provider.updateAddress(
        id: widget.existing!.id,
        addressName: _nameCtrl.text.trim(),
        streetAddress: _streetCtrl.text.trim(),
        zipCode: _zipCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        isDefault: _isDefault,
      );
    } else {
      ok = await provider.storeAddress(
        addressName: _nameCtrl.text.trim(),
        streetAddress: _streetCtrl.text.trim(),
        zipCode: _zipCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.saveError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: const BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColor.mediumGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppText(
              _isEditing ? 'Edit Address' : 'Add New Address',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 20),
            _Field(
              label: 'Address Label',
              hint: 'e.g. Home, Work',
              controller: _nameCtrl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Street Address',
              hint: '123 Main St',
              controller: _streetCtrl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _Field(
                    label: 'City',
                    hint: 'New York',
                    controller: _cityCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _Field(
                    label: 'ZIP Code',
                    hint: '10001',
                    controller: _zipCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v ?? false),
                    activeColor: AppColor.authButton,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  AppText(
                    'Set as default address',
                    fontSize: FontSizes.small,
                    color: AppColor.darkGrey,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Consumer<AddressProvider>(
              builder: (_, provider, __) {
                final saving = provider.isSaving;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.authButton,
                      foregroundColor: AppColor.white,
                      disabledBackgroundColor:
                          AppColor.authButton.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: AppColor.white, strokeWidth: 2.5),
                          )
                        : AppText(
                            _isEditing ? 'Update Address' : 'Save Address',
                            fontSize: FontSizes.regular,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.white,
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label,
            fontSize: FontSizes.small,
            fontWeight: FontWeights.medium,
            color: AppColor.grey),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: FontSizes.regular,
            color: AppColor.darkGrey,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: FontSizes.regular, color: AppColor.mediumGrey),
            filled: true,
            fillColor: AppColor.authBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColor.deepRed, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColor.authButton, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColor.deepRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
