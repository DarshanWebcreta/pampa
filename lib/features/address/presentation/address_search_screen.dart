import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/features/address/presentation/provider/address_provider.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().clearSuggestions();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<AddressProvider>().fetchSuggestions(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColor.darkGrey),
        ),
        title: AppText(
          'Search Address',
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColor.white,
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.authBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 14, color: AppColor.darkGrey),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search for street, area, or zip code...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColor.mediumGrey),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColor.grey),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            context.read<AddressProvider>().clearSuggestions();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppColor.grey),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          // Suggestions List
          Expanded(
            child: Consumer<AddressProvider>(
              builder: (context, provider, _) {
                if (provider.isSuggestionsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColor.authButton),
                  );
                }

                final list = provider.suggestions;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 44, color: AppColor.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          AppText(
                            _searchCtrl.text.isEmpty
                                ? 'Type to search address details'
                                : 'No address suggestions found',
                            fontSize: FontSizes.small,
                            color: AppColor.grey,
                            align: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColor.lightGrey),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColor.authButton.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, size: 16, color: AppColor.authButton),
                      ),
                      title: AppText(
                        item.description ?? '',
                        fontSize: FontSizes.small,
                        fontWeight: FontWeights.medium,
                        color: AppColor.darkGrey,
                        maxLines: 2,
                      ),
                      subtitle: item.structuredFormatting?.mainText != null
                          ? AppText(
                              item.structuredFormatting!.mainText!,
                              fontSize: 11,
                              color: AppColor.grey,
                              maxLines: 1,
                            )
                          : null,
                      onTap: () async {
                        // Show overlay loading indicator while details are resolving
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(color: AppColor.authButton),
                          ),
                        );

                        final details = await provider.getPlaceDetails(item.placeId ?? '');
                        
                        if (context.mounted) {
                          Navigator.of(context).pop(); // dismiss loading dialog
                          if (details != null) {
                            final Map<String, String> updatedDetails = {
                              ...details,
                              'streetAddress': item.description ?? details['streetAddress'] ?? '',
                            };
                            Navigator.of(context).pop(updatedDetails); // return resolved components
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to resolve address details. Please try again.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
