import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_credentials_provider.dart';

class ProviderCredentialsScreen extends StatefulWidget {
  const ProviderCredentialsScreen({super.key});

  @override
  State<ProviderCredentialsScreen> createState() =>
      _ProviderCredentialsScreenState();
}

class _ProviderCredentialsScreenState extends State<ProviderCredentialsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _ssnCtrl;

  @override
  void initState() {
    super.initState();
    _instagramCtrl = TextEditingController();
    _ssnCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderCredentialsProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _instagramCtrl.dispose();
    _ssnCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(ProviderCredentialsProvider provider) {
    if (_instagramCtrl.text != provider.instagram) {
      _instagramCtrl.text = provider.instagram;
    }
    if (_ssnCtrl.text != provider.ssnLast4) {
      _ssnCtrl.text = provider.ssnLast4;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProviderCredentialsProvider>();
    provider.updateInstagram(_instagramCtrl.text.trim());
    provider.updateSsnLast4(_ssnCtrl.text.trim());

    final error = await provider.save();
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
      title: 'Credentials updated successfully.',
      success: true,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderCredentialsProvider>(
      builder: (context, provider, _) {
        _syncControllers(provider);

        return Scaffold(
          backgroundColor: const Color(0xFFFDF7F9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: AppText(
              'Credentials',
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

  Widget _buildBody(ProviderCredentialsProvider provider) {
    switch (provider.status) {
      case ProviderCredentialsStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColor.authButton),
        );
      case ProviderCredentialsStatus.error:
        return _StateMessage(
          message: provider.error.isNotEmpty
              ? provider.error
              : 'Failed to load credentials.',
          onTap: () => provider.initialize(forceRefresh: true),
        );
      case ProviderCredentialsStatus.initial:
        return const SizedBox.shrink();
      case ProviderCredentialsStatus.success:
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
            children: [
              AppText(
                'Verify your credentials',
                fontSize: 24,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey,
              ),
              const SizedBox(height: 4),
              AppText(
                'Required for approval to maintain safety and quality.',
                fontSize: 12,
                color: AppColor.grey,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E8ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColor.authButton,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppText(
                        'We verify every provider to maintain safety and quality.',
                        fontSize: 12,
                        color: AppColor.darkGrey,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _YesNoSection(
                label: 'Licensed',
                value: provider.licensed,
                onChanged: provider.setLicensed,
              ),
              if (provider.licensed == 'Yes') ...[
                const SizedBox(height: 16),
                _UploadTile(
                  label: 'Cosmetology License',
                  imageFiles: provider.cosmetologyLicenseFile != null
                      ? [provider.cosmetologyLicenseFile!]
                      : const [],
                  imageUrls: (provider.cosmetologyLicenseUrl != null &&
                          provider.cosmetologyLicenseUrl!.isNotEmpty)
                      ? [provider.cosmetologyLicenseUrl!]
                      : const [],
                  emptyText: 'Upload license image',
                  onTap: provider.pickCosmetologyLicense,
                ),
                const SizedBox(height: 14),
                _UploadTile(
                  label: 'Specialty Certifications (Optional)',
                  imageFiles: provider.specialtyCertificationFiles,
                  imageUrls: provider.specialtyCertificationUrls,
                  emptyText: 'Upload certification images',
                  onTap: provider.pickSpecialtyCertifications,
                ),
              ],
              const SizedBox(height: 14),
              _TextFieldBlock(
                label: 'Instagram (Optional)',
                controller: _instagramCtrl,
                hint: '@yourusername',
              ),
              const SizedBox(height: 14),
              _TextFieldBlock(
                label: 'SSN Last 4 digits',
                controller: _ssnCtrl,
                hint: '1234',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (value.trim().length != 4) return 'Enter 4 digits';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF0E3E8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            'Background Check Consent',
                            fontSize: 14,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.darkGrey,
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            'Required for approval',
                            fontSize: 12,
                            color: AppColor.grey,
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: provider.backgroundConsent,
                      activeTrackColor: AppColor.authButton,
                      onChanged: provider.setBackgroundConsent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    disabledBackgroundColor: AppColor.authButton.withValues(
                      alpha: 0.6,
                    ),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.saving
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
                          'Continue',
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
}

class _YesNoSection extends StatelessWidget {
  const _YesNoSection({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          fontSize: 13,
          fontWeight: FontWeights.semiBold,
          color: AppColor.darkGrey,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: 'Yes',
                selected: value == 'Yes',
                onTap: () => onChanged('Yes'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChoiceChip(
                label: 'No',
                selected: value == 'No',
                onTap: () => onChanged('No'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColor.authButton.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColor.authButton : const Color(0xFFF0E3E8),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColor.authButton : AppColor.darkGrey,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.label,
    required this.imageFiles,
    required this.imageUrls,
    required this.emptyText,
    required this.onTap,
  });

  final String label;
  final List<XFile> imageFiles;
  final List<String> imageUrls;
  final String emptyText;
  final Future<String?> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final showLocal = imageFiles.isNotEmpty;
    final hasPreviews = imageFiles.isNotEmpty || imageUrls.isNotEmpty;
    final previewCount = showLocal ? imageFiles.length : imageUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          fontSize: 13,
          fontWeight: FontWeights.semiBold,
          color: AppColor.darkGrey,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final error = await onTap();
            if (error != null && context.mounted) {
              FunctionalComponent.showSnackBar(
                context: context,
                title: error,
                success: false,
              );
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0E3E8)),
            ),
            child: Column(
              children: [
                if (!hasPreviews) ...[
                  const Icon(
                    Icons.file_upload_outlined,
                    color: AppColor.darkGrey,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    emptyText,
                    fontSize: 12,
                    color: AppColor.grey,
                    align: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                ] else ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      '$previewCount image${previewCount == 1 ? '' : 's'} selected',
                      fontSize: 12,
                      color: AppColor.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (showLocal)
                        ...imageFiles.map(
                          (file) => _CredentialImagePreview.file(file.path),
                        )
                      else
                        ...imageUrls.map(_CredentialImagePreview.network),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                AppText(
                  'Select from gallery',
                  fontSize: 11,
                  color: AppColor.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CredentialImagePreview extends StatelessWidget {
  const _CredentialImagePreview.file(this.path) : imageUrl = null;

  const _CredentialImagePreview.network(this.imageUrl) : path = null;

  final String? path;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: const Color(0xFFEAD7DF));
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2F5),
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: path != null
          ? Image.file(
              File(path!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image_outlined, color: AppColor.grey),
            )
          : Image.network(
              imageUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image_outlined, color: AppColor.grey),
            ),
    );
  }
}

class _TextFieldBlock extends StatelessWidget {
  const _TextFieldBlock({
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          fontSize: 13,
          fontWeight: FontWeights.semiBold,
          color: AppColor.darkGrey,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF0E3E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.authButton),
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
        ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onTap});

  final String message;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColor.grey),
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
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
