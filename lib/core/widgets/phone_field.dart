import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';

// ─── Country model ────────────────────────────────────────────────────────────

class CountryCode {
  final String name;
  final String flag;
  final String dial; // e.g. "+1"
  final String code; // ISO e.g. "US"

  const CountryCode({
    required this.name,
    required this.flag,
    required this.dial,
    required this.code,
  });
}

// ─── Common country list ──────────────────────────────────────────────────────

const List<CountryCode> kCountryCodes = [
  CountryCode(name: 'United States',    flag: '🇺🇸', dial: '+1',   code: 'US'),
  CountryCode(name: 'United Kingdom',   flag: '🇬🇧', dial: '+44',  code: 'GB'),
  CountryCode(name: 'India',            flag: '🇮🇳', dial: '+91',  code: 'IN'),
  CountryCode(name: 'Canada',           flag: '🇨🇦', dial: '+1',   code: 'CA'),
  CountryCode(name: 'Australia',        flag: '🇦🇺', dial: '+61',  code: 'AU'),
  CountryCode(name: 'Germany',          flag: '🇩🇪', dial: '+49',  code: 'DE'),
  CountryCode(name: 'France',           flag: '🇫🇷', dial: '+33',  code: 'FR'),
  CountryCode(name: 'Italy',            flag: '🇮🇹', dial: '+39',  code: 'IT'),
  CountryCode(name: 'Spain',            flag: '🇪🇸', dial: '+34',  code: 'ES'),
  CountryCode(name: 'Brazil',           flag: '🇧🇷', dial: '+55',  code: 'BR'),
  CountryCode(name: 'Mexico',           flag: '🇲🇽', dial: '+52',  code: 'MX'),
  CountryCode(name: 'Japan',            flag: '🇯🇵', dial: '+81',  code: 'JP'),
  CountryCode(name: 'China',            flag: '🇨🇳', dial: '+86',  code: 'CN'),
  CountryCode(name: 'South Korea',      flag: '🇰🇷', dial: '+82',  code: 'KR'),
  CountryCode(name: 'Singapore',        flag: '🇸🇬', dial: '+65',  code: 'SG'),
  CountryCode(name: 'UAE',              flag: '🇦🇪', dial: '+971', code: 'AE'),
  CountryCode(name: 'Saudi Arabia',     flag: '🇸🇦', dial: '+966', code: 'SA'),
  CountryCode(name: 'Pakistan',         flag: '🇵🇰', dial: '+92',  code: 'PK'),
  CountryCode(name: 'Bangladesh',       flag: '🇧🇩', dial: '+880', code: 'BD'),
  CountryCode(name: 'Nigeria',          flag: '🇳🇬', dial: '+234', code: 'NG'),
  CountryCode(name: 'South Africa',     flag: '🇿🇦', dial: '+27',  code: 'ZA'),
  CountryCode(name: 'Kenya',            flag: '🇰🇪', dial: '+254', code: 'KE'),
  CountryCode(name: 'Ghana',            flag: '🇬🇭', dial: '+233', code: 'GH'),
  CountryCode(name: 'Netherlands',      flag: '🇳🇱', dial: '+31',  code: 'NL'),
  CountryCode(name: 'Switzerland',      flag: '🇨🇭', dial: '+41',  code: 'CH'),
  CountryCode(name: 'Sweden',           flag: '🇸🇪', dial: '+46',  code: 'SE'),
  CountryCode(name: 'Norway',           flag: '🇳🇴', dial: '+47',  code: 'NO'),
  CountryCode(name: 'Denmark',          flag: '🇩🇰', dial: '+45',  code: 'DK'),
  CountryCode(name: 'Finland',          flag: '🇫🇮', dial: '+358', code: 'FI'),
  CountryCode(name: 'Poland',           flag: '🇵🇱', dial: '+48',  code: 'PL'),
  CountryCode(name: 'Turkey',           flag: '🇹🇷', dial: '+90',  code: 'TR'),
  CountryCode(name: 'Greece',           flag: '🇬🇷', dial: '+30',  code: 'GR'),
  CountryCode(name: 'Portugal',         flag: '🇵🇹', dial: '+351', code: 'PT'),
  CountryCode(name: 'Russia',           flag: '🇷🇺', dial: '+7',   code: 'RU'),
  CountryCode(name: 'Philippines',      flag: '🇵🇭', dial: '+63',  code: 'PH'),
  CountryCode(name: 'Indonesia',        flag: '🇮🇩', dial: '+62',  code: 'ID'),
  CountryCode(name: 'Malaysia',         flag: '🇲🇾', dial: '+60',  code: 'MY'),
  CountryCode(name: 'Thailand',         flag: '🇹🇭', dial: '+66',  code: 'TH'),
  CountryCode(name: 'Vietnam',          flag: '🇻🇳', dial: '+84',  code: 'VN'),
  CountryCode(name: 'Egypt',            flag: '🇪🇬', dial: '+20',  code: 'EG'),
  CountryCode(name: 'Argentina',        flag: '🇦🇷', dial: '+54',  code: 'AR'),
  CountryCode(name: 'Colombia',         flag: '🇨🇴', dial: '+57',  code: 'CO'),
  CountryCode(name: 'Chile',            flag: '🇨🇱', dial: '+56',  code: 'CL'),
  CountryCode(name: 'Peru',             flag: '🇵🇪', dial: '+51',  code: 'PE'),
  CountryCode(name: 'New Zealand',      flag: '🇳🇿', dial: '+64',  code: 'NZ'),
  CountryCode(name: 'Ireland',          flag: '🇮🇪', dial: '+353', code: 'IE'),
];

