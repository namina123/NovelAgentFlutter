class WorkbenchInformationViewData {
  const WorkbenchInformationViewData({
    this.title = '资料与设定',
    this.summary = '当前项目还没有可回看的资料摘要。',
    this.usageSummary = '本轮还没有可解释的资料使用记录。',
    this.entries = const <WorkbenchInformationEntryViewData>[],
    this.pendingEntries = const <WorkbenchInformationEntryViewData>[],
  });

  final String title;
  final String summary;
  final String usageSummary;
  final List<WorkbenchInformationEntryViewData> entries;
  final List<WorkbenchInformationEntryViewData> pendingEntries;

  bool get hasContent => entries.isNotEmpty || pendingEntries.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkbenchInformationViewData &&
            other.title == title &&
            other.summary == summary &&
            other.usageSummary == usageSummary &&
            _listEquals(other.entries, entries) &&
            _listEquals(other.pendingEntries, pendingEntries);
  }

  @override
  int get hashCode => Object.hash(
    title,
    summary,
    usageSummary,
    Object.hashAll(entries),
    Object.hashAll(pendingEntries),
  );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

class WorkbenchInformationEntryViewData {
  const WorkbenchInformationEntryViewData({
    required this.id,
    required this.title,
    required this.summary,
    required this.statusLabel,
    required this.actionLabel,
    required this.relativePath,
    this.subtitle = '',
    this.usageLabel = '',
    this.riskLabel = '',
    this.mountStatusLabel = '',
    this.sourceOfTruthSummary = '',
    this.sourceIdentitySummary = '',
    this.pendingResearchRequestId = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String summary;
  final String statusLabel;
  final String usageLabel;
  final String riskLabel;
  final String mountStatusLabel;
  final String sourceOfTruthSummary;
  final String sourceIdentitySummary;
  final String actionLabel;
  final String relativePath;
  final String pendingResearchRequestId;

  bool get supportsPendingResearchActions =>
      pendingResearchRequestId.trim().isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkbenchInformationEntryViewData &&
            other.id == id &&
            other.title == title &&
            other.subtitle == subtitle &&
            other.summary == summary &&
            other.statusLabel == statusLabel &&
            other.usageLabel == usageLabel &&
            other.riskLabel == riskLabel &&
            other.mountStatusLabel == mountStatusLabel &&
            other.sourceOfTruthSummary == sourceOfTruthSummary &&
            other.sourceIdentitySummary == sourceIdentitySummary &&
            other.actionLabel == actionLabel &&
            other.relativePath == relativePath &&
            other.pendingResearchRequestId == pendingResearchRequestId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    subtitle,
    summary,
    statusLabel,
    usageLabel,
    riskLabel,
    mountStatusLabel,
    sourceOfTruthSummary,
    sourceIdentitySummary,
    actionLabel,
    relativePath,
    pendingResearchRequestId,
  );
}
