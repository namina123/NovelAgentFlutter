abstract class PendingResearchActionHandler {
  Future<void> onPendingResearchApproved(String requestId);

  Future<void> onPendingResearchRejected(String requestId);
}