// ─── Phone field widget ───────────────────────────────────────────────────────

/// A phone number input with a country code selector prefix.
///
/// Usage:
/// ```dart
/// PhoneField(
///   controller: _mobileController,
///   onCountryChanged: (country) => _selectedCountry = country,
/// )
/// ```
///
/// To get the full phone number (dial code + number):
/// ```dart
/// final fullNumber = '${_selectedCountry.dial}${_mobileController.text.trim()}';
/// ```
class PhoneField extends StatefulWidget {
  final TextEditingController controller;

  /// Fill color — matches the surrounding form card bg.
  final Color? fillColor;

  /// Initial country (defaults to US).
  final CountryCode initialCountry;

  /// Called whenever the selected country changes.
  final ValueChanged<CountryCode>? onCountryChanged;

  /// Optional validator for the number part.
  final String? Function(String?)? validator;

  final double radius;
  final TextInputAction action;

  const PhoneField({
    super.key,
    required this.controller,
    this.fillColor,
    this.initialCountry = const CountryCode(
      name: 'United States',
      flag: '🇺🇸',
      dial: '+1',
      code: 'US',
    ),
    this.onCountryChanged,
    this.validator,
    this.radius = 12,
    this.action = TextInputAction.next,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late CountryCode _selected;
  final _searchCtrl = TextEditingController();
  List<CountryCode> _filtered = kCountryCodes;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCountry;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = kCountryCodes
          .where((c) =>
              c.name.toLowerCase().contains(lower) ||
              c.dial.contains(lower) ||
              c.code.toLowerCase().contains(lower))
          .toList();
    });
  }

  void _openPicker() {
    _searchCtrl.clear();
    _filtered = kCountryCodes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CountryPickerSheet(
        filtered: _filtered,
        searchCtrl: _searchCtrl,
        onFilter: _filter,
        onSelect: (country) {
          setState(() => _selected = country);
          widget.onCountryChanged?.call(country);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.fillColor ?? AppColor.authBg;
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      textInputAction: widget.action,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: FontSizes.regular,
        color: AppColor.darkGrey,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          borderSide: const BorderSide(color: AppColor.mediumGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          borderSide: const BorderSide(color: AppColor.mediumGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          borderSide:
              const BorderSide(color: AppColor.authButton, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        hintText: 'Phone number',
        hintStyle: const TextStyle(color: AppColor.grey, fontSize: 14),
        prefixIcon: GestureDetector(
          onTap: _openPicker,
          child: Container(
            constraints: const BoxConstraints(minWidth: 80),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColor.mediumGrey,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selected.flag,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                Text(
                  _selected.dial,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColor.darkGrey,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down_rounded,
                    size: 18, color: AppColor.grey),
              ],
            ),
          ),
        ),
      ),
      validator: widget.validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            if (value.trim().length < 6) {
              return 'Enter a valid phone number';
            }
            return null;
          },
    );
  }
}

// ─── Country picker bottom sheet ──────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final List<CountryCode> filtered;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onFilter;
  final ValueChanged<CountryCode> onSelect;

  const _CountryPickerSheet({
    required this.filtered,
    required this.searchCtrl,
    required this.onFilter,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late List<CountryCode> _list;

  @override
  void initState() {
    super.initState();
    _list = List.from(kCountryCodes);
    widget.searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_onSearch);
    super.dispose();
  }

  void _onSearch() {
    final q = widget.searchCtrl.text.toLowerCase();
    setState(() {
      _list = kCountryCodes
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.dial.contains(q) ||
              c.code.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle ─────────────────────────────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColor.mediumGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select Country Code',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColor.darkGrey,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Search ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: widget.searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search country or code...',
                hintStyle:
                    const TextStyle(color: AppColor.grey, fontSize: 14),
                filled: true,
                fillColor: AppColor.authBg,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColor.grey, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColor.authButton, width: 1.2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: _list.isEmpty
                ? const Center(
                    child: Text('No results found',
                        style: TextStyle(color: AppColor.grey)),
                  )
                : ListView.builder(
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final c = _list[i];
                      return InkWell(
                        onTap: () => widget.onSelect(c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13),
                          child: Row(
                            children: [
                              Text(c.flag,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColor.darkGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                c.dial,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColor.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
