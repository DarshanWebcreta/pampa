import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:pampa/core/routes/routes.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/utils/functional_component.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';
import 'package:pampa/features/categories/data/models/category_model.dart';
import 'package:pampa/features/categories/presentation/provider/category_provider.dart';
import 'package:pampa/features/my_bookings/presentation/my_bookings_tab.dart';

// ─── Icon mapping for category names ──────────────────────────────────────────
IconData _iconForCategory(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('salon') || lower.contains('hair')) return Icons.content_cut_rounded;
  if (lower.contains('nail')) return Icons.colorize_rounded;
  if (lower.contains('makeup') || lower.contains('beauty')) return Icons.brush_rounded;
  if (lower.contains('massage') || lower.contains('spa')) return Icons.self_improvement_rounded;
  if (lower.contains('facial') || lower.contains('skin')) return Icons.face_retouching_natural_rounded;
  if (lower.contains('brow') || lower.contains('lash')) return Icons.auto_awesome_rounded;
  if (lower.contains('wax')) return Icons.waves_rounded;
  if (lower.contains('yoga') || lower.contains('fitness')) return Icons.fitness_center_rounded;
  return Icons.spa_rounded;
}

// ─── Bottom-nav item data ──────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

const _navItems = [
  _NavItem(icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,          label: 'Home'),
  _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Calendar'),
  _NavItem(icon: Icons.bookmark_border_rounded, activeIcon: Icons.bookmark_rounded,       label: 'Bookings'),
  _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages'),
  _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,         label: 'Profile'),
];

// ─── Main shell ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      context.read<AddressProvider>().fetchAddresses();
    });
  }

  void _showAddressPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AddressProvider>(),
        child: const _AddressPickerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _ServicesTab(),
          const _PlaceholderTab(icon: Icons.calendar_today_rounded, label: 'Calendar'),
          const MyBookingsTab(),
          const _PlaceholderTab(icon: Icons.chat_bubble_rounded,    label: 'Messages'),
          const _PlaceholderTab(icon: Icons.person_rounded,         label: 'Profile'),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 52),
      child: Container(
        color: AppColor.white,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Brand row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    AppText(
                      'Pampa',
                      fontSize: FontSizes.large,
                      fontWeight: FontWeights.bold,
                      color: AppColor.authButton,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.menu_rounded,
                          color: AppColor.authButton, size: 26),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              // ── Address bar ────────────────────────────────────────────
              GestureDetector(
                onTap: _showAddressPickerSheet,
                child: Consumer<AddressProvider>(
                  builder: (_, addrProvider, __) {
                    final addr = addrProvider.selectedAddress;
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColor.authBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColor.authButton.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColor.authButton, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: addr == null
                                ? AppText(
                                    addrProvider.isLoading
                                        ? 'Loading address...'
                                        : 'Add your address',
                                    fontSize: 13,
                                    color: AppColor.grey,
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        addr.addressName,
                                        fontSize: 13,
                                        fontWeight: FontWeights.semiBold,
                                        color: AppColor.darkGrey,
                                      ),
                                      AppText(
                                        '${addr.city}, ${addr.zipCode}',
                                        fontSize: 11,
                                        color: AppColor.grey,
                                      ),
                                    ],
                                  ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColor.authButton, size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(
          top: BorderSide(color: AppColor.lightGrey, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isActive = _currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        size: 22,
                        color: isActive ? AppColor.authButton : AppColor.offtab,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        item.label,
                        fontSize: 10,
                        fontWeight: isActive ? FontWeights.semiBold : FontWeights.regular,
                        color: isActive ? AppColor.authButton : AppColor.offtab,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Services tab ─────────────────────────────────────────────────────────────
class _ServicesTab extends StatelessWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          color: AppColor.authButton,
          onRefresh: () => provider.fetchCategories(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: AppText(
                    'Services',
                    fontSize: FontSizes.extraLarge,
                    fontWeight: FontWeights.bold,
                    color: AppColor.black,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              _buildBody(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CategoryProvider provider) {
    switch (provider.status) {
      case CategoryStatus.loading:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, index) => const _CategoryCardShimmer(),
              childCount: 6,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1,
            ),
          ),
        );

      case CategoryStatus.error:
        return SliverFillRemaining(
          child: _ErrorView(
            message: provider.errorMessage,
            onRetry: () => provider.refresh(),
          ),
        );

      case CategoryStatus.empty:
        return const SliverFillRemaining(
          child: _EmptyView(),
        );

      case CategoryStatus.initial:
        return const SliverToBoxAdapter(child: SizedBox.shrink());

      case CategoryStatus.success:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _CategoryCard(category: provider.categories[index]),
              childCount: provider.categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1,
            ),
          ),
        );
    }
  }
}

// ─── Category card ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          RouteNames.services,
          extra: {'categoryId': category.id, 'categoryName': category.categoryName},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.authBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColor.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.authButton.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _iconForCategory(category.categoryName),
                size: 28,
                color: AppColor.authButton,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AppText(
                category.categoryName,
                fontSize: FontSizes.small,
                fontWeight: FontWeights.semiBold,
                color: AppColor.authButton,
                align: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer placeholder ───────────────────────────────────────────────────────
class _CategoryCardShimmer extends StatefulWidget {
  const _CategoryCardShimmer();

  @override
  State<_CategoryCardShimmer> createState() => _CategoryCardShimmerState();
}

class _CategoryCardShimmerState extends State<_CategoryCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          decoration: BoxDecoration(
            color: AppColor.authBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColor.lightGrey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColor.lightGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColor.authBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 36, color: AppColor.authButton),
            ),
            const SizedBox(height: 20),
            AppText(
              'Something went wrong',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.semiBold,
              color: AppColor.darkGrey,
              align: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppText(
              message,
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  'Try Again',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty view ────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColor.authBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa_outlined, size: 36, color: AppColor.authButton),
            ),
            const SizedBox(height: 20),
            AppText(
              'No Services Available',
              fontSize: FontSizes.medium,
              fontWeight: FontWeights.semiBold,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 8),
            AppText(
              'Check back soon for available services.',
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Address picker sheet ─────────────────────────────────────────────────────
class _AddressPickerSheet extends StatefulWidget {
  const _AddressPickerSheet();

  @override
  State<_AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<_AddressPickerSheet> {
  bool _showAddForm = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _showAddForm
            ? _AddAddressForm(
                onBack: () => setState(() => _showAddForm = false),
                onSaved: () => setState(() => _showAddForm = false),
              )
            : _AddressList(
                onAddNew: () => setState(() => _showAddForm = true),
              ),
      ),
    );
  }
}

