abstract class SupportRepository {
  Future<List<String>> getIssueTypes();
  Future<void> reportIssue({
    required String issueType,
    String? customIssue,
    int? conversationId,
    int? messageId,
  });
}
