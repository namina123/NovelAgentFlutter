import 'reference_source_batch_models.dart';

class ReferenceSourceBatchProgressService {
  const ReferenceSourceBatchProgressService();

  ReferenceSourceBatchProgress initialize(ReferenceSourceBatchPlan plan) {
    return ReferenceSourceBatchProgress(
      planId: plan.planId,
      totalBatches: plan.batches.length,
      totalSourceChars: plan.batches.fold<int>(
        0,
        (sum, batch) => sum + batch.charCount,
      ),
      items: plan.batches
          .map(
            (batch) => ReferenceSourceBatchProgressItem(
              batchId: batch.batchId,
              status: ReferenceSourceBatchStatuses.pending,
              sectionIds: batch.sectionIds,
              charCount: batch.charCount,
            ),
          )
          .toList(growable: false),
    );
  }

  ReferenceSourceBatchProgress markCompleted({
    required ReferenceSourceBatchProgress progress,
    required ReferenceSourceBatch batch,
    required int proposalCount,
    required String completedAt,
  }) {
    return _replaceItem(
      progress: progress,
      next: ReferenceSourceBatchProgressItem(
        batchId: batch.batchId,
        status: ReferenceSourceBatchStatuses.completed,
        sectionIds: batch.sectionIds,
        charCount: batch.charCount,
        proposalCount: proposalCount,
        completedAt: completedAt,
      ),
    );
  }

  ReferenceSourceBatchProgress markFailed({
    required ReferenceSourceBatchProgress progress,
    required ReferenceSourceBatch batch,
    required String failureReason,
  }) {
    return _replaceItem(
      progress: progress,
      next: ReferenceSourceBatchProgressItem(
        batchId: batch.batchId,
        status: ReferenceSourceBatchStatuses.failed,
        sectionIds: batch.sectionIds,
        charCount: batch.charCount,
        failureReason: failureReason,
      ),
    );
  }

  ReferenceSourceBatchProgress _replaceItem({
    required ReferenceSourceBatchProgress progress,
    required ReferenceSourceBatchProgressItem next,
  }) {
    final items = progress.items
        .map((item) => item.batchId == next.batchId ? next : item)
        .toList(growable: false);
    return ReferenceSourceBatchProgress(
      planId: progress.planId,
      totalBatches: progress.totalBatches,
      totalSourceChars: progress.totalSourceChars,
      items: items,
    );
  }
}
