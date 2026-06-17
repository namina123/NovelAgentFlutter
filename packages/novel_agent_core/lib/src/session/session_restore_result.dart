enum SessionRestoreScrollTarget {
  latest,
  preserveCurrentPosition,
}

class SessionRestoreResult {
  const SessionRestoreResult({
    required this.restoredSessionIds,
    required this.activeSessionId,
    required this.showSessionHistory,
    required this.defaultScrollTarget,
  });

  final List<String> restoredSessionIds;
  final String activeSessionId;
  final bool showSessionHistory;
  final SessionRestoreScrollTarget defaultScrollTarget;

  bool get hasRestoredSessions => restoredSessionIds.isNotEmpty;

  bool get hasHistoricalSessions => restoredSessionIds.length > 1;
}
