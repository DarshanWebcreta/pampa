import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/urls.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/di.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

enum _SelectType { multiChip, singleGrid, singleList }

class _BeautySection {
  final String key;
  final String title;
  final List<String> options;
  final _SelectType selectType;
  List<String> selectedValues; // multi-select
  String? selectedValue; // single-select

  _BeautySection({
    required this.key,
    required this.title,
    required this.options,
    required this.selectType,
    required this.selectedValues,
    required this.selectedValue,
  });

  factory _BeautySection.fromJson(String key, Map<String, dynamic> json) {
    final title = json['title'] as String? ?? key;
    final options = (json['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final rawValue = json['value'];
    final isMulti = rawValue is List;

    // Determine visual layout: multi → chips; single → grid if all labels short, else list
    _SelectType selectType;
    if (isMulti) {
      selectType = _SelectType.multiChip;
    } else {
      final maxLen =
          options.fold<int>(0, (m, o) => o.length > m ? o.length : m);
      selectType = maxLen <= 8 ? _SelectType.singleGrid : _SelectType.singleList;
    }

    return _BeautySection(
      key: key,
      title: title,
      options: options,
      selectType: selectType,
      selectedValues: isMulti
          ? List<String>.from(rawValue.map((e) => e.toString()))
          : [],
      selectedValue: (!isMulti && rawValue is String) ? rawValue : null,
    );
  }

  bool get usesStandaloneOptionCards {
    final normalizedTitle = title.toLowerCase();
    final normalizedKey = key.toLowerCase();
    return normalizedTitle == 'typical budget per service' ||
        normalizedTitle == 'preferred appointment vibe' ||
        normalizedKey.contains('budget') ||
        normalizedKey.contains('vibe');
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BeautyPreferencesScreen extends StatefulWidget {
  const BeautyPreferencesScreen({super.key});

  @override
  State<BeautyPreferencesScreen> createState() =>
      _BeautyPreferencesScreenState();
}

class _BeautyPreferencesScreenState extends State<BeautyPreferencesScreen> {
  final _api = getIt<ApiService>();
  final _dio = getIt<Dio>();

  List<_BeautySection> _sections = [];
  bool _loading = true;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await _api.getBeautyPreferences();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as Map<String, dynamic>;
        setState(() {
          _sections = data.entries
              .map((e) =>
                  _BeautySection.fromJson(e.key, e.value as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = map['message']?.toString() ?? 'Failed to load preferences.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Failed to load preferences.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{};
    for (final s in _sections) {
      if (s.selectType == _SelectType.multiChip) {
        body[s.key] = s.selectedValues;
      } else {
        body[s.key] = s.selectedValue;
      }
    }

    try {
      await _dio.post(
        '${ApiStrings.baseUrl}${ApiPath.beautyPreferences}',
        data: body,
        options: Options(
          headers: {ApiStrings.contentType: ApiStrings.applicationJson},
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.authBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColor.darkGrey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AppText(
          'Beauty Preferences',
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
        centerTitle: false,
      ),
      body: _loading
          ? _buildShimmer()
          : _error.isNotEmpty
              ? _buildError()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        itemCount: _sections.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 24),
                        itemBuilder: (_, i) => _buildSection(_sections[i], i),
                      ),
                    ),
                    _buildSaveButton(),
                  ],
                ),
    );
  }

  Widget _buildSection(_BeautySection section, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          section.title,
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
        const SizedBox(height: 12),
        if (section.selectType == _SelectType.multiChip)
          _MultiChips(
            options: section.options,
            selected: section.selectedValues,
            onToggle: (opt) => setState(() {
              if (section.selectedValues.contains(opt)) {
                section.selectedValues.remove(opt);
              } else {
                section.selectedValues.add(opt);
              }
            }),
          )
        else if (section.selectType == _SelectType.singleGrid)
          _SingleGrid(
            options: section.options,
            selected: section.selectedValue,
            onSelect: (opt) => setState(() => section.selectedValue = opt),
          )
        else
          _SingleList(
            options: section.options,
            selected: section.selectedValue,
            onSelect: (opt) => setState(() => section.selectedValue = opt),
            useStandaloneCards: section.usesStandaloneOptionCards,
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: AppColor.authBg,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.authButton,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : AppText(
                  'Save Preferences',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 16, width: 140,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 12),
          Container(
              height: 56,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColor.authButton),
            const SizedBox(height: 12),
            AppText(_error,
                fontSize: FontSizes.small,
                color: AppColor.grey,
                align: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText('Try Again',
                    fontSize: FontSizes.regular,
                    fontWeight: FontWeights.semiBold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Multi-select chips ───────────────────────────────────────────────────────

class _MultiChips extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const _MultiChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () => onToggle(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColor.authButton : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? AppColor.authButton
                    : AppColor.authButton.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: AppText(
              opt,
              fontSize: FontSizes.small,
              fontWeight: FontWeights.medium,
              color: isSelected ? Colors.white : AppColor.darkGrey,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Single-select 2-column grid ─────────────────────────────────────────────

class _SingleGrid extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _SingleGrid({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.2,
      ),
      itemCount: options.length,
      itemBuilder: (_, i) {
        final opt = options[i];
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColor.authButton.withValues(alpha: 0.07)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColor.authButton
                    : const Color(0xFFE0E0E0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: AppText(
              opt,
              fontSize: FontSizes.regular,
              fontWeight:
                  isSelected ? FontWeights.semiBold : FontWeights.regular,
              color:
                  isSelected ? AppColor.authButton : AppColor.darkGrey,
            ),
          ),
        );
      },
    );
  }
}

// ─── Single-select full-width list ───────────────────────────────────────────

class _SingleList extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final bool useStandaloneCards;

  const _SingleList({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.useStandaloneCards = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final i = entry.key;
        final opt = entry.value;
        final isSelected = selected == opt;
        final isFirst = i == 0;
        final isLast = i == options.length - 1;

        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: useStandaloneCards
                ? EdgeInsets.only(bottom: isLast ? 0 : 10)
                : EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColor.authButton.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: useStandaloneCards
                  ? BorderRadius.circular(12)
                  : BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(12) : Radius.zero,
                      bottom: isLast ? const Radius.circular(12) : Radius.zero,
                    ),
              border: useStandaloneCards
                  ? Border.all(
                      color: isSelected
                          ? AppColor.authButton.withValues(alpha: 0.3)
                          : const Color(0xFFEEEEEE),
                    )
                  : Border(
                      top: isFirst
                          ? BorderSide(
                              color: isSelected
                                  ? AppColor.authButton.withValues(alpha: 0.3)
                                  : const Color(0xFFEEEEEE))
                          : BorderSide.none,
                      bottom: BorderSide(
                          color: isSelected
                              ? AppColor.authButton.withValues(alpha: 0.3)
                              : const Color(0xFFEEEEEE)),
                      left: BorderSide(
                          color: isSelected
                              ? AppColor.authButton.withValues(alpha: 0.3)
                              : const Color(0xFFEEEEEE)),
                      right: BorderSide(
                          color: isSelected
                              ? AppColor.authButton.withValues(alpha: 0.3)
                              : const Color(0xFFEEEEEE)),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    opt,
                    fontSize: FontSizes.regular,
                    fontWeight: isSelected
                        ? FontWeights.semiBold
                        : FontWeights.regular,
                    color: isSelected
                        ? AppColor.authButton
                        : AppColor.darkGrey,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_rounded,
                      size: 18, color: AppColor.authButton),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
