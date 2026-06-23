import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/values/urls.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/di.dart';

class _NotificationPref {
  final String id;
  final String title;
  final String description;
  final String icon;
  bool value;

  _NotificationPref({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
  });

  factory _NotificationPref.fromJson(Map<String, dynamic> json) {
    return _NotificationPref(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      value: json['value'] as bool? ?? false,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = getIt<ApiService>();
  final _dio = getIt<Dio>();

  bool _pushNotifications = true;
  bool _smsNotifications = true;
  bool _emailNotifications = true;
  List<_NotificationPref> _prefs = [];
  bool _loading = true;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await _api.getNotificationPreferences();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final rawData = map['data'];
        setState(() {
          if (rawData is List) {
            _prefs = rawData
                .map((e) => _NotificationPref.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (rawData is Map<String, dynamic>) {
            _pushNotifications = rawData['push_notifications'] as bool? ?? false;
            _smsNotifications = rawData['sms_notifications'] as bool? ?? false;
            _emailNotifications = rawData['email_notifications'] as bool? ?? false;
            
            final types = rawData['types'] as List<dynamic>? ?? [];
            _prefs = types
                .map((e) => _NotificationPref.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          _loading = false;
        });
      } else {
        setState(() {
          _error = map['message']?.toString() ?? 'Failed to load preferences.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load preferences.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleChannel(String channel, bool newValue) async {
    if (_saving) return;

    final oldPush = _pushNotifications;
    final oldSms = _smsNotifications;
    final oldEmail = _emailNotifications;

    setState(() {
      _saving = true;
      if (channel == 'push') _pushNotifications = newValue;
      if (channel == 'sms') _smsNotifications = newValue;
      if (channel == 'email') _emailNotifications = newValue;
    });

    try {
      final body = <String, dynamic>{
        'push_notifications': _pushNotifications,
        'sms_notifications': _smsNotifications,
        'email_notifications': _emailNotifications,
        for (final p in _prefs) p.id: p.value,
      };
      await _dio.post(
        '${ApiStrings.baseUrl}${ApiPath.notificationPreferences}',
        data: body,
        options: Options(
          headers: {ApiStrings.contentType: ApiStrings.applicationJson},
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _pushNotifications = oldPush;
          _smsNotifications = oldSms;
          _emailNotifications = oldEmail;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _togglePref(int index, bool newValue) async {
    if (_saving) return;

    final oldVal = _prefs[index].value;
    setState(() {
      _saving = true;
      _prefs[index].value = newValue;
    });

    try {
      final body = <String, dynamic>{
        'push_notifications': _pushNotifications,
        'sms_notifications': _smsNotifications,
        'email_notifications': _emailNotifications,
        for (final p in _prefs) p.id: p.value,
      };
      await _dio.post(
        '${ApiStrings.baseUrl}${ApiPath.notificationPreferences}',
        data: body,
        options: Options(
          headers: {ApiStrings.contentType: ApiStrings.applicationJson},
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _prefs[index].value = oldVal);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'calendar':
        return Icons.calendar_today_outlined;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'bell':
        return Icons.notifications_outlined;
      case 'gift':
        return Icons.card_giftcard_outlined;
      case 'trending-up':
        return Icons.trending_up_rounded;
      default:
        return Icons.notifications_outlined;
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
          'Notifications',
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const _LoadingShimmer()
          : _error.isNotEmpty
              ? _ErrorView(message: _error, onRetry: _fetchPreferences)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    AppText(
                      'Notification Channels',
                      fontSize: FontSizes.regular,
                      fontWeight: FontWeights.bold,
                      color: AppColor.darkGrey,
                    ),
                    const SizedBox(height: 12),
                    _PrefTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Push Notifications',
                      description: 'Receive notifications directly on your device',
                      value: _pushNotifications,
                      onChanged: (v) => _toggleChannel('push', v),
                    ),
                    const SizedBox(height: 10),
                    _PrefTile(
                      icon: Icons.textsms_outlined,
                      title: 'SMS Notifications',
                      description: 'Receive text message updates',
                      value: _smsNotifications,
                      onChanged: (v) => _toggleChannel('sms', v),
                    ),
                    const SizedBox(height: 10),
                    _PrefTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'Email Notifications',
                      description: 'Receive email alerts and updates',
                      value: _emailNotifications,
                      onChanged: (v) => _toggleChannel('email', v),
                    ),
                    const SizedBox(height: 24),
                    AppText(
                      'Notification Preferences',
                      fontSize: FontSizes.regular,
                      fontWeight: FontWeights.bold,
                      color: AppColor.darkGrey,
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_prefs.length, (i) {
                      final pref = _prefs[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: i == _prefs.length - 1 ? 0 : 10),
                        child: _PrefTile(
                          icon: _iconFor(pref.icon),
                          title: pref.title,
                          description: pref.description,
                          value: pref.value,
                          onChanged: (v) => _togglePref(i, v),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColor.authButton.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColor.authButton),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: AppColor.darkGrey,
                ),
                const SizedBox(height: 2),
                AppText(
                  description,
                  fontSize: 12,
                  color: AppColor.grey,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColor.authButton,
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

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
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColor.authButton),
            const SizedBox(height: 12),
            AppText(
              message,
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  'Try Again',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
