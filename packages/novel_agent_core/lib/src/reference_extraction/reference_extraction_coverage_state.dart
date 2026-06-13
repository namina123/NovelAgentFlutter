import '../common/json_types.dart';
import '../common/value_readers.dart';

class ReferenceExtractionCoveredRange {
  const ReferenceExtractionCoveredRange({
    required this.startSectionIndex,
    required this.endSectionIndex,
    this.sectionIds = const <String>[],
  });

  final int startSectionIndex;
  final int endSectionIndex;
  final List<String> sectionIds;

  JsonMap toJson() {
    return <String, Object?>{
      'start_section_index': startSectionIndex,
      'end_section_index': endSectionIndex,
      'section_ids': ValueReaders.deepCopyList(sectionIds.cast<Object?>()),
    };
  }

  static ReferenceExtractionCoveredRange fromJson(JsonMap json) {
    return ReferenceExtractionCoveredRange(
      startSectionIndex: ValueReaders.intValue(json['start_section_index']),
      endSectionIndex: ValueReaders.intValue(json['end_section_index']),
      sectionIds: ValueReaders.stringList(json['section_ids']),
    );
  }
}

class ReferenceExtractionCoverageState {
  const ReferenceExtractionCoverageState({
    required this.planId,
    required this.totalSegmentCount,
    required this.completedSegmentCount,
    required this.failedSegmentCount,
    required this.pendingSegmentCount,
    this.coveredSectionRanges = const <ReferenceExtractionCoveredRange>[],
    this.requiresFollowupSegmentIds = const <String>[],
    this.coveredDimensionIds = const <String>[],
    this.uncoveredDimensionIds = const <String>[],
    this.consolidationReady = false,
    this.metadata = const <String, Object?>{},
  });

  final String planId;
  final int totalSegmentCount;
  final int completedSegmentCount;
  final int failedSegmentCount;
  final int pendingSegmentCount;
  final List<ReferenceExtractionCoveredRange> coveredSectionRanges;
  final List<String> requiresFollowupSegmentIds;
  final List<String> coveredDimensionIds;
  final List<String> uncoveredDimensionIds;
  final bool consolidationReady;
  final JsonMap metadata;

  bool get requiresFollowup =>
      requiresFollowupSegmentIds.isNotEmpty || uncoveredDimensionIds.isNotEmpty;

  JsonMap toJson() {
    return <String, Object?>{
      'plan_id': planId,
      'total_segment_count': totalSegmentCount,
      'completed_segment_count': completedSegmentCount,
      'failed_segment_count': failedSegmentCount,
      'pending_segment_count': pendingSegmentCount,
      'covered_section_ranges': coveredSectionRanges
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'requires_followup_segment_ids': ValueReaders.deepCopyList(
        requiresFollowupSegmentIds.cast<Object?>(),
      ),
      'covered_dimension_ids': ValueReaders.deepCopyList(
        coveredDimensionIds.cast<Object?>(),
      ),
      'uncovered_dimension_ids': ValueReaders.deepCopyList(
        uncoveredDimensionIds.cast<Object?>(),
      ),
      'consolidation_ready': consolidationReady,
      'requires_followup': requiresFollowup,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ReferenceExtractionCoverageState fromJson(JsonMap json) {
    return ReferenceExtractionCoverageState(
      planId: ValueReaders.stringValue(json['plan_id']).trim(),
      totalSegmentCount: ValueReaders.intValue(json['total_segment_count']),
      completedSegmentCount: ValueReaders.intValue(
        json['completed_segment_count'],
      ),
      failedSegmentCount: ValueReaders.intValue(json['failed_segment_count']),
      pendingSegmentCount: ValueReaders.intValue(json['pending_segment_count']),
      coveredSectionRanges: ValueReaders.mapList(
        json['covered_section_ranges'],
      ).map(ReferenceExtractionCoveredRange.fromJson).toList(growable: false),
      requiresFollowupSegmentIds: ValueReaders.stringList(
        json['requires_followup_segment_ids'],
      ),
      coveredDimensionIds: ValueReaders.stringList(
        json['covered_dimension_ids'],
      ),
      uncoveredDimensionIds: ValueReaders.stringList(
        json['uncovered_dimension_ids'],
      ),
      consolidationReady: ValueReaders.boolValue(json['consolidation_ready']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (planId.trim().isEmpty) {
      result.add('missing_reference_extraction_coverage_state_plan_id');
    }
    if (totalSegmentCount < 0 ||
        completedSegmentCount < 0 ||
        failedSegmentCount < 0 ||
        pendingSegmentCount < 0) {
      result.add('invalid_reference_extraction_coverage_state_counts');
    }
    if (completedSegmentCount + failedSegmentCount + pendingSegmentCount >
        totalSegmentCount) {
      result.add('reference_extraction_coverage_state_counts_exceed_total');
    }
    return result;
  }
}
