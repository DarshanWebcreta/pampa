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
  bool _isReceivingNewMessage = false;
  int? _pendingConversationId;

  MessagesFetchStatus get msgStatus => _msgStatus;
  ConversationModel? get activeConversation => _activeConversation;
  List<MessageModel> get messages => _messages;
  String get msgError => _msgError;
  bool get isSending => _isSending;
  bool get isReceivingNewMessage => _isReceivingNewMessage;

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

  Future<void> silentRefreshConversations() async {
    try {
      _conversations = await _repository.getProviderConversations();
      if (_convStatus != ConversationsFetchStatus.success) {
        _convStatus = ConversationsFetchStatus.success;
      }
      notifyListeners();
    } catch (_) {
      // Ignore background refresh errors
    }
  }

  Future<void> openConversation(int conversationId) async {
    _pendingConversationId = conversationId;
    _activeConversation = null;
    _messages = [];
    _msgStatus = MessagesFetchStatus.loading;
    _msgError = '';
    notifyListeners();

    try {
      final result = await _repository.getProviderMessages(conversationId);
      if (_pendingConversationId != conversationId ||
          _msgStatus == MessagesFetchStatus.initial) {
        return;
      }
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

  Future<void> refreshActiveConversation(int conversationId) async {
    if (_pendingConversationId != conversationId) return;
    _isReceivingNewMessage = true;
    notifyListeners();
    
    // Artificial delay to make the typing indicator visible for a moment
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final result = await _repository.getProviderMessages(conversationId);
      if (_pendingConversationId == conversationId) {
        _messages = result.messages;
      }
    } catch (_) {}
    
    _isReceivingNewMessage = false;
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

  Future<void> openAdminChat() async {
    _msgStatus = MessagesFetchStatus.loading;
    _msgError = '';
    notifyListeners();

    try {
      final result = await _repository.getAdminChat();
      _activeConversation = result.conversation;
      _messages = result.messages;
      _pendingConversationId = result.conversation.id;
      _msgStatus = MessagesFetchStatus.success;
    } catch (e) {
      _msgError = e.toString().replaceFirst('Exception: ', '');
      _msgStatus = MessagesFetchStatus.error;
    }
    notifyListeners();
  }

  void clearActiveConversation() {
    _pendingConversationId = null;
    _activeConversation = null;
    _messages = [];
    _msgStatus = MessagesFetchStatus.initial;
    notifyListeners();
  }
}
