import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'reference_ingestion_budget_policy.dart';

abstract final class ReferenceSourceBatchSplitModes {
  static const String sectionAligned = 'section_aligned';
  static const String oversizedSectionSplit = 'oversized_section_split';
  static const String structureFallback = 'structure_fallback';
}

abstract final class ReferenceSourceBatchStatuses {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
}

class ReferenceSourceBatch {
  const ReferenceSourceBatch({
    required this.batchId,
    required this.batchIndex,
    required this.structureMode,
    required this.splitMode,
    required this.sourceText,
    this.sectionIds = const <String>[],
    this.sectionIndexes = const <int>[],
    this.headings = const <String>[],
    this.syntheticSplit = false,
    this.parentSectionIds = const <String>[],
  });

  final String batchId;
  final int batchIndex;
  final String structureMode;
  final String splitMode;
  final String sourceText;
  final List<String> sectionIds;
  final List<int> sectionIndexes;
  final List<String> headings;
  final bool syntheticSplit;
  final List<String> parentSectionIds;

  int get charCount => sourceText.length;

  JsonMap toJson() {
    return <String, Object?>{
      'batch_id': batchId,
      'batch_index': batchIndex,
      'structure_mode': structureMode,
      'split_mode': splitMode,
      'source_text': sourceText,
      'section_ids': ValueReaders.deepCopyList(sectionIds.cast<Object?>()),
      'section_indexes': ValueReaders.deepCopyList(
        sectionIndexes.cast<Object?>(),
      ),
      'headings': ValueReaders.deepCopyList(headings.cast<Object?>()),
      'synthetic_split': syntheticSplit,
      'parent_section_ids': ValueReaders.deepCopyList(
        parentSectionIds.cast<Object?>(),
      ),
    };
  }

  static ReferenceSourceBatch fromJson(JsonMap json) {
    return ReferenceSourceBatch(
      batchId: ValueReaders.stringValue(json['batch_id']).trim(),
      batchIndex: ValueReaders.intValue(json['batch_index']),
      structureMode: ValueReaders.stringValue(json['structure_mode']).trim(),
      splitMode: ValueReaders.stringValue(json['split_mode']).trim(),
      sourceText: ValueReaders.stringValue(json['source_text']),
      sectionIds: ValueReaders.stringList(json['section_ids']),
      sectionIndexes: ValueReaders.objectList(
        json['section_indexes'],
      ).map((entry) => ValueReaders.intValue(entry)).toList(growable: false),
      headings: ValueReaders.stringList(json['headings']),
      syntheticSplit: ValueReaders.boolValue(json['synthetic_split']),
      parentSectionIds: ValueReaders.stringList(json['parent_section_ids']),
    );
  }
}

class ReferenceSourceBatchPlan {
  const ReferenceSourceBatchPlan({
    required this.planId,
    required this.structureMode,
    required this.totalSourceChars,
    required this.totalSectionCount,
    required this.budgetResolution,
    required this.batches,
    this.planningMode = ReferenceSourceBatchPlanningModes.structureFirst,
    this.batchGoalKind = ReferenceBatchGoalKinds.semanticExtraction,
    this.structureFallbackUsed = false,
    this.oversizeSplitApplied = false,
  });

  final String planId;
  final String structureMode;
  final int totalSourceChars;
  final int totalSectionCount;
  final ReferenceIngestionBudgetResolution budgetResolution;
  final List<ReferenceSourceBatch> batches;
  final String planningMode;
  final String batchGoalKind;
  final bool structureFallbackUsed;
  final bool oversizeSplitApplied;

