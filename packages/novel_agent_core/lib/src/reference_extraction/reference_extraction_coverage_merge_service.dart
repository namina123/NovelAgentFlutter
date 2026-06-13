import '../output/output_contract_models.dart';
import 'reference_extraction_coverage_state.dart';
import 'reference_extraction_proposal_models.dart';
import 'reference_source_batch_models.dart';

class ReferenceExtractionCoverageMergeService {
  const ReferenceExtractionCoverageMergeService();

  ReferenceExtractionCoverageState merge({
    required ReferenceSourceBatchPlan batchPlan,
    required ReferenceSourceBatchProgress batchProgress,
    List<ReferenceExtractionProposal> proposals =
        const <ReferenceExtractionProposal>[],
    OutputCoverageLedger? coverageLedger,
    List<OmissionReport> omissionReports = const <OmissionReport>[],
    List<ContinuationRequest> continuationRequests =
        const <ContinuationRequest>[],
  }) {
    final segmentStatuses = <String, _SegmentCoverageStatus>{};
    final segmentIndexes = <String, int>{};
    final progressByBatchId = <String, ReferenceSourceBatchProgressItem>{
      for (final item in batchProgress.items) item.batchId: item,
    };

    for (final batch in batchPlan.batches) {
      final item = progressByBatchId[batch.batchId];
      final status = item?.status ?? ReferenceSourceBatchStatuses.pending;
      final sourceSegmentIds = batch.parentSectionIds.isNotEmpty
          ? batch.parentSectionIds
          : batch.sectionIds;
      final sourceSegmentIndexes = batch.parentSectionIds.isNotEmpty
          ? batch.sectionIndexes.take(batch.parentSectionIds.length).toList()
          : batch.sectionIndexes;
      for (var index = 0; index < sourceSegmentIds.length; index += 1) {
        final sourceSegmentId = sourceSegmentIds[index];
        final sourceSegmentIndex = sourceSegmentIndexes.isEmpty
            ? 0
            : sourceSegmentIndexes[index.clamp(
                0,
                sourceSegmentIndexes.length - 1,
              )];
        segmentIndexes.putIfAbsent(sourceSegmentId, () => sourceSegmentIndex);
        segmentStatuses.update(
          sourceSegmentId,
          (existing) => existing.merge(status),
          ifAbsent: () => _SegmentCoverageStatus.fromBatchStatus(status),
        );
      }
    }

    final completedSegments = segmentStatuses.entries
        .where((entry) => entry.value == _SegmentCoverageStatus.completed)
        .map((entry) => entry.key)
        .toList(growable: false);
    final failedSegments = segmentStatuses.entries
        .where((entry) => entry.value == _SegmentCoverageStatus.failed)
        .map((entry) => entry.key)
        .toList(growable: false);
    final pendingSegments = segmentStatuses.entries
        .where((entry) => entry.value == _SegmentCoverageStatus.pending)
        .map((entry) => entry.key)
        .toList(growable: false);

    final coveredDimensionIds = <String>{
      for (final proposal in proposals) ...proposal.coverageDimensionIds,
    };
    final uncoveredDimensionIds = <String>{
      ...?coverageLedger?.uncoveredDimensionIds,
      for (final report in omissionReports) ...report.omittedDimensionIds,
      for (final request in continuationRequests)
        ...request.missingDimensionIds,
    };

    final coveredRanges = _condenseRanges(
      segmentIds: completedSegments,
      segmentIndexes: segmentIndexes,
    );
    final consolidationReady =
        pendingSegments.isEmpty &&
        failedSegments.isEmpty &&
        uncoveredDimensionIds.isEmpty;

    return ReferenceExtractionCoverageState(
      planId: batchPlan.planId,
      totalSegmentCount: segmentStatuses.length,
      completedSegmentCount: completedSegments.length,
      failedSegmentCount: failedSegments.length,
      pendingSegmentCount: pendingSegments.length,
      coveredSectionRanges: coveredRanges,
      requiresFollowupSegmentIds: <String>[
        ...failedSegments,
        ...pendingSegments,
      ],
      coveredDimensionIds: coveredDimensionIds.toList(growable: false),
      uncoveredDimensionIds: uncoveredDimensionIds.toList(growable: false),
      consolidationReady: consolidationReady,
      metadata: <String, Object?>{
        'completed_batch_count': batchProgress.completedBatchCount,
        'failed_batch_count': batchProgress.failedBatchCount,
        'pending_batch_count': batchProgress.pendingBatchCount,
        'coverage_ratio': batchProgress.coverageRatio,
      },
    );
  }

  List<ReferenceExtractionCoveredRange> _condenseRanges({
    required List<String> segmentIds,
    required Map<String, int> segmentIndexes,
  }) {
    final indexedSegments =
        segmentIds
            .map((id) => (id: id, index: segmentIndexes[id] ?? 0))
            .where((entry) => entry.index > 0)
            .toList(growable: false)
          ..sort((left, right) => left.index.compareTo(right.index));
    if (indexedSegments.isEmpty) {
      return const <ReferenceExtractionCoveredRange>[];
    }
    final ranges = <ReferenceExtractionCoveredRange>[];
    var startIndex = indexedSegments.first.index;
    var endIndex = indexedSegments.first.index;
    final sectionIds = <String>[indexedSegments.first.id];
    for (var i = 1; i < indexedSegments.length; i += 1) {
      final current = indexedSegments[i];
      if (current.index == endIndex + 1) {
        endIndex = current.index;
        sectionIds.add(current.id);
        continue;
      }
      ranges.add(
        ReferenceExtractionCoveredRange(
          startSectionIndex: startIndex,
          endSectionIndex: endIndex,
          sectionIds: List<String>.from(sectionIds),
        ),
      );
      sectionIds
        ..clear()
        ..add(current.id);
      startIndex = current.index;
      endIndex = current.index;
    }
    ranges.add(
      ReferenceExtractionCoveredRange(
        startSectionIndex: startIndex,
        endSectionIndex: endIndex,
        sectionIds: List<String>.from(sectionIds),
      ),
    );
    return ranges;
  }
}

enum _SegmentCoverageStatus {
  pending,
  completed,
  failed;

  static _SegmentCoverageStatus fromBatchStatus(String status) {
    switch (status) {
      case ReferenceSourceBatchStatuses.completed:
        return _SegmentCoverageStatus.completed;
      case ReferenceSourceBatchStatuses.failed:
        return _SegmentCoverageStatus.failed;
      default:
        return _SegmentCoverageStatus.pending;
    }
  }

  _SegmentCoverageStatus merge(String batchStatus) {
    final next = fromBatchStatus(batchStatus);
    if (this == _SegmentCoverageStatus.failed ||
        next == _SegmentCoverageStatus.failed) {
      return _SegmentCoverageStatus.failed;
    }
    if (this == _SegmentCoverageStatus.pending ||
        next == _SegmentCoverageStatus.pending) {
      return _SegmentCoverageStatus.pending;
    }
    return _SegmentCoverageStatus.completed;
  }
}
