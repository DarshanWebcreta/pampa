import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/data/models/provider_profile_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_profile_provider.dart';

class ProviderEditProfileScreen extends StatefulWidget {
  final ProviderProfileModel profile;

  const ProviderEditProfileScreen({super.key, required this.profile});

  @override
  State<ProviderEditProfileScreen> createState() =>
      _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState extends State<ProviderEditProfileScreen> {
  late final TextEditingController _bioCtrl;
  late final TextEditingController _certificationCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _zipCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _distanceCtrl;
  late final TextEditingController _perKmCtrl;
  late final TextEditingController _serviceZipCodesCtrl;
  final _formKey = GlobalKey<FormState>();

  String _licensed = 'No';

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
    _certificationCtrl =
        TextEditingController(text: widget.profile.certification ?? '');
    _streetCtrl =
        TextEditingController(text: widget.profile.streetAddress ?? '');
    _zipCtrl = TextEditingController(text: widget.profile.zipCode ?? '');
    _cityCtrl = TextEditingController(text: widget.profile.city ?? '');
    _stateCtrl = TextEditingController(text: widget.profile.state ?? '');
    _countryCtrl =
        TextEditingController(text: widget.profile.country ?? 'United States');
    _distanceCtrl = TextEditingController(
      text: widget.profile.maxServiceDistance > 0
          ? widget.profile.maxServiceDistance.toString()
          : '',
    );
    _perKmCtrl = TextEditingController(text: widget.profile.perKmCharge ?? '');
    _serviceZipCodesCtrl =
        TextEditingController(text: widget.profile.zipCodes.join(', '));
    _licensed = (widget.profile.licensed ?? 'No').trim().isEmpty
        ? 'No'
        : widget.profile.licensed!.trim();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _certificationCtrl.dispose();
    _streetCtrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _distanceCtrl.dispose();
    _perKmCtrl.dispose();
    _serviceZipCodesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<ProviderProfileProvider>();
    final err = await prov.updateProfile(
      bio: _bioCtrl.text.trim(),
      certification: _certificationCtrl.text.trim(),
      licensed: _licensed,
      streetAddress: _streetCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      maxServiceDistance: _distanceCtrl.text.trim(),
      perKmCharge: _perKmCtrl.text.trim(),
      serviceZipCodes: _serviceZipCodesCtrl.text.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: err,
        success: false,
      );
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Profile updated successfully',
        success: true,
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _addGalleryImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty || !mounted) return;
    final prov = context.read<ProviderProfileProvider>();
    final err = await prov.uploadGalleryImages(
      picked.map((x) => File(x.path)).toList(),
    );
    if (!mounted) return;
    if (err != null) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: err,
        success: false,
      );
    }
  }

  Future<void> _confirmDeleteImage(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Image'),
        content: const Text('Remove this image from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final prov = context.read<ProviderProfileProvider>();
    final err = await prov.deleteGalleryImage(id);
    if (!mounted) return;
    if (err != null) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: err,
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderProfileProvider>(
      builder: (context, prov, _) {
        final gallery = prov.profile?.gallery ?? widget.profile.gallery;
        return Scaffold(
          backgroundColor: const Color(0xFFF7F3F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: AppText(
              'Edit Profile',
              fontSize: 18,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
            actions: [
              prov.saving
                  ? const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _save,
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: AppColor.authButton,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              children: [
                _ProfilePreview(profile: widget.profile),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Professional Details',
                  subtitle:
                      'These fields map directly to the provider profile update API.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Bio'),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _bioCtrl,
                        hint: 'Expert nail technician with 10 years experience',
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bio is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel('Certification'),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _certificationCtrl,
                        hint: 'Licensed Cosmetologist',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Certification is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel('Licensed'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ChoiceTile(
                              label: 'Yes',
                              selected: _licensed == 'Yes',
                              onTap: () => setState(() => _licensed = 'Yes'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ChoiceTile(
                              label: 'No',
                              selected: _licensed == 'No',
                              onTap: () => setState(() => _licensed = 'No'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Business Address',
                  child: Column(
                    children: [
                      _InputGroup(
                        label: 'Street Address',
                        child: _InputField(
                          controller: _streetCtrl,
                          hint: '123 Main St',
                          validator: _requiredField('Street address is required'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _InputGroup(
                              label: 'City',
                              child: _InputField(
                                controller: _cityCtrl,
                                hint: 'Los Angeles',
                                validator: _requiredField('City is required'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InputGroup(
                              label: 'State',
                              child: _InputField(
                                controller: _stateCtrl,
                                hint: 'CA',
                                validator: _requiredField('State is required'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _InputGroup(
                              label: 'ZIP Code',
                              child: _InputField(
                                controller: _zipCtrl,
                                hint: '90015',
                                keyboardType: TextInputType.number,
                                validator: _requiredField('ZIP code is required'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InputGroup(
                              label: 'Country',
                              child: _InputField(
                                controller: _countryCtrl,
                                hint: 'United States',
                                validator: _requiredField('Country is required'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Service Area & Pricing',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _InputGroup(
                              label: 'Max Service Distance',
                              child: _InputField(
                                controller: _distanceCtrl,
                                hint: '25',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: false,
                                ),
                                suffixText: 'km',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Distance is required';
                                  }
                                  final parsed = num.tryParse(value.trim());
                                  if (parsed == null || parsed <= 0) {
                                    return 'Enter a valid distance';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InputGroup(
                              label: 'Per KM Charge',
                              child: _InputField(
                                controller: _perKmCtrl,
                                hint: '1.50',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                prefixText: '\$ ',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Charge is required';
                                  }
                                  final parsed = num.tryParse(value.trim());
                                  if (parsed == null || parsed < 0) {
                                    return 'Enter a valid amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InputGroup(
                        label: 'Service ZIP Codes',
                        helper:
                            'Comma-separated list, for example: 90015, 90016, 90017',
                        child: _InputField(
                          controller: _serviceZipCodesCtrl,
                          hint: '90015, 90016, 90017',
                          maxLines: 3,
                          validator: _requiredField('Service ZIP codes are required'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Portfolio',
                  trailing: prov.galleryLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : GestureDetector(
                          onTap: _addGalleryImages,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.authButton.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 14,
                                  color: AppColor.authButton,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add Photos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.authButton,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  child: gallery.isEmpty
                      ? Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F7F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColor.lightGrey),
                          ),
                          child: const Center(
                            child: Text(
                              'No portfolio images yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColor.grey,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemCount: gallery.length,
                          itemBuilder: (context, i) {
                            final img = gallery[i];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: FunctionalComponent.cachedNetworkImage(
                                    img.url,
                                    fit: BoxFit.cover,
                                    radius: 10,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _confirmDeleteImage(img.id),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? Function(String?) _requiredField(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }
}

class _ProfilePreview extends StatelessWidget {
  final ProviderProfileModel profile;

  const _ProfilePreview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final location = [
      profile.city,
      profile.state,
      profile.country,
    ].whereType<String>().where((item) => item.trim().isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EFF2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColor.authButton.withValues(alpha: 0.12),
            backgroundImage: (profile.photoUrl ?? '').isNotEmpty
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: (profile.photoUrl ?? '').isEmpty
                ? Text(
                    (profile.name ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColor.authButton,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? 'Provider Profile',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColor.darkGrey,
                  ),
                ),
                if ((profile.email ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.email!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColor.grey,
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColor.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.darkGrey,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColor.grey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InputGroup extends StatelessWidget {
  final String label;
  final String? helper;
  final Widget child;

  const _InputGroup({
    required this.label,
    required this.child,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        child,
        if (helper != null && helper!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: const TextStyle(
              fontSize: 11,
              color: AppColor.grey,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF8EFF2) : const Color(0xFFF9F7F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColor.authButton : AppColor.lightGrey,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColor.authButton : AppColor.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColor.authButton : AppColor.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColor.darkGrey,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? suffixText;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixText,
    this.suffixText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColor.darkGrey),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColor.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9F7F8),
        prefixText: prefixText,
        suffixText: suffixText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColor.authButton, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