  JsonMap toJson() {
    return <String, Object?>{
      'plan_id': planId,
      'structure_mode': structureMode,
      'total_source_chars': totalSourceChars,
      'total_section_count': totalSectionCount,
      'budget_resolution': budgetResolution.toJson(),
      'planning_mode': planningMode,
      'batch_goal_kind': batchGoalKind,
      'structure_fallback_used': structureFallbackUsed,
      'oversize_split_applied': oversizeSplitApplied,
      'batches': batches.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  static ReferenceSourceBatchPlan fromJson(JsonMap json) {
    return ReferenceSourceBatchPlan(
      planId: ValueReaders.stringValue(json['plan_id']).trim(),
      structureMode: ValueReaders.stringValue(json['structure_mode']).trim(),
      totalSourceChars: ValueReaders.intValue(json['total_source_chars']),
      totalSectionCount: ValueReaders.intValue(json['total_section_count']),
      budgetResolution: ReferenceIngestionBudgetResolution.fromJson(
        ValueReaders.mapValue(json['budget_resolution']),
      ),
      planningMode: ValueReaders.stringValue(
        json['planning_mode'],
        ReferenceSourceBatchPlanningModes.structureFirst,
      ).trim(),
      batchGoalKind: ValueReaders.stringValue(
        json['batch_goal_kind'],
        ReferenceBatchGoalKinds.semanticExtraction,
      ).trim(),
      structureFallbackUsed: ValueReaders.boolValue(
        json['structure_fallback_used'],
      ),
      oversizeSplitApplied: ValueReaders.boolValue(
        json['oversize_split_applied'],
      ),
      batches: ValueReaders.mapList(
        json['batches'],
      ).map(ReferenceSourceBatch.fromJson).toList(growable: false),
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (planId.trim().isEmpty) {
      result.add('missing_reference_source_batch_plan_id');
    }
    if (!ReferenceSourceBatchPlanningModes.knownValues.contains(planningMode)) {
      result.add('invalid_reference_source_batch_plan_mode');
    }
    if (!ReferenceBatchGoalKinds.knownValues.contains(batchGoalKind)) {
      result.add('invalid_reference_source_batch_plan_goal_kind');
    }
    if (batches.isEmpty) {
      result.add('missing_reference_source_batches');
    }
    return result;
  }
}

class ReferenceSourceBatchProgressItem {
  const ReferenceSourceBatchProgressItem({
    required this.batchId,
    required this.status,
    this.sectionIds = const <String>[],
    this.charCount = 0,
    this.proposalCount = 0,
    this.completedAt = '',
    this.failureReason = '',
  });

  final String batchId;
  final String status;
  final List<String> sectionIds;
  final int charCount;
  final int proposalCount;
  final String completedAt;
  final String failureReason;

  JsonMap toJson() {
    return <String, Object?>{
      'batch_id': batchId,
      'status': status,
      'section_ids': ValueReaders.deepCopyList(sectionIds.cast<Object?>()),
      'char_count': charCount,
      'proposal_count': proposalCount,
      'completed_at': completedAt,
      'failure_reason': failureReason,
    };
  }

  static ReferenceSourceBatchProgressItem fromJson(JsonMap json) {
    return ReferenceSourceBatchProgressItem(
      batchId: ValueReaders.stringValue(json['batch_id']).trim(),
      status: ValueReaders.stringValue(json['status']).trim(),
      sectionIds: ValueReaders.stringList(json['section_ids']),
      charCount: ValueReaders.intValue(json['char_count']),
      proposalCount: ValueReaders.intValue(json['proposal_count']),
      completedAt: ValueReaders.stringValue(json['completed_at']).trim(),
      failureReason: ValueReaders.stringValue(json['failure_reason']).trim(),
    );
  }
}

class ReferenceSourceBatchProgress {
  const ReferenceSourceBatchProgress({
    required this.planId,
    required this.totalBatches,
    required this.totalSourceChars,
    required this.items,
  });

  final String planId;
  final int totalBatches;
  final int totalSourceChars;
  final List<ReferenceSourceBatchProgressItem> items;

  int get completedBatchCount => items
      .where((entry) => entry.status == ReferenceSourceBatchStatuses.completed)
      .length;

  int get failedBatchCount => items
      .where((entry) => entry.status == ReferenceSourceBatchStatuses.failed)
      .length;

  int get pendingBatchCount => items
      .where((entry) => entry.status == ReferenceSourceBatchStatuses.pending)
      .length;

  int get completedSourceChars => items
      .where((entry) => entry.status == ReferenceSourceBatchStatuses.completed)
      .fold<int>(0, (sum, entry) => sum + entry.charCount);

  double get coverageRatio {
    if (totalSourceChars <= 0) {
      return 0;
    }
    return completedSourceChars / totalSourceChars;
  }

  bool get consolidationReady =>
      totalBatches > 0 && pendingBatchCount == 0 && failedBatchCount == 0;

  JsonMap toJson() {
    return <String, Object?>{
      'plan_id': planId,
      'total_batches': totalBatches,
      'total_source_chars': totalSourceChars,
      'completed_batch_count': completedBatchCount,
      'failed_batch_count': failedBatchCount,
      'pending_batch_count': pendingBatchCount,
      'completed_source_chars': completedSourceChars,
      'coverage_ratio': coverageRatio,
      'consolidation_ready': consolidationReady,
      'items': items.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  static ReferenceSourceBatchProgress fromJson(JsonMap json) {
    return ReferenceSourceBatchProgress(
      planId: ValueReaders.stringValue(json['plan_id']).trim(),
      totalBatches: ValueReaders.intValue(json['total_batches']),
      totalSourceChars: ValueReaders.intValue(json['total_source_chars']),
      items: ValueReaders.mapList(
        json['items'],
      ).map(ReferenceSourceBatchProgressItem.fromJson).toList(growable: false),
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (planId.trim().isEmpty) {
      result.add('missing_reference_source_batch_progress_plan_id');
    }
    if (totalBatches < 0 || totalSourceChars < 0) {
      result.add('invalid_reference_source_batch_progress_totals');
    }
    return result;
  }
}
