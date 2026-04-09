import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/categories/data/models/category_model.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_category_management_provider.dart';

class ProviderCategoryManagementScreen extends StatefulWidget {
  const ProviderCategoryManagementScreen({super.key});

  @override
  State<ProviderCategoryManagementScreen> createState() =>
      _ProviderCategoryManagementScreenState();
}

class _ProviderCategoryManagementScreenState
    extends State<ProviderCategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderCategoryManagementProvider>().fetchCategories();
    });
  }

  Future<void> _openCategoryForm([CategoryModel? category]) async {
    final provider = context.read<ProviderCategoryManagementProvider>();
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: provider,
        child: _CategoryFormSheet(category: category),
      ),
    );

    if (didSave == true && mounted) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: category == null
            ? 'Category created successfully.'
            : 'Category updated successfully.',
        success: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderCategoryManagementProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F1F4),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: AppText(
              'Categories',
              fontSize: 18,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColor.authButton,
            onPressed: provider.saving ? null : () => _openCategoryForm(),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add Category',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: AppColor.authButton,
            onRefresh: () => provider.fetchCategories(forceRefresh: true),
            child: _buildBody(provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(ProviderCategoryManagementProvider provider) {
    switch (provider.status) {
      case ProviderCategoryStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColor.authButton),
        );
      case ProviderCategoryStatus.error:
        return _StateMessage(
          icon: Icons.wifi_off_rounded,
          title: provider.error.isNotEmpty
              ? provider.error
              : 'Failed to load categories.',
          actionLabel: 'Retry',
          onTap: () => provider.fetchCategories(forceRefresh: true),
        );
      case ProviderCategoryStatus.empty:
        return _StateMessage(
          icon: Icons.category_outlined,
          title: 'No categories available.',
          actionLabel: 'Add Category',
          onTap: _openCategoryForm,
        );
      case ProviderCategoryStatus.initial:
        return const SizedBox.shrink();
      case ProviderCategoryStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
          itemCount: provider.categories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final category = provider.categories[index];
            return _CategoryCard(
              category: category,
              onEdit: () => _openCategoryForm(category),
            );
          },
        );
    }
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onEdit});

  final CategoryModel category;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isActive = category.isActive;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADDE2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColor.authButton.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: AppColor.authButton,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  category.categoryName,
                  fontSize: 16,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE8F7ED)
                        : const Color(0xFFFCE8E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    category.status,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF1F8F4C)
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColor.darkGrey),
          ),
        ],
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.category});

  final CategoryModel? category;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late String _status;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.category?.categoryName ?? '',
    );
    _status = widget.category?.status ?? 'Active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProviderCategoryManagementProvider>();
    final error = _isEdit
        ? await provider.updateCategory(
            id: widget.category!.id,
            categoryName: _nameCtrl.text.trim(),
            status: _status,
          )
        : await provider.createCategory(
            categoryName: _nameCtrl.text.trim(),
            status: _status,
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

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderCategoryManagementProvider>();
    final saving = provider.saving;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  _isEdit ? 'Edit Category' : 'Add Category',
                  fontSize: 18,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                ),
                const SizedBox(height: 6),
                AppText(
                  'Use this to manage category names and visibility.',
                  fontSize: 13,
                  color: AppColor.grey,
                ),
                const SizedBox(height: 18),
                const _FieldLabel('Category Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Enter category name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category name is required.';
                    }
                    if (value.trim().length > 150) {
                      return 'Category name must be under 150 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Status'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatusChip(
                        label: 'Active',
                        selected: _status == 'Active',
                        onTap: () => setState(() => _status = 'Active'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatusChip(
                        label: 'Inactive',
                        selected: _status == 'Inactive',
                        onTap: () => setState(() => _status = 'Inactive'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.authButton,
                      disabledBackgroundColor: AppColor.authButton.withValues(
                        alpha: 0.6,
                      ),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: saving
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
                        : Text(
                            _isEdit ? 'Update Category' : 'Create Category',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppText(
      label,
      fontSize: 13,
      fontWeight: FontWeights.semiBold,
      color: AppColor.darkGrey,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColor.authButton.withValues(alpha: 0.12)
              : const Color(0xFFF7F2F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColor.authButton : const Color(0xFFE3D7DC),
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

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: AppColor.grey),
                  const SizedBox(height: 16),
                  AppText(
                    title,
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
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8F3F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE4D9DD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE4D9DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColor.authButton),
    ),
  );
}
