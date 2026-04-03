import 'package:pampa/features/messaging/data/models/conversation_model.dart';

abstract class MessagingRepository {
  Future<List<ConversationModel>> getConversations();
  Future<List<ConversationModel>> getProviderConversations();
  Future<ConversationModel> createOrGetConversation({
    required int providerId,
    int? bookingId,
  });
  Future<ConversationModel> createOrGetProviderConversation({
    required int customerId,
    int? bookingId,
  });
  Future<({ConversationModel conversation, List<MessageModel> messages})>
      getMessages(int conversationId);
  Future<({ConversationModel conversation, List<MessageModel> messages})>
      getProviderMessages(int conversationId);
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
  });
  Future<MessageModel> sendProviderMessage({
    required int conversationId,
    required String body,
  });
}
