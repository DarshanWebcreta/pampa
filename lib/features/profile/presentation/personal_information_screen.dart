import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/profile/presentation/provider/profile_provider.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  bool _editing = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _phoneCtrl = TextEditingController(text: p?.mobile ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_editing) {
      // Save — no update API yet, show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _editing = !_editing);
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
          'Personal Information',
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _toggleEdit,
            child: AppText(
              _editing ? 'Save' : 'Edit',
              fontSize: FontSizes.regular,
              fontWeight: FontWeights.semiBold,
              color: AppColor.authButton,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _InfoCard(
            icon: Icons.person_outline_rounded,
            label: 'Full Name',
            controller: _nameCtrl,
            editing: _editing,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.mail_outline_rounded,
            label: 'Email Address',
            controller: _emailCtrl,
            editing: _editing,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            controller: _phoneCtrl,
            editing: _editing,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool editing;
  final TextInputType keyboardType;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.controller,
    required this.editing,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColor.authButton),
              const SizedBox(width: 6),
              AppText(
                label,
                fontSize: FontSizes.small,
                color: AppColor.grey,
              ),
            ],
          ),
          const SizedBox(height: 6),
          editing
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
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
                )
              : AppText(
                  controller.text.isEmpty ? '—' : controller.text,
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.medium,
                  color: AppColor.darkGrey,
                ),
        ],
      ),
    );
  }
}
