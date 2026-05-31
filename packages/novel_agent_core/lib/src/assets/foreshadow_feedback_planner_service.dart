import 'foreshadow_feedback_signal.dart';
import 'foreshadow_record.dart';
import 'foreshadow_status_catalog_service.dart';

class ForeshadowFeedbackPlannerService {
  const ForeshadowFeedbackPlannerService({
    ForeshadowStatusCatalogService? statusCatalogService,
  }) : _statusCatalogService =
           statusCatalogService ?? const ForeshadowStatusCatalogService();

  final ForeshadowStatusCatalogService _statusCatalogService;

  ForeshadowRecord applySignals(
    ForeshadowRecord record,
    List<ForeshadowFeedbackSignal> signals,
  ) {
    // 中文注释: 反馈规划器只负责把 review/analysis 信号折算为新的伏笔状态和补充关联。
    if (signals.isEmpty) {
      return record;
    }
    var status = record.status;
    final notes = <String>[record.notes.trim()];
    final relatedTimelineIds = <String>[...record.relatedTimelineIds];
    final relatedRelationshipIds = <String>[...record.relatedRelationshipIds];
    final relatedPaths = <String>[...record.relatedPaths];
    for (final signal in signals) {
      status = _preferStatus(status, signal.statusHint);
      if (signal.note.trim().isNotEmpty) {
        notes.add(signal.note.trim());
      }
      for (final id in signal.relatedTimelineIds) {
        if (id.trim().isNotEmpty && !relatedTimelineIds.contains(id.trim())) {
          relatedTimelineIds.add(id.trim());
        }
      }
      for (final id in signal.relatedRelationshipIds) {
        if (id.trim().isNotEmpty &&
            !relatedRelationshipIds.contains(id.trim())) {
          relatedRelationshipIds.add(id.trim());
        }
      }
      for (final path in signal.relatedPaths) {
        if (path.trim().isNotEmpty && !relatedPaths.contains(path.trim())) {
          relatedPaths.add(path.trim());
        }
      }
    }
    return ForeshadowRecord(
      id: record.id,
      title: record.title,
      status: _statusCatalogService.normalize(status),
      summary: record.summary,
      plantedChapterPath: record.plantedChapterPath,
      targetPayoffPath: record.targetPayoffPath,
      relatedEntityIds: record.relatedEntityIds,
      relatedTimelineIds: relatedTimelineIds,
      relatedRelationshipIds: relatedRelationshipIds,
      relatedPaths: relatedPaths,
      triggerConditions: record.triggerConditions,
      payoffExpectations: record.payoffExpectations,
      tags: record.tags,
      notes: notes.where((item) => item.isNotEmpty).join('\n\n').trim(),
      sourcePath: record.sourcePath,
      metadata: record.metadata,
    );
  }

  String _preferStatus(String current, String candidate) {
    final normalizedCurrent = _statusCatalogService.normalize(current);
    final normalizedCandidate = _statusCatalogService.normalize(candidate);
    if (normalizedCurrent == normalizedCandidate) {
      return normalizedCurrent;
    }
    if (_isTerminal(normalizedCandidate)) {
      return normalizedCandidate;
    }
    if (_isTerminal(normalizedCurrent)) {
      return normalizedCurrent;
    }
    if (normalizedCurrent == ForeshadowStatusCatalogService.atRisk) {
      return normalizedCandidate == ForeshadowStatusCatalogService.atRisk
          ? normalizedCurrent
          : normalizedCurrent;
    }
    if (normalizedCandidate == ForeshadowStatusCatalogService.atRisk) {
      return normalizedCandidate;
    }
    return _progressionRank(normalizedCandidate) >
            _progressionRank(normalizedCurrent)
        ? normalizedCandidate
        : normalizedCurrent;
  }

  bool _isTerminal(String status) {
    return status == ForeshadowStatusCatalogService.resolved ||
        status == ForeshadowStatusCatalogService.abandoned;
  }

  int _progressionRank(String status) {
    return switch (status) {
      ForeshadowStatusCatalogService.planted => 0,
      ForeshadowStatusCatalogService.pendingPayoff => 1,
      ForeshadowStatusCatalogService.partialPayoff => 2,
      ForeshadowStatusCatalogService.resolved => 3,
      ForeshadowStatusCatalogService.abandoned => 3,
      ForeshadowStatusCatalogService.atRisk => -1,
      _ => -1,
    };
  }
}
