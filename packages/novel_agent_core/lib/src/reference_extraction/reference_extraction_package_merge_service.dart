import '../agents/agent_task_family.dart';
import '../information/information_activation_policy.dart';
import '../information/information_policy_constants.dart';
import '../information/information_usage_policy.dart';
import '../output/output_contract_models.dart';
import '../reference_substrate/reference_package_models.dart';
import 'reference_extraction_proposal_models.dart';
import 'reference_extraction_review_models.dart';

class ReferenceExtractionPackageMergeService {
  const ReferenceExtractionPackageMergeService();

  ReferencePackageSnapshot merge({
    required ReferencePackageSnapshot seedSnapshot,
    required List<ReferenceExtractionProposal> proposals,
    required ReferenceExtractionReviewOutcome reviewOutcome,
    required String finalizedAt,
    String finalizedBy = '',
    String finalizedPackageVersionId = '',
    String finalizedVersionLabel = '',
  }) {
    if (reviewOutcome.outputCompletionStatus !=
        OutputCompletionStatuses.completed) {
      throw StateError(
        'reference extraction merge requires completed output status; got ${reviewOutcome.outputCompletionStatus}.',
      );
    }
    final acceptedIds = reviewOutcome.acceptedProposalIds.toSet();
    final resolvedVersionId = finalizedPackageVersionId.trim().isNotEmpty
        ? finalizedPackageVersionId.trim()
        : '${seedSnapshot.packageVersionRecord.packageVersionId}_finalized';
    final resolvedVersionLabel = finalizedVersionLabel.trim().isNotEmpty
        ? finalizedVersionLabel.trim()
        : '${seedSnapshot.packageVersionRecord.versionLabel} curated';
    final mergedEntries = <String, ReferenceEntryRecord>{};
    for (final entry in seedSnapshot.entries) {
      mergedEntries[entry.entryId] = _copySeedEntry(
        entry,
        packageVersionId: resolvedVersionId,
      );
    }
    for (final proposal in proposals) {
      if (!acceptedIds.contains(proposal.proposalId)) {
        continue;
      }
      mergedEntries[proposal.entryId] = _proposalToEntry(
        proposal,
        packageId: seedSnapshot.packageRecord.packageId,
        packageVersionId: resolvedVersionId,
      );
    }
    final targetLanguage = seedSnapshot.packageRecord.targetLanguage.trim();
    final acceptedCount = acceptedIds.length;
    const outputCompletionStatus = OutputCompletionStatuses.completed;
    final compressionRiskLevel = reviewOutcome.outputCompressionRisk.level;
    final uncoveredDimensionIds =
        reviewOutcome.coverageLedger?.uncoveredDimensionIds ?? const <String>[];
    final description = targetLanguage.startsWith('zh')
        ? '在 seed extraction 基础上完成 agent-driven extraction 与审核后定稿，共纳入 $acceptedCount 条语义提取条目。'
        : 'Finalized after agent-driven extraction and review with $acceptedCount accepted semantic entries.';
    return ReferencePackageSnapshot(
      packageRecord: ReferencePackageRecord(
        packageId: seedSnapshot.packageRecord.packageId,
        packageKind: seedSnapshot.packageRecord.packageKind,
        displayName: seedSnapshot.packageRecord.displayName,
        packageNamespace: seedSnapshot.packageRecord.packageNamespace,
        sourceLanguage: seedSnapshot.packageRecord.sourceLanguage,
        targetLanguage: seedSnapshot.packageRecord.targetLanguage,
        description: description,
        latestVersionId: resolvedVersionId,
        lifecycleStatus: seedSnapshot.packageRecord.lifecycleStatus,
        sourceSummary: seedSnapshot.packageRecord.sourceSummary,
        licenseSummary: seedSnapshot.packageRecord.licenseSummary,
        createdAt: seedSnapshot.packageRecord.createdAt,
        updatedAt: finalizedAt,
        metadata: <String, Object?>{
          ...seedSnapshot.packageRecord.metadata,
          'task_family_id': AgentTaskFamilies.referenceExtraction,
          'seed_package_version_id':
              seedSnapshot.packageVersionRecord.packageVersionId,
          'output_completion_status': outputCompletionStatus,
          'output_compression_risk_level': compressionRiskLevel,
          'output_uncovered_dimension_ids': uncoveredDimensionIds,
        },
      ),
      packageVersionRecord: ReferencePackageVersionRecord(
        packageVersionId: resolvedVersionId,
        packageId: seedSnapshot.packageRecord.packageId,
        versionLabel: resolvedVersionLabel,
        createdAt: finalizedAt,
        createdBy: finalizedBy,
        sourceSummary: seedSnapshot.packageVersionRecord.sourceSummary,
        licenseSummary: seedSnapshot.packageVersionRecord.licenseSummary,
        dependencySummary: seedSnapshot.packageVersionRecord.dependencySummary,
        integrityHash: seedSnapshot.packageVersionRecord.integrityHash,
        metadata: <String, Object?>{
          ...seedSnapshot.packageVersionRecord.metadata,
          'task_family_id': AgentTaskFamilies.referenceExtraction,
          'accepted_proposal_count': acceptedCount,
          'output_completion_status': outputCompletionStatus,
          'output_compression_risk_level': compressionRiskLevel,
          'continuation_request_count':
              reviewOutcome.continuationRequests.length,
          'omission_report_count': reviewOutcome.omissionReports.length,
        },
      ),
      entries: mergedEntries.values.toList(growable: false),
      dependencies: seedSnapshot.dependencies,
      promotionRecords: seedSnapshot.promotionRecords,
    );
  }

