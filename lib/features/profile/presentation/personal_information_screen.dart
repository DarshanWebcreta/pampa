import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/profile/presentation/provider/profile_provider.dart';
import 'package:pampa/core/widgets/phone_field.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _zipCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _countryCtrl;

  CountryCode _selectedCountry = kCountryCodes.first;
  File? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().profile;
    _firstNameCtrl = TextEditingController(text: p?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: p?.lastName ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');

    // Strip dial code from stored mobile if present so just the number shows
    final rawMobile = p?.mobile ?? '';
    final matchedCountry = kCountryCodes.firstWhere(
      (c) => rawMobile.startsWith(c.dial),
      orElse: () => kCountryCodes.first,
    );
    if (rawMobile.startsWith(matchedCountry.dial)) {
      _selectedCountry = matchedCountry;
      _mobileCtrl = TextEditingController(
          text: rawMobile.substring(matchedCountry.dial.length));
    } else {
      _mobileCtrl = TextEditingController(text: rawMobile);
    }

    _streetCtrl = TextEditingController(text: p?.streetAddress ?? '');
    _zipCtrl = TextEditingController(text: p?.zipCode ?? '');
    _cityCtrl = TextEditingController(text: p?.city ?? '');
    _stateCtrl = TextEditingController(text: p?.state ?? '');
    _countryCtrl = TextEditingController(text: p?.country ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _streetCtrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedPhoto = File(picked.path));
    }
  }

  Future<void> _deletePhoto() async {
    if (_selectedPhoto != null) {
      setState(() => _selectedPhoto = null);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      mobile: '${_selectedCountry.dial}${_mobileCtrl.text.trim()}',
      removeImage: true,
    );

    if (success && mounted) {
      provider.fetchProfile(forceRefresh: true);
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Profile photo removed.',
        success: true,
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      mobile: '${_selectedCountry.dial}${_mobileCtrl.text.trim()}',
      streetAddress: _streetCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      photo: _selectedPhoto,
    );

    if (!mounted) return;

    if (success) {
      // Re-fetch /customer/me so the profile avatar & all fields
      // in the profile tab reflect the latest server data.
      if (mounted) {
        context.read<ProfileProvider>().fetchProfile(forceRefresh: true);
      }
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Profile updated successfully.',
        success: true,
      );
      Navigator.of(context).pop();
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.updateError.isNotEmpty
            ? provider.updateError
            : 'Failed to update profile.',
        success: false,
      );
      provider.resetUpdateStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final isSaving = provider.updateStatus == ProfileUpdateStatus.loading;

        return Scaffold(
          backgroundColor: AppColor.authBg,
          appBar: AppBar(
            backgroundColor: AppColor.authBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColor.darkGrey),
            ),
            title: AppText(
              'Personal Information',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
            centerTitle: false,
            actions: [
              isSaving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColor.authButton),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _save,
                      child: AppText(
                        'Save',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.authButton,
                      ),
                    ),
              const SizedBox(width: 8),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // ── Photo picker ────────────────────────────────────────────
                _PhotoPicker(
                  photoUrl: provider.profile?.photoUrl,
                  selectedFile: _selectedPhoto,
                  onTap: _pickPhoto,
                  onDelete: (provider.profile?.photoUrl != null || _selectedPhoto != null)
                      ? _deletePhoto
                      : null,
                ),

                const SizedBox(height: 24),
                _sectionLabel('Personal Details'),
                const SizedBox(height: 10),

                // ── Name ────────────────────────────────────────────────────
                _FieldCard(
                  icon: Icons.person_outline_rounded,
                  label: 'First Name',
                  controller: _firstNameCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                _FieldCard(
                  icon: Icons.person_outline_rounded,
                  label: 'Last Name',
                  controller: _lastNameCtrl,
                ),
                const SizedBox(height: 10),

                // ── Contact ─────────────────────────────────────────────────
                _FieldCard(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email Address',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // ── Phone (with country-code picker) ────────────────────
                _sectionLabel('Phone Number'),
                const SizedBox(height: 6),
                PhoneField(
                  controller: _mobileCtrl,
                  fillColor: AppColor.white,
                  initialCountry: _selectedCountry,
                  radius: 14,
                  onCountryChanged: (c) =>
                      setState(() => _selectedCountry = c),
                ),

                // const SizedBox(height: 24),
                // _sectionLabel('Address'),
                // const SizedBox(height: 10),
                //
                // _FieldCard(
                //   icon: Icons.location_on_outlined,
                //   label: 'Street Address',
                //   controller: _streetCtrl,
                // ),
                // const SizedBox(height: 10),
                // Row(
                //   children: [
                //     Expanded(
                //       child: _FieldCard(
                //         icon: Icons.markunread_mailbox_outlined,
                //         label: 'Zip Code',
                //         controller: _zipCtrl,
                //         keyboardType: TextInputType.number,
                //       ),
                //     ),
                //     const SizedBox(width: 10),
                //     Expanded(
                //       child: _FieldCard(
                //         icon: Icons.location_city_outlined,
                //         label: 'City',
                //         controller: _cityCtrl,
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 10),
                // Row(
                //   children: [
                //     Expanded(
                //       child: _FieldCard(
                //         icon: Icons.map_outlined,
                //         label: 'State',
                //         controller: _stateCtrl,
                //       ),
                //     ),
                //     const SizedBox(width: 10),
                //     Expanded(
                //       child: _FieldCard(
                //         icon: Icons.public_outlined,
                //         label: 'Country',
                //         controller: _countryCtrl,
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: AppText(
          label,
          fontSize: FontSizes.small,
          fontWeight: FontWeights.medium,
          color: AppColor.grey,
        ),
      );
}

// ─── Photo picker ─────────────────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  final String? photoUrl;
  final File? selectedFile;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PhotoPicker({
    required this.photoUrl,
    required this.selectedFile,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.authButton.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColor.authButton.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: selectedFile != null
                    ? Image.file(selectedFile!, fit: BoxFit.cover)
                    : (photoUrl != null && photoUrl!.isNotEmpty)
                        ? FunctionalComponent.cachedNetworkImage(
                            photoUrl!,
                            radius: 45,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person_outline_rounded,
                            size: 40,
                            color: AppColor.authButton,
                          ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColor.authButton,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 14, color: AppColor.white),
                ),
              ),
            ),
            if (onDelete != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Field card ───────────────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FieldCard({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColor.authButton),
              const SizedBox(width: 5),
              AppText(label, fontSize: 11, color: AppColor.grey),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontSize: FontSizes.regular,
              color: AppColor.darkGrey,
              fontWeight: FontWeights.medium,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
