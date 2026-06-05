import 'package:flutter/foundation.dart';

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
            listEquals(other.entries, entries) &&
            listEquals(other.pendingEntries, pendingEntries);
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
  });

  final String id;
  final String title;
  final String subtitle;
  final String summary;
  final String statusLabel;
  final String usageLabel;
  final String riskLabel;
  final String actionLabel;
  final String relativePath;

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
            other.actionLabel == actionLabel &&
            other.relativePath == relativePath;
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
    actionLabel,
    relativePath,
  );
}
