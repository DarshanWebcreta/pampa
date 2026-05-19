import 'package:flutter/material.dart';
import 'package:pampa/features/support/domain/repositories/support_repository.dart';

enum SupportStatus { initial, loading, loaded, error, submitting, success }

class SupportProvider extends ChangeNotifier {
  final SupportRepository _repository;
  SupportProvider(this._repository);

  SupportStatus _status = SupportStatus.initial;
  SupportStatus get status => _status;

  List<String> _issueTypes = [];
  List<String> get issueTypes => _issueTypes;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> fetchIssueTypes() async {
    _status = SupportStatus.loading;
    notifyListeners();
    try {
      _issueTypes = await _repository.getIssueTypes();
      _status = SupportStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = SupportStatus.error;
    }
    notifyListeners();
  }

  Future<bool> reportIssue({
    required String issueType,
    String? customIssue,
    int? conversationId,
    int? messageId,
  }) async {
    _status = SupportStatus.submitting;
    notifyListeners();
    try {
      await _repository.reportIssue(
        issueType: issueType,
        customIssue: customIssue,
        conversationId: conversationId,
        messageId: messageId,
      );
      _status = SupportStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = SupportStatus.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = SupportStatus.initial;
    _errorMessage = '';
    notifyListeners();
  }
}
