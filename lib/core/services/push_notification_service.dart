import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pampa/core/common_models/device_info.dart';
import 'package:flutter/material.dart';
import 'package:pampa/core/routes/pages.dart';
import 'package:pampa/core/storage/storage.dart';
import 'package:pampa/core/values/keys.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/di.dart';
import 'package:pampa/features/messaging/data/models/conversation_model.dart';
import 'package:pampa/features/messaging/presentation/chat_screen.dart';
import 'package:pampa/features/messaging/presentation/provider/messaging_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider/provider_messaging_provider.dart';
import 'package:pampa/features/provider_home/presentation/provider_chat_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('──────────────────────────────────────────');
  debugPrint('🔔 FCM [BACKGROUND]');
  debugPrint('   messageId  : ${message.messageId}');
  debugPrint('   title      : ${message.notification?.title}');
  debugPrint('   body       : ${message.notification?.body}');
  debugPrint('   data       : ${message.data}');
  debugPrint('──────────────────────────────────────────');
}

class PushNotificationService {
  static const int _maxNotificationId = 2147483647;

  PushNotificationService(this._apiService, this._deviceInfoService);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio();
  final ApiService _apiService;
  final DeviceInfoService _deviceInfoService;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'pampa_high_importance_channel',
    'Pampa Notifications',
    description: 'Notifications for bookings, messages, and account updates.',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermission();
    await _configureForegroundPresentation();
    await _cacheFcmToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _persistFcmToken(token);
    });
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // App was in background — give the navigator a frame to settle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(message);
      });
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _printPayload('LAUNCH', initialMessage);
      // App was killed — wait until the widget tree is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage);
        });
      });
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );
    }
  }

  Future<void> _configureForegroundPresentation() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _cacheFcmToken() async {
    final token = await _messaging.getToken();
    _persistFcmToken(token);
  }

  void _persistFcmToken(String? token) {
    if (token == null || token.isEmpty) return;
    StorageManager.saveData(StoreKeys.fcmToken, token);
    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }
  }

  Future<void> syncTokenWithBackend() async {
    final authToken = StorageManager.readData(StoreKeys.token) as String?;
    final notificationToken =
        StorageManager.readData(StoreKeys.fcmToken) as String?;
    final syncedToken =
        StorageManager.readData(StoreKeys.syncedFcmToken) as String?;

    if (authToken == null || authToken.isEmpty) return;
    if (notificationToken == null || notificationToken.isEmpty) return;
    if (syncedToken == notificationToken) return;

    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      final deviceId = deviceInfo['deviceId'] ?? 'unknown';

      await _apiService.submitNotificationToken({
        'device_id': deviceId,
        'notification_token': notificationToken,
      });

      StorageManager.saveData(StoreKeys.syncedFcmToken, notificationToken);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to sync notification token: $error');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _printPayload('FOREGROUND', message);
    _handleMessageType(message, navigate: false);
    await showRemoteMessage(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    _printPayload('TAP', message);
    _handleMessageType(message, navigate: true);
  }

  void _handleMessageType(RemoteMessage message, {required bool navigate}) {
    final type = message.data['type'] as String?;
    if (type != 'message') return;

    final conversationId = int.tryParse(message.data['id']?.toString() ?? '');
    if (conversationId == null) return;

    final userType = StorageManager.readData(StoreKeys.userType) as String?;
    final isProvider = userType == 'provider';

    // ── Refresh conversations list + specific conversation messages ────────
    if (isProvider) {
      final prov = getIt<ProviderMessagingProvider>();
      prov.refreshConversations();
      // If this conversation is currently open, refresh its messages too
      if (prov.activeConversation?.id == conversationId) {
        prov.openConversation(conversationId);
      }
    } else {
      try {
        final ctx = AppRouter.navigatorKey.currentContext;
        if (ctx != null) {
          final prov = ctx.read<MessagingProvider>();
          prov.refreshConversations();
          if (prov.activeConversation?.id == conversationId) {
            prov.openConversation(conversationId);
          }
        }
      } catch (_) {}
    }

    if (!navigate) return;

    // ── Navigate to chat ─────────────────────────────────────────────────────
    final navContext = AppRouter.navigatorKey.currentContext;
    if (navContext == null) return;

    final stub = ConversationModel(
      id: conversationId,
      otherUser: ConversationOtherUser(id: 0, name: ''),
      lastMessage: null,
      unreadCount: 0,
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    if (isProvider) {
      Navigator.of(navContext).push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: getIt<ProviderMessagingProvider>(),
          child: ProviderChatScreen(conversation: stub),
        ),
      ));
    } else {
      try {
        final msgProvider = navContext.read<MessagingProvider>();
        Navigator.of(navContext).push(MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: msgProvider,
            child: ChatScreen(conversation: stub),
          ),
        ));
      } catch (_) {}
    }
  }

  void _printPayload(String source, RemoteMessage message) {
    debugPrint('──────────────────────────────────────────');
    debugPrint('🔔 FCM [$source]');
    debugPrint('   messageId  : ${message.messageId}');
    debugPrint('   title      : ${message.notification?.title}');
    debugPrint('   body       : ${message.notification?.body}');
    debugPrint('   data       : ${message.data}');
    debugPrint('──────────────────────────────────────────');
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 LOCAL TAP payload: ${response.payload}');
    _handleLocalPayload(response.payload);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 LOCAL BG TAP payload: ${response.payload}');
    // Background static handler — cannot access instance members;
    // onMessageOpenedApp will fire instead for FCM background taps.
  }

  void _handleLocalPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final fakeMessage = RemoteMessage(data: data.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      ));
      _handleMessageType(fakeMessage, navigate: true);
    } catch (_) {}
  }

  Future<void> showRemoteMessage(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Pampa';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';
    final imageUrl = _extractImageUrl(message);
    final imagePath = imageUrl == null ? null : await _downloadImage(imageUrl);

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: imagePath == null
          ? BigTextStyleInformation(body)
          : BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              contentTitle: title,
              summaryText: body,
            ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: imagePath == null
          ? null
          : <DarwinNotificationAttachment>[
              DarwinNotificationAttachment(imagePath),
            ],
    );

    await _localNotifications.show(
      _notificationIdFor(message),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(message.data),
    );
  }

  int _notificationIdFor(RemoteMessage message) {
    final baseId = message.messageId?.hashCode ??
        message.sentTime?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    return baseId.abs() % _maxNotificationId;
  }

  String? _extractImageUrl(RemoteMessage message) {
    final candidates = <String?>[
      message.data['image']?.toString(),
      message.data['imageUrl']?.toString(),
      message.data['image_url']?.toString(),
      message.notification?.android?.imageUrl,
      message.notification?.apple?.imageUrl,
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }

  Future<String?> _downloadImage(String url) async {
    try {
      final directory = await getTemporaryDirectory();
      final extension = _fileExtension(url);
      final file = File(
        '${directory.path}/notification_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      await _dio.download(url, file.path);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String _fileExtension(String url) {
    final uri = Uri.tryParse(url);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : '';
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex == -1) return '.jpg';
    return lastSegment.substring(dotIndex);
  }
}
