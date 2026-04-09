import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_service_management_provider.dart';
import 'package:pampa/features/services/data/models/service_model.dart';

class ProviderServiceManagementScreen extends StatefulWidget {
  const ProviderServiceManagementScreen({super.key});

  @override
  State<ProviderServiceManagementScreen> createState() =>
      _ProviderServiceManagementScreenState();
}

class _ProviderServiceManagementScreenState
    extends State<ProviderServiceManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderServiceManagementProvider>().initialize();
    });
  }

  Future<void> _openServiceForm([ServiceModel? service]) async {
    final provider = context.read<ProviderServiceManagementProvider>();
    if (provider.categories.isEmpty &&
        provider.status != ProviderServiceStatus.loading) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Create a category first before adding services.',
        success: false,
      );
      return;
    }

    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _ServiceFormSheet(service: service),
      ),
    );

    if (didSave == true && mounted) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: service == null
            ? 'Service created successfully.'
            : 'Service updated successfully.',
        success: true,
      );
    }
  }

  Future<void> _confirmDelete(ServiceModel service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Service'),
        content: Text('Delete "${service.serviceName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<ProviderServiceManagementProvider>();
    final error = await provider.deleteService(service.id);
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
      title: 'Service deleted successfully.',
      success: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderServiceManagementProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F1F4),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: AppText(
              'Services',
              fontSize: 18,
              fontWeight: FontWeights.bold,
              color: AppColor.darkGrey,
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColor.authButton,
            onPressed: provider.saving ? null : () => _openServiceForm(),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add Service',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: AppColor.authButton,
            onRefresh: () => provider.initialize(forceRefresh: true),
            child: _buildBody(provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(ProviderServiceManagementProvider provider) {
    switch (provider.status) {
      case ProviderServiceStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColor.authButton),
        );
      case ProviderServiceStatus.error:
        return _ServiceStateMessage(
          icon: Icons.wifi_off_rounded,
          title: provider.error.isNotEmpty
              ? provider.error
              : 'Failed to load services.',
          actionLabel: 'Retry',
          onTap: provider.initialize,
        );
      case ProviderServiceStatus.empty:
        return _ServiceStateMessage(
          icon: Icons.content_cut_rounded,
          title: 'No services found for this provider.',
          actionLabel: 'Add Service',
          onTap: () => _openServiceForm(),
        );
      case ProviderServiceStatus.initial:
        return const SizedBox.shrink();
      case ProviderServiceStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
          itemCount: provider.services.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final service = provider.services[index];
            return _ServiceCard(
              service: service,
              onEdit: () => _openServiceForm(service),
              onDelete: () => _confirmDelete(service),
            );
          },
        );
    }
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = service.isActive;
    final hasImage = service.image.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADDE2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFF6EFF2),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? FunctionalComponent.cachedNetworkImage(
                        service.image,
                        radius: 0,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.design_services_rounded,
                        color: AppColor.authButton,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      service.serviceName,
                      fontSize: 16,
                      fontWeight: FontWeights.bold,
                      color: AppColor.darkGrey,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      service.category?.categoryName ??
                          'Category #${service.categoryId}',
                      fontSize: 13,
                      color: AppColor.grey,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(label: service.formattedPrice),
                        _InfoPill(label: service.formattedDuration),
                        _InfoPill(
                          label: service.status,
                          foreground: isActive
                              ? const Color(0xFF1F8F4C)
                              : Colors.red.shade700,
                          background: isActive
                              ? const Color(0xFFE8F7ED)
                              : const Color(0xFFFDECEC),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((service.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: AppText(
                service.description!.trim(),
                fontSize: 13,
                color: AppColor.grey,
                maxLines: 3,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    this.foreground = AppColor.darkGrey,
    this.background = const Color(0xFFF6EFF2),
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ServiceFormSheet extends StatefulWidget {
  const _ServiceFormSheet({this.service});

  final ServiceModel? service;

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _depositCtrl;
  late final TextEditingController _priorityFeeCtrl;
  late final TextEditingController _descriptionCtrl;

  int? _categoryId;
  late String _status;
  File? _image;

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameCtrl = TextEditingController(text: service?.serviceName ?? '');
    _priceCtrl = TextEditingController(text: service?.price ?? '');
    _durationCtrl = TextEditingController(
      text: service != null && service.duration > 0
          ? '${service.duration}'
          : '',
    );
    _depositCtrl = TextEditingController(
      text: service != null && service.deposit > 0
          ? '${service.deposit.toInt()}'
          : '',
    );
    _priorityFeeCtrl = TextEditingController(
      text: service != null && service.priorityFee > 0
          ? '${service.priorityFee.toInt()}'
          : '',
    );
    _descriptionCtrl = TextEditingController(text: service?.description ?? '');
    _categoryId = service?.categoryId;
    _status = service?.status ?? 'Active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _depositCtrl.dispose();
    _priorityFeeCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Please select a category.',
        success: false,
      );
      return;
    }

    final provider = context.read<ProviderServiceManagementProvider>();
    final error = _isEdit
        ? await provider.updateService(
            id: widget.service!.id,
            categoryId: _categoryId!,
            serviceName: _nameCtrl.text.trim(),
            price: _priceCtrl.text.trim(),
            duration: _durationCtrl.text.trim(),
            status: _status,
            deposit: _depositCtrl.text.trim(),
            priorityFee: _priorityFeeCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            image: _image,
          )
        : await provider.createService(
            categoryId: _categoryId!,
            serviceName: _nameCtrl.text.trim(),
            price: _priceCtrl.text.trim(),
            duration: _durationCtrl.text.trim(),
            status: _status,
            deposit: _depositCtrl.text.trim(),
            priorityFee: _priorityFeeCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            image: _image,
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
    final provider = context.watch<ProviderServiceManagementProvider>();
    final categories = provider.categories;
    final currentCategoryId = _categoryId;
    final hasSelectedCategory =
        currentCategoryId != null &&
        categories.any((item) => item.id == currentCategoryId);

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    _isEdit ? 'Edit Service' : 'Add Service',
                    fontSize: 18,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey,
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    'Manage your provider service details, pricing and image.',
                    fontSize: 13,
                    color: AppColor.grey,
                  ),
                  const SizedBox(height: 18),
                  const _ServiceFieldLabel('Category'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: hasSelectedCategory
                        ? currentCategoryId
                        : null,
                    decoration: _serviceInputDecoration('Select category'),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(category.categoryName),
                          ),
                        )
                        .toList(),
                    onChanged: provider.saving
                        ? null
                        : (value) => setState(() => _categoryId = value),
                    validator: (value) =>
                        value == null ? 'Category is required.' : null,
                  ),
                  const SizedBox(height: 16),
                  const _ServiceFieldLabel('Service Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _serviceInputDecoration('Express Haircut'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Service name is required.';
                      }
                      if (value.trim().length > 150) {
                        return 'Service name must be under 150 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: _priceCtrl,
                          label: 'Price',
                          hint: '65.00',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed < 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberField(
                          controller: _durationCtrl,
                          label: 'Duration',
                          hint: '45',
                          suffix: 'min',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed < 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: _depositCtrl,
                          label: 'Deposit %',
                          hint: '20',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed < 0 || parsed > 100) {
                              return '0-100';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberField(
                          controller: _priorityFeeCtrl,
                          label: 'Priority Fee %',
                          hint: '10',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed < 0 || parsed > 100) {
                              return '0-100';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ServiceFieldLabel('Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    decoration: _serviceInputDecoration(
                      'Optional service description',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _ServiceFieldLabel('Status'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ServiceStatusChip(
                          label: 'Active',
                          selected: _status == 'Active',
                          onTap: () => setState(() => _status = 'Active'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ServiceStatusChip(
                          label: 'Inactive',
                          selected: _status == 'Inactive',
                          onTap: () => setState(() => _status = 'Inactive'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ServiceFieldLabel('Image'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: provider.saving ? null : _pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F3F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE4D9DD)),
                      ),
                      child: Row(
                        children: [
                          _ServiceImagePreview(
                            imageFile: _image,
                            imageUrl: widget.service?.image,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upload service image',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.darkGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _image != null
                                      ? _image!.path.split('/').last
                                      : (_isEdit
                                            ? 'Tap to replace current image'
                                            : 'PNG or JPG up to 2 MB'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColor.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.photo_library_outlined),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.saving ? null : _submit,
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
                          : Text(
                              _isEdit ? 'Update Service' : 'Create Service',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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

class _ServiceImagePreview extends StatelessWidget {
  const _ServiceImagePreview({required this.imageFile, this.imageUrl});

  final File? imageFile;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageFile != null
          ? Image.file(imageFile!, fit: BoxFit.cover)
          : hasNetworkImage
          ? FunctionalComponent.cachedNetworkImage(
              imageUrl!,
              radius: 0,
              fit: BoxFit.cover,
            )
          : const Icon(Icons.image_outlined, color: AppColor.authButton),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ServiceFieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _serviceInputDecoration(
            hint,
          ).copyWith(suffixText: suffix),
          validator: validator,
        ),
      ],
    );
  }
}

class _ServiceFieldLabel extends StatelessWidget {
  const _ServiceFieldLabel(this.label);

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

class _ServiceStatusChip extends StatelessWidget {
  const _ServiceStatusChip({
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

class _ServiceStateMessage extends StatelessWidget {
  const _ServiceStateMessage({
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

InputDecoration _serviceInputDecoration(String hint) {
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
