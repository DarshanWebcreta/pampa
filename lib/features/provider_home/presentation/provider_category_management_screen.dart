import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

// ─── Category card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onEdit});

  final CategoryModel category;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isActive = category.isActive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADDE2)),
      ),
      child: Row(
        children: [
          // ── Icon / Image ─────────────────────────────────────────────
          _CategoryIcon(iconUrl: category.icon),
          const SizedBox(width: 14),

          // ── Text info ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  category.categoryName,
                  fontSize: 15,
                  fontWeight: FontWeights.bold,
                  color: AppColor.darkGrey,
                ),
                if ((category.tag ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  AppText(
                    category.tag!,
                    fontSize: 12,
                    color: AppColor.grey,
                    maxLines: 1,
                  ),
                ],
                const SizedBox(height: 6),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
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
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Edit button ──────────────────────────────────────────────
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColor.darkGrey),
          ),
        ],
      ),
    );
  }
}

// ── Category icon widget ──────────────────────────────────────────────────────

class _CategoryIcon extends StatelessWidget {
  final String? iconUrl;

  const _CategoryIcon({this.iconUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = iconUrl != null && iconUrl!.isNotEmpty;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColor.authButton.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? FunctionalComponent.cachedNetworkImage(
              iconUrl!,
              fit: BoxFit.cover,
              radius: 14,
            )
          : const Icon(
              Icons.category_rounded,
              color: AppColor.authButton,
              size: 26,
            ),
    );
  }
}

// ─── Category form sheet ──────────────────────────────────────────────────────

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.category});

  final CategoryModel? category;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _tagCtrl;
  late String _status;
  File? _pickedIcon;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.category?.categoryName ?? '',
    );
    _tagCtrl = TextEditingController(
      text: widget.category?.tag ?? '',
    );
    _status = widget.category?.status ?? 'Active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedIcon = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProviderCategoryManagementProvider>();
    final error = _isEdit
        ? await provider.updateCategory(
            id: widget.category!.id,
            categoryName: _nameCtrl.text.trim(),
            status: _status,
            tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
            icon: _pickedIcon,
          )
        : await provider.createCategory(
            categoryName: _nameCtrl.text.trim(),
            status: _status,
            tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
            icon: _pickedIcon,
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  AppText(
                    _isEdit ? 'Edit Category' : 'Add Category',
                    fontSize: 18,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    'Manage category details, icon and visibility.',
                    fontSize: 13,
                    color: AppColor.grey,
                  ),
                  const SizedBox(height: 20),

                  // ── Icon picker ────────────────────────────────────────
                  const _FieldLabel('Category Icon'),
                  const SizedBox(height: 10),
                  _IconPickerTile(
                    existingUrl: widget.category?.icon,
                    pickedFile: _pickedIcon,
                    onTap: _pickIcon,
                  ),
                  const SizedBox(height: 16),

                  // ── Category Name ──────────────────────────────────────
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

                  // ── Tag ────────────────────────────────────────────────
                  const _FieldLabel('Tag / Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tagCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                        'e.g. Cuts, color, styling & treatments'),
                  ),
                  const SizedBox(height: 16),

                  // ── Status ─────────────────────────────────────────────
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

                  // ── Submit ─────────────────────────────────────────────
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
      ),
    );
  }
}

// ─── Icon picker tile ─────────────────────────────────────────────────────────

class _IconPickerTile extends StatelessWidget {
  final String? existingUrl;
  final File? pickedFile;
  final VoidCallback onTap;

  const _IconPickerTile({
    required this.onTap,
    this.existingUrl,
    this.pickedFile,
  });

  @override
  Widget build(BuildContext context) {
    final hasNew = pickedFile != null;
    final hasExisting = existingUrl != null && existingUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColor.authButton.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Preview box
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
                color: AppColor.authButton.withValues(alpha: 0.08),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasNew
                  ? Image.file(pickedFile!, fit: BoxFit.cover)
                  : hasExisting
                      ? FunctionalComponent.cachedNetworkImage(
                          existingUrl!,
                          fit: BoxFit.cover,
                          radius: 0,
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: AppColor.authButton,
                        ),
            ),

            // Label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasNew
                          ? 'Icon selected'
                          : hasExisting
                              ? 'Tap to change icon'
                              : 'Tap to upload icon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasNew
                            ? AppColor.authButton
                            : AppColor.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasNew
                          ? pickedFile!.path.split('/').last
                          : 'PNG, JPG supported',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Camera icon
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColor.authButton.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 18,
                  color: AppColor.authButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────

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

// ─── Status chip ──────────────────────────────────────────────────────────────

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

// ─── State message ────────────────────────────────────────────────────────────

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

// ─── Input decoration ─────────────────────────────────────────────────────────

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
