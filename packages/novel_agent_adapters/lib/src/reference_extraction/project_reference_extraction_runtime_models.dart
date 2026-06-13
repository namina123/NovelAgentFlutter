import 'package:novel_agent_core/novel_agent_core.dart';

abstract final class ProjectReferenceMountStatuses {
  static const String notRequested = 'not_requested';
  static const String snapshotUnavailable = 'snapshot_unavailable';
  static const String attachedOnly = 'attached_only';
  static const String applied = ReferenceProjectionStatuses.applied;
  static const String denied = ReferenceProjectionStatuses.denied;
  static const String missingAttachment =
      ReferenceProjectionStatuses.missingAttachment;
  static const String missingPackage =
      ReferenceProjectionStatuses.missingPackage;
}

class ProjectReferenceExtractionRequest {
  const ProjectReferenceExtractionRequest({
    required this.sourceFilePath,
    this.packageId = '',
    this.packageKind = 'reference_work_package',
    this.displayName = '',
    this.packageVersionId = '',
    this.versionLabel = '',
    this.packageNamespace = '',
    this.createdBy = '',
    this.sourceLanguage = '',
    this.targetLanguage = 'zh-CN',
    this.maxChapterEntries = 6,
    this.maxEntityEntries = 6,
    this.exportBundle = true,
    this.attachToProject = true,
    this.projectMountedEntries = true,
    this.explicitProjectionConfirmationGranted = true,
    this.bundleOutputDirectory = '',
    this.runId = '',
    this.strategyProfileId = '',
    this.availableContextChars = 0,
    this.additionalStrategyProfiles =
        const <ReferenceExtractionStrategyProfile>[],
  });

  final String sourceFilePath;
  final String packageId;
  final String packageKind;
  final String displayName;
  final String packageVersionId;
  final String versionLabel;
  final String packageNamespace;
  final String createdBy;
  final String sourceLanguage;
  final String targetLanguage;
  final int maxChapterEntries;
  final int maxEntityEntries;
  final bool exportBundle;
  final bool attachToProject;
  final bool projectMountedEntries;
  final bool explicitProjectionConfirmationGranted;
  final String bundleOutputDirectory;
  final String runId;
  final String strategyProfileId;
  final int availableContextChars;
  final List<ReferenceExtractionStrategyProfile> additionalStrategyProfiles;
}

class ProjectReferenceExtractionResult {
  const ProjectReferenceExtractionResult({
    required this.runId,
    required this.packageId,
    required this.packageVersionId,
    required this.sourceFilePath,
    required this.sourceDecodeMode,
    required this.groupResolutionKind,
    required this.selectedGroupId,
    required this.strategyProfileId,
    required this.executionConcurrencyMode,
    this.executionMaxConcurrentBatches = 1,
    this.allowParallelHeavyTextConsumption = false,
    required this.proposalCount,
    required this.acceptedProposalCount,
    required this.finalizedEntryCount,
    this.batchCount = 0,
    this.batchCoverageRatio = 0,
    this.batchPlanningMode = ReferenceSourceBatchPlanningModes.structureFirst,
    this.batchGoalKind = ReferenceBatchGoalKinds.semanticExtraction,
    this.batchStructureMode = '',
    this.batchTargetSourceChars = 0,
    this.batchMaxSourceChars = 0,
    this.availableContextChars = 0,
    this.completedBatchCount = 0,
    this.failedBatchCount = 0,
    this.pendingBatchCount = 0,
    this.runStatus = ReferenceExtractionRunStatuses.active,
    this.continuationRoundCount = 0,
    this.deliveryStatus = ReferenceExtractionDeliveryStatuses.publishable,
    this.deliveryRationale = '',
    this.outputCompletionStatus = OutputCompletionStatuses.completed,
    this.outputCompressionRiskLevel = OutputCompressionRiskLevels.none,
    this.needsContinuation = false,
    this.omissionReportCount = 0,
    this.continuationRequestCount = 0,
    this.uncoveredCoverageDimensionIds = const <String>[],
    this.coveredCoverageDimensionIds = const <String>[],
    this.followupSegmentIds = const <String>[],
    this.coverageRequiresFollowup = false,
    this.conflictClusterCount = 0,
    this.canonDecisionCount = 0,
    this.reviewAlertCount = 0,
    this.requiresManualContinuityReview = false,
    this.unresolvedConflictCount = 0,
    this.publishedSnapshotAvailable = true,
    this.attachToProjectRequested = false,
    this.projectMountedEntriesRequested = false,
    this.projectMountStatus = ProjectReferenceMountStatuses.notRequested,
    this.projectMountWarningCodes = const <String>[],
    this.bundleOutputDirectory = '',
    this.stagingRunPath = '',
    this.knowledgeCardIds = const <String>[],
    this.designElementIds = const <String>[],
    this.researchNoteIds = const <String>[],
    this.referenceWorkIds = const <String>[],
    this.generatedProjectionPaths = const <String>[],
  });

  final String runId;
  final String packageId;
  final String packageVersionId;
  final String sourceFilePath;
  final String sourceDecodeMode;
  final String groupResolutionKind;
  final String selectedGroupId;
  final String strategyProfileId;
  final String executionConcurrencyMode;
  final int executionMaxConcurrentBatches;
  final bool allowParallelHeavyTextConsumption;
  final int proposalCount;
  final int acceptedProposalCount;
  final int finalizedEntryCount;
  final int batchCount;
  final double batchCoverageRatio;
  final String batchPlanningMode;
  final String batchGoalKind;
  final String batchStructureMode;
  final int batchTargetSourceChars;
  final int batchMaxSourceChars;
  final int availableContextChars;
  final int completedBatchCount;
  final int failedBatchCount;
  final int pendingBatchCount;
  final String runStatus;
  final int continuationRoundCount;
  final String deliveryStatus;
  final String deliveryRationale;
  final String outputCompletionStatus;
  final String outputCompressionRiskLevel;
  final bool needsContinuation;
  final int omissionReportCount;
  final int continuationRequestCount;
  final List<String> uncoveredCoverageDimensionIds;
  final List<String> coveredCoverageDimensionIds;
  final List<String> followupSegmentIds;
  final bool coverageRequiresFollowup;
  final int conflictClusterCount;
  final int canonDecisionCount;
  final int reviewAlertCount;
  final bool requiresManualContinuityReview;
  final int unresolvedConflictCount;
  final bool publishedSnapshotAvailable;
  final bool attachToProjectRequested;
  final bool projectMountedEntriesRequested;
  final String projectMountStatus;
  final List<String> projectMountWarningCodes;
  final String bundleOutputDirectory;
  final String stagingRunPath;
  final List<String> knowledgeCardIds;
  final List<String> designElementIds;
  final List<String> researchNoteIds;
  final List<String> referenceWorkIds;
  final List<String> generatedProjectionPaths;
}
