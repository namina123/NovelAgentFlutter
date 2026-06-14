import 'package:flutter/foundation.dart';

@immutable
class ConversationContextCompactionSegmentViewData {
  const ConversationContextCompactionSegmentViewData({
    required this.id,
    required this.title,
    required this.summary,
    required this.sourceMessageCount,
    required this.createdAt,
    required this.sourceMessageRoles,
  });

  final String id;
  final String title;
  final String summary;
  final int sourceMessageCount;
  final String createdAt;
  final List<String> sourceMessageRoles;

  String get sourceSummary {
    // 中文注释: 归档段只展示稳定的来源概览，避免把完整历史又展开成第二份长正文。
    if (sourceMessageCount <= 0) {
      return '来源消息未知';
    }
    return '来源 $sourceMessageCount 条消息';
  }

  String get foldedSummary {
    // 中文注释: 折叠摘要优先保留压缩段的首要结论，方便时间线在不展开细节时也能看懂归档发生了什么。
    final cleanSummary = summary.trim();
    if (cleanSummary.isNotEmpty) {
      return cleanSummary;
    }
    return sourceSummary;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConversationContextCompactionSegmentViewData &&
            other.id == id &&
            other.title == title &&
            other.summary == summary &&
            other.sourceMessageCount == sourceMessageCount &&
            other.createdAt == createdAt &&
            listEquals(other.sourceMessageRoles, sourceMessageRoles);
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    summary,
    sourceMessageCount,
    createdAt,
    Object.hashAll(sourceMessageRoles),
  );
}
