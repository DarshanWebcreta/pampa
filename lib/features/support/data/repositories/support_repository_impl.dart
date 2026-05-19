import 'package:dio/dio.dart';
import 'package:pampa/core/error/exception.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/features/support/domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  final ApiService _apiService;
  SupportRepositoryImpl(this._apiService);

  @override
  Future<List<String>> getIssueTypes() async {
    try {
      final response = await _apiService.getIssueTypes();
      final map = response as Map<String, dynamic>;
      if (map['success'] == true) {
        return List<String>.from(map['data']);
      }
      throw Exception(map['message'] ?? 'Failed to load issue types.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }

  @override
  Future<void> reportIssue({
    required String issueType,
    String? customIssue,
    int? conversationId,
    int? messageId,
  }) async {
    try {
      final body = {
        'issue_type': issueType,
        if (customIssue != null) 'custom_issue': customIssue,
        if (conversationId != null) 'conversation_id': conversationId,
        if (messageId != null) 'message_id': messageId,
      };
      final response = await _apiService.reportIssue(body);
      final map = response as Map<String, dynamic>;
      if (map['success'] == true) {
        return;
      }
      throw Exception(map['message'] ?? 'Failed to report issue.');
    } on DioException catch (e) {
      throw Exception(HandleExeption.handleError(e));
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }
  }
}