// ─── Address list inside sheet ────────────────────────────────────────────────
class _AddressList extends StatelessWidget {
  final VoidCallback onAddNew;
  const _AddressList({required this.onAddNew});

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressProvider>(
      builder: (_, provider, __) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.mediumGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                AppText('Your Addresses',
                    fontSize: FontSizes.medium,
                    fontWeight: FontWeights.bold,
                    color: AppColor.darkGrey),
                const Spacer(),
                GestureDetector(
                  onTap: onAddNew,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColor.authBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_rounded,
                            color: AppColor.authButton, size: 16),
                        const SizedBox(width: 4),
                        AppText('Add New',
                            fontSize: 12,
                            fontWeight: FontWeights.semiBold,
                            color: AppColor.authButton),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(color: AppColor.authButton),
                ),
              )
            else if (provider.addresses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColor.authBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_off_outlined,
                            color: AppColor.authButton, size: 26),
                      ),
                      const SizedBox(height: 12),
                      AppText('No addresses yet',
                          fontSize: FontSizes.regular,
                          fontWeight: FontWeights.semiBold,
                          color: AppColor.darkGrey),
                      const SizedBox(height: 4),
                      AppText('Add an address to get started',
                          fontSize: FontSizes.small, color: AppColor.grey),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: provider.addresses.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (_, i) {
                    final addr = provider.addresses[i];
                    final isSelected =
                        provider.selectedAddress?.id == addr.id;
                    return GestureDetector(
                      onTap: () {
                        provider.selectAddress(addr);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColor.authButton
                                    : AppColor.authBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: isSelected
                                    ? AppColor.white
                                    : AppColor.authButton,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    addr.addressName,
                                    fontSize: FontSizes.regular,
                                    fontWeight: FontWeights.semiBold,
                                    color: AppColor.darkGrey,
                                  ),
                                  const SizedBox(height: 2),
                                  AppText(
                                    '${addr.streetAddress}, ${addr.city} ${addr.zipCode}',
                                    fontSize: 12,
                                    color: AppColor.grey,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColor.authButton,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: AppColor.white, size: 14),
                              )
                            else if (addr.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColor.authBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: AppText('Default',
                                    fontSize: 10,
                                    color: AppColor.authButton),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Add address form inside sheet ────────────────────────────────────────────
class _AddAddressForm extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSaved;
  const _AddAddressForm({required this.onBack, required this.onSaved});

  @override
  State<_AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<_AddAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final savedZip = StorageManager.readData(StoreKeys.zipCode) as String?;
    if (savedZip != null && savedZip.isNotEmpty) _zipCtrl.text = savedZip;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AddressProvider>();
    final success = await provider.storeAddress(
      addressName: _nameCtrl.text.trim(),
      streetAddress: _streetCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      widget.onSaved();
      FunctionalComponent.showSnackBar(
        context: context,
        title: 'Address saved!',
        success: true,
      );
    } else {
      FunctionalComponent.showSnackBar(
        context: context,
        title: provider.saveError,
        success: false,
      );
      provider.resetSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColor.mediumGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColor.authBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColor.authButton, size: 14),
              ),
            ),
            const SizedBox(width: 12),
            AppText('Add New Address',
                fontSize: FontSizes.medium,
                fontWeight: FontWeights.bold,
                color: AppColor.darkGrey),
          ],
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _HomeAddressField(
                controller: _nameCtrl,
                label: 'Full Address',
                hint: 'e.g. 44/Otamba Society, Bapunagar',
                icon: Icons.home_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _HomeAddressField(
                controller: _streetCtrl,
                label: 'Street / House No.',
                hint: 'e.g. 33',
                icon: Icons.signpost_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HomeAddressField(
                      controller: _zipCtrl,
                      label: 'ZIP Code',
                      hint: '382350',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeAddressField(
                      controller: _cityCtrl,
                      label: 'City',
                      hint: 'Ahmedabad',
                      icon: Icons.location_city_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Consumer<AddressProvider>(
          builder: (_, provider, __) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.authButton,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: provider.isSaving ? null : _submit,
                child: provider.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColor.white, strokeWidth: 2.5),
                      )
                    : AppText('Save Address',
                        fontSize: FontSizes.regular,
                        fontWeight: FontWeights.semiBold,
                        color: AppColor.white),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HomeAddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const _HomeAddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColor.darkGrey),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColor.grey),
        labelStyle: const TextStyle(fontSize: 13, color: AppColor.grey),
        hintStyle: const TextStyle(fontSize: 13, color: AppColor.mediumGrey),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Placeholder tabs ──────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColor.authBg),
          const SizedBox(height: 12),
          AppText(label, fontSize: FontSizes.medium, color: AppColor.grey),
        ],
      ),
    );
  }
}
