import 'package:pampa/features/messaging/data/models/conversation_model.dart';

abstract class MessagingRepository {
  Future<List<ConversationModel>> getConversations();
  Future<ConversationModel> createOrGetConversation({
    required int providerId,
    int? bookingId,
  });
  Future<({ConversationModel conversation, List<MessageModel> messages})> getMessages(int conversationId);
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
  });
}
