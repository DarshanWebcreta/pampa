class ConversationOtherUser {
  final int id;
  final String name;
  final String? photoUrl;

  const ConversationOtherUser({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  factory ConversationOtherUser.fromJson(Map<String, dynamic> json) {
    return ConversationOtherUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class ConversationLastMessage {
  final String body;
  final String senderType;
  final DateTime createdAt;

  const ConversationLastMessage({
    required this.body,
    required this.senderType,
    required this.createdAt,
  });

  factory ConversationLastMessage.fromJson(Map<String, dynamic> json) {
    return ConversationLastMessage(
      body: json['body'] as String? ?? '',
      senderType: json['sender_type'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ConversationModel {
  final int id;
  final ConversationOtherUser otherUser;
  final ConversationLastMessage? lastMessage;
  final int unreadCount;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  const ConversationModel({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final lastMsgJson = json['last_message'];
    return ConversationModel(
      id: json['id'] as int? ?? 0,
      otherUser: ConversationOtherUser.fromJson(
          json['other_user'] as Map<String, dynamic>? ?? {}),
      lastMessage: lastMsgJson is Map<String, dynamic>
          ? ConversationLastMessage.fromJson(lastMsgJson)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessageAt: DateTime.tryParse(json['last_message_at'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

enum MessageStatus { sending, sent, error }

class MessageModel {
  final int id;
  final String body;
  final String senderType;
  final String senderName;
  final DateTime? readAt;
  final DateTime createdAt;
  final MessageStatus status;

  const MessageModel({
    required this.id,
    required this.body,
    required this.senderType,
    required this.senderName,
    this.readAt,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  String get normalizedSenderType => senderType.trim().toLowerCase();
  bool get isFromCustomer => normalizedSenderType == 'customer';
  bool get isFromProvider => normalizedSenderType == 'provider';
  bool get isFromMe => isFromCustomer;

  MessageModel copyWith({
    int? id,
    String? body,
    String? senderType,
    String? senderName,
    DateTime? readAt,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      body: body ?? this.body,
      senderType: senderType ?? this.senderType,
      senderName: senderName ?? this.senderName,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int? ?? 0,
      body: json['body'] as String? ?? '',
      senderType: json['sender_type'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      status: MessageStatus.sent,
    );
  }
}
