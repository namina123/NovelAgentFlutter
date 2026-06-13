import '../common/json_types.dart';
import '../common/source_asset_identity.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/continuity_review_alert.dart';
import '../continuity/narrative_state/narrative_conflict_cluster.dart';
import '../continuity/narrative_state/project_canon_decision.dart';
import '../output/output_contract_models.dart';
import '../reference_extraction/reference_extraction_coverage_state.dart';
import '../reference_extraction/reference_source_batch_models.dart';

class ReferenceEvidenceBatchExecutionState {
  const ReferenceEvidenceBatchExecutionState({
    required this.packageId,
    required this.packageVersionId,
    required this.batchPlan,
    required this.batchProgress,
    this.coverageState,
    this.coverageLedger,
    this.updatedAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String packageId;
  final String packageVersionId;
  final ReferenceSourceBatchPlan batchPlan;
  final ReferenceSourceBatchProgress batchProgress;
  final ReferenceExtractionCoverageState? coverageState;
  final OutputCoverageLedger? coverageLedger;
  final String updatedAt;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'package_id': packageId,
      'package_version_id': packageVersionId,
      'batch_plan': batchPlan.toJson(),
      'batch_progress': batchProgress.toJson(),
      'coverage_state': coverageState?.toJson(),
      'coverage_ledger': coverageLedger?.toJson(),
      'updated_at': updatedAt,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ReferenceEvidenceBatchExecutionState fromJson(JsonMap json) {
    return ReferenceEvidenceBatchExecutionState(
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      packageVersionId: ValueReaders.stringValue(
        json['package_version_id'],
      ).trim(),
      batchPlan: ReferenceSourceBatchPlan.fromJson(
        ValueReaders.mapValue(json['batch_plan']),
      ),
      batchProgress: ReferenceSourceBatchProgress.fromJson(
        ValueReaders.mapValue(json['batch_progress']),
      ),
      coverageState: ValueReaders.mapValue(json['coverage_state']).isEmpty
          ? null
          : ReferenceExtractionCoverageState.fromJson(
              ValueReaders.mapValue(json['coverage_state']),
            ),
      coverageLedger: ValueReaders.mapValue(json['coverage_ledger']).isEmpty
          ? null
          : OutputCoverageLedger.fromJson(
              ValueReaders.mapValue(json['coverage_ledger']),
            ),
      updatedAt: ValueReaders.stringValue(json['updated_at']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (packageId.trim().isEmpty) {
      result.add('missing_reference_evidence_batch_state_package_id');
    }
    if (packageVersionId.trim().isEmpty) {
      result.add('missing_reference_evidence_batch_state_package_version_id');
    }
    result.addAll(batchPlan.validateBasics());
    result.addAll(batchProgress.validateBasics());
    if (coverageState != null) {
      result.addAll(coverageState!.validateBasics());
    }
    return result;
  }
}

class ReferenceEvidenceContinuityLedger {
  const ReferenceEvidenceContinuityLedger({
    required this.packageId,
    required this.packageVersionId,
    this.conflictClusters = const <NarrativeConflictCluster>[],
    this.canonDecisions = const <ProjectCanonDecision>[],
    this.reviewAlerts = const <ContinuityReviewAlert>[],
    this.updatedAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String packageId;
  final String packageVersionId;
  final List<NarrativeConflictCluster> conflictClusters;
  final List<ProjectCanonDecision> canonDecisions;
  final List<ContinuityReviewAlert> reviewAlerts;
  final String updatedAt;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'package_id': packageId,
      'package_version_id': packageVersionId,
      'conflict_clusters': conflictClusters
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'canon_decisions': canonDecisions
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'review_alerts': reviewAlerts
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'updated_at': updatedAt,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ReferenceEvidenceContinuityLedger fromJson(JsonMap json) {
    return ReferenceEvidenceContinuityLedger(
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      packageVersionId: ValueReaders.stringValue(
        json['package_version_id'],
      ).trim(),
      conflictClusters: ValueReaders.mapList(
        json['conflict_clusters'],
      ).map(NarrativeConflictCluster.fromJson).toList(growable: false),
      canonDecisions: ValueReaders.mapList(
        json['canon_decisions'],
      ).map(ProjectCanonDecision.fromJson).toList(growable: false),
      reviewAlerts: ValueReaders.mapList(
        json['review_alerts'],
      ).map(ContinuityReviewAlert.fromJson).toList(growable: false),
      updatedAt: ValueReaders.stringValue(json['updated_at']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (packageId.trim().isEmpty) {
      result.add('missing_reference_evidence_continuity_package_id');
    }
    if (packageVersionId.trim().isEmpty) {
      result.add('missing_reference_evidence_continuity_package_version_id');
    }
    result.addAll(
      conflictClusters.expand((cluster) => cluster.validateBasics()),
    );
    result.addAll(
      canonDecisions.expand((decision) => decision.validateBasics()),
    );
    result.addAll(reviewAlerts.expand((alert) => alert.validateBasics()));
    return result;
  }
}

class ReferenceSourceAssetLinkRecord {
  const ReferenceSourceAssetLinkRecord({
    required this.sourceAsset,
    required this.packageId,
    required this.packageVersionId,
    this.entryId = '',
    this.relationRole = '',
    this.metadata = const <String, Object?>{},
  });

  final SourceAssetIdentity sourceAsset;
  final String packageId;
  final String packageVersionId;
  final String entryId;
  final String relationRole;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'source_asset': sourceAsset.toJson(),
      'package_id': packageId,
      'package_version_id': packageVersionId,
      'entry_id': entryId,
      'relation_role': relationRole,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ReferenceSourceAssetLinkRecord fromJson(JsonMap json) {
    return ReferenceSourceAssetLinkRecord(
      sourceAsset: SourceAssetIdentity.fromJson(
        ValueReaders.mapValue(json['source_asset']),
      ),
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      packageVersionId: ValueReaders.stringValue(
        json['package_version_id'],
      ).trim(),
      entryId: ValueReaders.stringValue(json['entry_id']).trim(),
      relationRole: ValueReaders.stringValue(json['relation_role']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}
