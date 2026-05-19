import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/support/presentation/provider/support_provider.dart';

class ReportIssueBottomSheet extends StatefulWidget {
  final int? conversationId;
  final int? messageId;

  const ReportIssueBottomSheet({
    super.key,
    this.conversationId,
    this.messageId,
  });

  @override
  State<ReportIssueBottomSheet> createState() => _ReportIssueBottomSheetState();
}

class _ReportIssueBottomSheetState extends State<ReportIssueBottomSheet> {
  String? _selectedType;
  final _customIssueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().fetchIssueTypes();
    });
  }

  @override
  void dispose() {
    _customIssueCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue type')),
      );
      return;
    }

    final success = await context.read<SupportProvider>().reportIssue(
          issueType: _selectedType!,
          customIssue: _customIssueCtrl.text.trim().isEmpty
              ? null
              : _customIssueCtrl.text.trim(),
          conversationId: widget.conversationId,
          messageId: widget.messageId,
        );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you, our team will review this')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 30),
      decoration: const BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Report Issue',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<SupportProvider>(
            builder: (context, provider, _) {
              if (provider.status == SupportStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.status == SupportStatus.error &&
                  provider.issueTypes.isEmpty) {
                return Column(
                  children: [
                    AppText(provider.errorMessage, color: Colors.red),
                    TextButton(
                      onPressed: () => provider.fetchIssueTypes(),
                      child: const Text('Retry'),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText('Select Issue Type',
                      fontSize: 14, fontWeight: FontWeight.w600),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: provider.issueTypes.map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: AppText(
                          type,
                          color: isSelected ? AppColor.white : AppColor.darkGrey,
                        ),
                        selected: isSelected,
                        selectedColor: AppColor.authButton,
                        backgroundColor: AppColor.authBg,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const AppText('Description (Optional)',
              fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 10),
          TextField(
            controller: _customIssueCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Provide more details...',
              filled: true,
              fillColor: AppColor.authBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Consumer<SupportProvider>(
            builder: (context, provider, _) {
              final isSubmitting = provider.status == SupportStatus.submitting;
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.authButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: AppColor.white)
                      : const AppText(
                          'Submit Report',
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
