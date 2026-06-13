import '../reference_substrate/reference_package_models.dart';
import '../reference_substrate/reference_evidence_substrate_state_models.dart';
import '../reference_substrate/reference_query.dart';

abstract class ReferenceEvidenceSubstrate {
  Future<void> upsertPackageSnapshot(ReferencePackageSnapshot snapshot);

  Future<void> upsertBatchExecutionState(
    ReferenceEvidenceBatchExecutionState state,
  );

  Future<void> upsertContinuityLedger(ReferenceEvidenceContinuityLedger ledger);

  Future<ReferencePackageRecord?> readPackage(String packageId);

  Future<ReferencePackageSnapshot?> readPackageSnapshot({
    required String packageId,
    required String packageVersionId,
  });

  Future<ReferenceEvidenceBatchExecutionState?> readBatchExecutionState({
    required String packageId,
    required String packageVersionId,
  });

  Future<ReferenceEvidenceContinuityLedger?> readContinuityLedger({
    required String packageId,
    required String packageVersionId,
  });

  Future<List<ReferencePackageRecord>> listPackages({String? packageKind});

  Future<List<ReferenceEntryRecord>> listEntries({
    String? packageId,
    String? packageVersionId,
    String? entryKind,
  });

  Future<List<ReferenceSourceAssetLinkRecord>> listSourceAssetLinks({
    String? packageId,
    String? packageVersionId,
    String? entryId,
    String? sourceAssetId,
  });

  Future<ReferenceQueryResult> queryEntries(ReferenceQuery query);
}
