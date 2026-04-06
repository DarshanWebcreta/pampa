import 'package:flutter/material.dart';
import 'package:pampa/features/messaging/data/models/conversation_model.dart';
import 'package:pampa/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:pampa/features/messaging/presentation/provider/messaging_provider.dart';

class ProviderMessagingProvider extends ChangeNotifier {
  final MessagingRepository _repository;
  ProviderMessagingProvider(this._repository);

  ConversationsFetchStatus _convStatus = ConversationsFetchStatus.initial;
  List<ConversationModel> _conversations = [];
  String _convError = '';

  ConversationsFetchStatus get convStatus => _convStatus;
  List<ConversationModel> get conversations => _conversations;
  String get convError => _convError;

  MessagesFetchStatus _msgStatus = MessagesFetchStatus.initial;
  ConversationModel? _activeConversation;
  List<MessageModel> _messages = [];
  String _msgError = '';
  bool _isSending = false;

  MessagesFetchStatus get msgStatus => _msgStatus;
  ConversationModel? get activeConversation => _activeConversation;
  List<MessageModel> get messages => _messages;
  String get msgError => _msgError;
  bool get isSending => _isSending;

  Future<void> fetchConversations() async {
    if (_convStatus == ConversationsFetchStatus.loading) return;
    _convStatus = ConversationsFetchStatus.loading;
    _convError = '';
    notifyListeners();

    try {
      _conversations = await _repository.getProviderConversations();
      _convStatus = ConversationsFetchStatus.success;
    } catch (e) {
      _convError = e.toString().replaceFirst('Exception: ', '');
      _convStatus = ConversationsFetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshConversations() async {
    _convStatus = ConversationsFetchStatus.initial;
    await fetchConversations();
  }

  Future<void> openConversation(int conversationId) async {
    _msgStatus = MessagesFetchStatus.loading;
    _msgError = '';
    notifyListeners();

    try {
      final result = await _repository.getProviderMessages(conversationId);
      if (_msgStatus == MessagesFetchStatus.initial) return;
      _activeConversation = result.conversation;
      _messages = result.messages;
      _msgStatus = MessagesFetchStatus.success;
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        _conversations[idx] = ConversationModel(
          id: _conversations[idx].id,
          otherUser: _conversations[idx].otherUser,
          lastMessage: _conversations[idx].lastMessage,
          unreadCount: 0,
          lastMessageAt: _conversations[idx].lastMessageAt,
          createdAt: _conversations[idx].createdAt,
        );
      }
    } catch (e) {
      _msgError = e.toString().replaceFirst('Exception: ', '');
      _msgStatus = MessagesFetchStatus.error;
    }
    notifyListeners();
  }

  Future<bool> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    if (body.trim().isEmpty) return false;
    _isSending = true;
    notifyListeners();

    try {
      final msg = await _repository.sendProviderMessage(
        conversationId: conversationId,
        body: body.trim(),
      );
      _messages = [..._messages, msg];
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        _conversations[idx] = ConversationModel(
          id: _conversations[idx].id,
          otherUser: _conversations[idx].otherUser,
          lastMessage: ConversationLastMessage(
            body: msg.body,
            senderType: msg.senderType,
            createdAt: msg.createdAt,
          ),
          unreadCount: 0,
          lastMessageAt: msg.createdAt,
          createdAt: _conversations[idx].createdAt,
        );
      } else if (_activeConversation != null) {
        _conversations = [
          ConversationModel(
            id: _activeConversation!.id,
            otherUser: _activeConversation!.otherUser,
            lastMessage: ConversationLastMessage(
              body: msg.body,
              senderType: msg.senderType,
              createdAt: msg.createdAt,
            ),
            unreadCount: 0,
            lastMessageAt: msg.createdAt,
            createdAt: _activeConversation!.createdAt,
          ),
          ..._conversations,
        ];
      }
      _isSending = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<ConversationModel?> createOrGetConversation({
    required int customerId,
    int? bookingId,
  }) async {
    try {
      return await _repository.createOrGetProviderConversation(
        customerId: customerId,
        bookingId: bookingId,
      );
    } catch (_) {
      return null;
    }
  }

  void clearActiveConversation() {
    _activeConversation = null;
    _messages = [];
    _msgStatus = MessagesFetchStatus.initial;
    notifyListeners();
  }
}
