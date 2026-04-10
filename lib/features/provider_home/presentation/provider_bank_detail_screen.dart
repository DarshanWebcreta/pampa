import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/data/models/bank_detail_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_bank_detail_provider.dart';

class ProviderBankDetailScreen extends StatefulWidget {
  const ProviderBankDetailScreen({super.key});

  @override
  State<ProviderBankDetailScreen> createState() => _ProviderBankDetailScreenState();
}

class _ProviderBankDetailScreenState extends State<ProviderBankDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  late TextEditingController _bankNameCtrl;
  late TextEditingController _holderNameCtrl;
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _routingNumberCtrl;
  String _accountType = 'checking';

  @override
  void initState() {
    super.initState();
    _bankNameCtrl = TextEditingController();
    _holderNameCtrl = TextEditingController();
    _accountNumberCtrl = TextEditingController();
    _routingNumberCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBankDetailProvider>().fetchBankDetails();
    });
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _holderNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _routingNumberCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(BankDetailModel? detail) {
    if (detail == null) return;
    if (!_isEditing) {
      _bankNameCtrl.text = detail.bankName;
      _holderNameCtrl.text = detail.accountHolderName;
      _routingNumberCtrl.text = detail.routingNumber;
      _accountType = detail.accountType.toLowerCase();
      // We don't sync account number here because it's masked in the detail model
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProviderBankDetailProvider>();
    final error = await provider.saveBankDetails(
      bankName: _bankNameCtrl.text.trim(),
      accountHolderName: _holderNameCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim(),
      routingNumber: _routingNumberCtrl.text.trim(),
      accountType: _accountType,
    );

    if (!mounted) return;

    if (error != null) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: error,
        success: false,
      );
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Bank details saved successfully.',
        success: true,
      );
      setState(() {
        _isEditing = false;
        _accountNumberCtrl.clear(); // Clear the full account number for security
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderBankDetailProvider>(
      builder: (context, provider, _) {
        final detail = provider.bankDetail;
        _syncControllers(detail);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F3F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: AppText(
              'Bank Details',
              fontSize: 18,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
            actions: [
              if (detail != null && detail.hasBankDetails && !_isEditing)
                TextButton(
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text('Edit', style: TextStyle(color: AppColor.authButton)),
                ),
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(ProviderBankDetailProvider provider) {
    if (provider.status == BankDetailStatus.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColor.authButton));
    }

    if (provider.status == BankDetailStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColor.grey),
            const SizedBox(height: 16),
            AppText(provider.error, fontSize: 14, color: AppColor.grey, align: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.fetchBankDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final detail = provider.bankDetail;
    final showForm = _isEditing || detail == null || !detail.hasBankDetails;

    if (showForm) {
      return _buildForm(provider.status == BankDetailStatus.saving);
    }

    return _buildDetailsView(detail!);
  }

  Widget _buildDetailsView(BankDetailModel detail) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBDDE3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Bank Name', value: detail.bankName),
              const Divider(height: 24),
              _InfoRow(label: 'Account Holder', value: detail.accountHolderName),
              const Divider(height: 24),
              _InfoRow(label: 'Account Number', value: detail.maskedAccountNumber),
              const Divider(height: 24),
              _InfoRow(label: 'Account Type', value: detail.accountType.toUpperCase()),
              if (detail.routingNumber.isNotEmpty) ...[
                const Divider(height: 24),
                _InfoRow(label: 'Routing Number', value: detail.routingNumber),
              ],
              const Divider(height: 24),
              Row(
                children: [
                  AppText('Status', fontSize: 13, color: AppColor.grey),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: detail.isVerified ? const Color(0xFFE8F7ED) : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      detail.isVerified ? 'VERIFIED' : 'PENDING',
                      fontSize: 11,
                      fontWeight: FontWeights.bold,
                      color: detail.isVerified ? const Color(0xFF1F8F4C) : const Color(0xFFB26A00),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isSaving) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBDDE3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('Bank Information', fontSize: 18, fontWeight: FontWeights.bold, color: AppColor.darkGrey),
                const SizedBox(height: 16),
                _InputField(
                  label: 'Bank Name',
                  hint: 'e.g. Chase Bank',
                  controller: _bankNameCtrl,
                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _InputField(
                  label: 'Account Holder Name',
                  hint: 'Full name on account',
                  controller: _holderNameCtrl,
                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _InputField(
                  label: 'Account Number',
                  hint: 'Full account number',
                  controller: _accountNumberCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _InputField(
                  label: 'Routing Number (Optional)',
                  hint: '9-digit routing number',
                  controller: _routingNumberCtrl,
                ),
                const SizedBox(height: 16),
                AppText('Account Type', fontSize: 13, color: AppColor.grey),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF0DDE5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _accountType,
                      isExpanded: true,
                      onChanged: (val) => setState(() => _accountType = val!),
                      items: const [
                        DropdownMenuItem(value: 'checking', child: Text('Checking')),
                        DropdownMenuItem(value: 'savings', child: Text('Savings')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_isEditing)
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving ? null : () => setState(() => _isEditing = false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              if (_isEditing) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Bank Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(label, fontSize: 13, color: AppColor.grey),
        const Spacer(),
        AppText(value, fontSize: 14, fontWeight: FontWeights.semiBold, color: AppColor.darkGrey),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, fontSize: 13, color: AppColor.grey),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFFFFEFE),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          ),
        ),
      ],
    );
  }
}
