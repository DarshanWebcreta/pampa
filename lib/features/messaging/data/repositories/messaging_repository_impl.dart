import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/messaging/data/models/conversation_model.dart';
import 'package:pampa/features/messaging/domain/repositories/messaging_repository.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final ApiService _apiService;
  MessagingRepositoryImpl(this._apiService);

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _apiService.getConversations();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(map['message'] ?? 'Failed to load conversations.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<List<ConversationModel>> getProviderConversations() async {
    try {
      final response = await _apiService.getProviderConversations();
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(map['message'] ?? 'Failed to load conversations.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<ConversationModel> createOrGetConversation({
    required int providerId,
    int? bookingId,
  }) async {
    try {
      final body = <String, dynamic>{'provider_id': providerId};
      if (bookingId != null) body['booking_id'] = bookingId;
      final response = await _apiService.createOrGetConversation(body);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return ConversationModel.fromJson(map['data'] as Map<String, dynamic>);
      }
      throw Exception(map['message'] ?? 'Failed to start conversation.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<ConversationModel> createOrGetProviderConversation({
    required int customerId,
    int? bookingId,
  }) async {
    try {
      final body = <String, dynamic>{'customer_id': customerId};
      if (bookingId != null) body['booking_id'] = bookingId;
      final response = await _apiService.createOrGetProviderConversation(body);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return ConversationModel.fromJson(map['data'] as Map<String, dynamic>);
      }
      throw Exception(map['message'] ?? 'Failed to start conversation.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<({ConversationModel conversation, List<MessageModel> messages})>
      getMessages(int conversationId) async {
    try {
      final response = await _apiService.getConversationMessages(conversationId);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as Map<String, dynamic>;
        final conversation = ConversationModel.fromJson(data);
        final msgs = (data['messages'] as List<dynamic>? ?? [])
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return (conversation: conversation, messages: msgs);
      }
      throw Exception(map['message'] ?? 'Failed to load messages.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<({ConversationModel conversation, List<MessageModel> messages})>
      getProviderMessages(int conversationId) async {
    try {
      final response =
          await _apiService.getProviderConversationMessages(conversationId);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as Map<String, dynamic>;
        final conversation = ConversationModel.fromJson(data);
        final msgs = (data['messages'] as List<dynamic>? ?? [])
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return (conversation: conversation, messages: msgs);
      }
      throw Exception(map['message'] ?? 'Failed to load messages.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    try {
      final response = await _apiService.sendMessage(
        conversationId,
        {'body': body},
      );
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return MessageModel.fromJson(map['data'] as Map<String, dynamic>);
      }
      throw Exception(map['message'] ?? 'Failed to send message.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<MessageModel> sendProviderMessage({
    required int conversationId,
    required String body,
  }) async {
    try {
      final response =
          await _apiService.sendProviderMessage(conversationId, {'body': body});
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        return MessageModel.fromJson(map['data'] as Map<String, dynamic>);
      }
      throw Exception(map['message'] ?? 'Failed to send message.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }
}