  ReferenceEntryRecord _copySeedEntry(
    ReferenceEntryRecord entry, {
    required String packageVersionId,
  }) {
    return ReferenceEntryRecord(
      entryId: entry.entryId,
      packageId: entry.packageId,
      packageVersionId: packageVersionId,
      entryNamespace: entry.entryNamespace,
      entryKind: entry.entryKind,
      title: entry.title,
      summary: entry.summary,
      payload: entry.payload,
      sourceRefs: entry.sourceRefs,
      evidenceRefs: entry.evidenceRefs,
      tags: entry.tags,
      attachments: entry.attachments,
      activationPolicy: entry.activationPolicy,
      usagePolicy: entry.usagePolicy,
      confidence: entry.confidence,
      lifecycleStatus: entry.lifecycleStatus,
      metadata: entry.metadata,
    );
  }

  ReferenceEntryRecord _proposalToEntry(
    ReferenceExtractionProposal proposal, {
    required String packageId,
    required String packageVersionId,
  }) {
    return ReferenceEntryRecord(
      entryId: proposal.entryId,
      packageId: packageId,
      packageVersionId: packageVersionId,
      entryNamespace: proposal.entryNamespace,
      entryKind: proposal.entryKind,
      title: proposal.title,
      summary: proposal.summary,
      payload: proposal.payload,
      sourceRefs: proposal.sourceRefs,
      evidenceRefs: proposal.evidenceRefs,
      tags: proposal.tags,
      activationPolicy: const InformationActivationPolicy(
        activationPriority: InformationActivationPriorities.reference,
        preferredBudgetChars: 260,
      ),
      usagePolicy: const InformationUsagePolicy(
        usageMode: InformationUsageModes.referenceOnly,
        citationRiskLevel: InformationCitationRiskLevels.normal,
        requiresConfirmation: true,
        allowsDerivativeUse: true,
        allowsDirectQuote: false,
      ),
      confidence: proposal.confidence,
      lifecycleStatus: 'active',
      metadata: <String, Object?>{
        ...proposal.metadata,
        'accepted_from_reference_extraction_proposal': true,
      },
    );
  }
}
