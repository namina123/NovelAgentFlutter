import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'foreshadow_record.dart';
import 'foreshadow_status_catalog_service.dart';
import 'relationship_record.dart';
import 'timeline_record.dart';

class SharedNarrativeAssetContextSectionService {
  const SharedNarrativeAssetContextSectionService({
    ForeshadowStatusCatalogService? foreshadowStatusCatalogService,
  }) : _foreshadowStatusCatalogService =
           foreshadowStatusCatalogService ??
           const ForeshadowStatusCatalogService();

  final ForeshadowStatusCatalogService _foreshadowStatusCatalogService;

  List<JsonMap> buildSections({
    required List<ForeshadowRecord> foreshadows,
    required List<TimelineRecord> timelines,
    required List<RelationshipRecord> relationships,
    List<String> focusPaths = const <String>[],
    int maxItemsPerSection = 4,
  }) {
    // 中文注释: 共享资产片段服务只负责把伏笔/时间线/关系压成上下文块，供普通协作与长任务共同消费。
    final sections = <JsonMap>[];
    final foreshadowLines = _pendingForeshadowLines(
      foreshadows,
      focusPaths: focusPaths,
      maxItems: maxItemsPerSection,
    );
    if (foreshadowLines.isNotEmpty) {
      sections.add(<String, Object?>{
        'id': 'shared_pending_foreshadows',
        'title': '待回收伏笔',
        'priority': 84,
        'content': foreshadowLines.join('\n'),
      });
    }
    final timelineLines = _recentTimelineLines(
      timelines,
      focusPaths: focusPaths,
      maxItems: maxItemsPerSection,
    );
    if (timelineLines.isNotEmpty) {
      sections.add(<String, Object?>{
        'id': 'shared_recent_timeline',
        'title': '最近时间线',
        'priority': 80,
        'content': timelineLines.join('\n'),
      });
    }
    final relationshipLines = _relationshipLines(
      relationships,
      focusPaths: focusPaths,
      maxItems: maxItemsPerSection,
    );
    if (relationshipLines.isNotEmpty) {
      sections.add(<String, Object?>{
        'id': 'shared_key_relationship_changes',
        'title': '关键关系变化',
        'priority': 78,
        'content': relationshipLines.join('\n'),
      });
    }
    return sections;
  }

  List<String> _pendingForeshadowLines(
    List<ForeshadowRecord> records, {
    required List<String> focusPaths,
    required int maxItems,
  }) {
    final items =
        records
            .where(
              (record) =>
                  !_foreshadowStatusCatalogService.isTerminal(record.status),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final leftScore = _foreshadowScore(left, focusPaths);
            final rightScore = _foreshadowScore(right, focusPaths);
            return leftScore.compareTo(rightScore);
          });
    return items
        .take(maxItems)
        .map((record) {
          final parts = <String>[
            '- ${record.title}（${_statusLabel(record.status)}）',
          ];
          if (record.summary.trim().isNotEmpty) {
            parts.add(record.summary.trim());
          }
          if (record.targetPayoffPath.trim().isNotEmpty) {
            parts.add('目标回收：${record.targetPayoffPath.trim()}');
          }
          return parts.join('｜');
        })
        .toList(growable: false);
  }

  List<String> _recentTimelineLines(
    List<TimelineRecord> records, {
    required List<String> focusPaths,
    required int maxItems,
  }) {
    final items = records.toList(growable: false)
      ..sort((left, right) {
        final leftScore = _timelineScore(left, focusPaths);
        final rightScore = _timelineScore(right, focusPaths);
        return leftScore.compareTo(rightScore);
      });
    return items
        .take(maxItems)
        .map((record) {
          final parts = <String>['- ${record.displayName}'];
          if (record.phaseLabel.trim().isNotEmpty) {
            parts.add(record.phaseLabel.trim());
          }
          if (record.summary.trim().isNotEmpty) {
            parts.add(record.summary.trim());
          }
          return parts.join('｜');
        })
        .toList(growable: false);
  }

  List<String> _relationshipLines(
    List<RelationshipRecord> records, {
    required List<String> focusPaths,
    required int maxItems,
  }) {
    final items = records.toList(growable: false)
      ..sort((left, right) {
        final leftScore = _relationshipScore(left, focusPaths);
        final rightScore = _relationshipScore(right, focusPaths);
        return leftScore.compareTo(rightScore);
      });
    return items
        .take(maxItems)
        .map((record) {
          final parts = <String>['- ${record.displayName}'];
          if (record.relationshipType.trim().isNotEmpty) {
            parts.add(record.relationshipType.trim());
          }
          if (record.summary.trim().isNotEmpty) {
            parts.add(record.summary.trim());
          }
          return parts.join('｜');
        })
        .toList(growable: false);
  }

  int _foreshadowScore(ForeshadowRecord record, List<String> focusPaths) {
    final priority = _foreshadowStatusCatalogService.priority(record.status);
    final focusHit = _pathHit(record.relatedPaths, focusPaths) ? -10 : 0;
    return priority * 10 + focusHit;
  }

  int _timelineScore(TimelineRecord record, List<String> focusPaths) {
    final focusHit = _pathHit(record.relatedPaths, focusPaths) ? -10 : 0;
    final sequenceScore = record.sequence > 0 ? -record.sequence : 0;
    return focusHit + sequenceScore;
  }

  int _relationshipScore(RelationshipRecord record, List<String> focusPaths) {
    final focusHit = _pathHit(<String>[record.sourcePath], focusPaths) ? -5 : 0;
    final activeScore =
        ValueReaders.stringValue(record.status).trim() == 'active' ? 0 : -1;
    return focusHit + activeScore;
  }

  bool _pathHit(List<String> recordPaths, List<String> focusPaths) {
    final normalizedFocus = focusPaths
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    for (final recordPath in recordPaths) {
      final cleanRecordPath = recordPath.trim();
      if (cleanRecordPath.isEmpty) {
        continue;
      }
      for (final focusPath in normalizedFocus) {
        if (cleanRecordPath == focusPath) {
          return true;
        }
      }
    }
    return false;
  }

  String _statusLabel(String status) {
    return switch (_foreshadowStatusCatalogService.normalize(status)) {
      ForeshadowStatusCatalogService.planted => '已埋下',
      ForeshadowStatusCatalogService.pendingPayoff => '待回收',
      ForeshadowStatusCatalogService.partialPayoff => '部分回收',
      ForeshadowStatusCatalogService.resolved => '已回收',
      ForeshadowStatusCatalogService.abandoned => '弃用',
      ForeshadowStatusCatalogService.atRisk => '风险中',
      _ => status,
    };
  }
}
