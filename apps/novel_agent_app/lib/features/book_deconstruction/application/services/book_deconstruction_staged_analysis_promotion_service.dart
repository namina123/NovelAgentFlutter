import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

/// Promotes a publishable reference-extraction package that was deliberately
/// kept in staging during the optional book-deconstruction analysis step.
///
/// This service never starts extraction and never discovers a "latest" run.
/// Callers must provide the exact identifiers persisted with the workflow
/// state, which prevents a reopened project from silently applying unrelated
/// staged output.
class BookDeconstructionStagedAnalysisPromotionService {
  BookDeconstructionStagedAnalysisPromotionService({
    ProjectReferenceExtractionPathService? pathService,
    ProjectReferenceExtractionMountService? mountService,
    ReferenceEvidenceSubstrate Function(ProjectDescriptor project)?
    substrateFactory,
    ReferenceExtractionStagingWorkspace Function(ProjectDescriptor project)?
    stagingWorkspaceFactory,
    DateTime Function()? now,
  }) : _pathService = pathService ?? ProjectReferenceExtractionPathService(),
       _mountService =
           mountService ??
           ProjectReferenceExtractionMountService(
             workspacePort: LocalProjectWorkspacePort(),
           ),
       _substrateFactory =
           substrateFactory ??
           ((project) => SqliteReferenceEvidenceSubstrate(
             substrateRootPath:
                 (pathService ?? ProjectReferenceExtractionPathService())
                     .substrateRootPath(project),
           )),
       _stagingWorkspaceFactory =
           stagingWorkspaceFactory ??
           ((project) => FileReferenceExtractionStagingWorkspace(
             stagingRootPath:
                 (pathService ?? ProjectReferenceExtractionPathService())
                     .stagingRootPath(project),
           )),
       _now = now ?? DateTime.now;

  final ProjectReferenceExtractionPathService _pathService;
  final ProjectReferenceExtractionMountService _mountService;
  final ReferenceEvidenceSubstrate Function(ProjectDescriptor project)
  _substrateFactory;
  final ReferenceExtractionStagingWorkspace Function(ProjectDescriptor project)
  _stagingWorkspaceFactory;
  final DateTime Function() _now;

  /// Checks that the exact staged package still exists before confirmation
  /// begins durable writes. Mount failures that happen after this check are
  /// still journaled by the confirmation workflow.
  Future<void> validate({
    required ProjectDescriptor project,
    required String runId,
    required String packageId,
    required String packageVersionId,
  }) async {
    await _loadStagedSnapshot(
      project: project,
      runId: runId,
      packageId: packageId,
      packageVersionId: packageVersionId,
    );
  }

  Future<BookDeconstructionStagedAnalysisPromotionResult> promote({
    required ProjectDescriptor project,
    required String runId,
    required String packageId,
    required String packageVersionId,
  }) async {
    final snapshot = await _loadStagedSnapshot(
      project: project,
      runId: runId,
      packageId: packageId,
      packageVersionId: packageVersionId,
    );
    final cleanRunId = runId.trim();
    final cleanPackageId = packageId.trim();
    final cleanPackageVersionId = packageVersionId.trim();
    final mountOutcome = await _mountService.attachAndProjectIfRequested(
      project: project,
      substrate: _substrateFactory(project),
      request: ProjectReferenceExtractionRequest(
        // Mounting only reads the already-staged substrate. The source path is
        // retained as an audit label and is never used to re-run extraction.
        sourceFilePath: _stagingRunPath(project, cleanRunId),
        packageId: cleanPackageId,
        packageVersionId: cleanPackageVersionId,
        displayName: snapshot.packageRecord.displayName,
        exportBundle: false,
        attachToProject: true,
        projectMountedEntries: true,
        explicitProjectionConfirmationGranted: true,
        runId: cleanRunId,
      ),
      packageId: cleanPackageId,
      packageVersionId: cleanPackageVersionId,
      displayName: snapshot.packageRecord.displayName,
      attachedAt: _now().toUtc().toIso8601String(),
    );
    if (mountOutcome.status != ProjectReferenceMountStatuses.applied) {
      throw StateError('暂存分析包未能应用到项目资产（挂载状态：${mountOutcome.status}）。');
    }
    return BookDeconstructionStagedAnalysisPromotionResult(
      runId: cleanRunId,
      packageId: cleanPackageId,
      packageVersionId: cleanPackageVersionId,
      mountStatus: mountOutcome.status,
      changedPaths: List<String>.unmodifiable(
        mountOutcome.generatedProjectionPaths,
      ),
      warningCodes: List<String>.unmodifiable(mountOutcome.warningCodes),
    );
  }

  Future<ReferencePackageSnapshot> _loadStagedSnapshot({
    required ProjectDescriptor project,
    required String runId,
    required String packageId,
    required String packageVersionId,
  }) async {
    final cleanRunId = runId.trim();
    final cleanPackageId = packageId.trim();
    final cleanPackageVersionId = packageVersionId.trim();
    if (cleanRunId.isEmpty ||
        cleanPackageId.isEmpty ||
        cleanPackageVersionId.isEmpty) {
      throw StateError('暂存分析结果缺少运行、资料包或版本标识，无法应用。');
    }
    final stagingRun = await _stagingWorkspaceFactory(
      project,
    ).readRun(cleanRunId);
    if (stagingRun == null) {
      throw StateError('找不到步骤③暂存的分析运行记录，请重新执行分析后再确认。');
    }
    if (stagingRun.runId.trim() != cleanRunId ||
        stagingRun.packageId.trim() != cleanPackageId ||
        stagingRun.packageVersionId.trim() != cleanPackageVersionId) {
      throw StateError('暂存分析运行与待应用的资料包版本不匹配，已拒绝应用。');
    }
    if (!stagingRun.deliveryDecision.isPublishable ||
        stagingRun.finalizedSnapshot == null) {
      throw StateError('步骤③暂存分析尚未形成可应用的发布快照，请继续分析或重新执行。');
    }
    final snapshot = await _substrateFactory(project).readPackageSnapshot(
      packageId: cleanPackageId,
      packageVersionId: cleanPackageVersionId,
    );
    if (snapshot == null) {
      throw StateError('找不到步骤③暂存的分析资料包，请重新执行分析后再确认。');
    }
    if (snapshot.entries.isEmpty) {
      throw StateError('步骤③暂存的分析资料包没有可应用的条目，请重新执行分析。');
    }
    return snapshot;
  }

  String _stagingRunPath(ProjectDescriptor project, String runId) {
    final stagingRootPath = _pathService.stagingRootPath(project);
    return '$stagingRootPath/$runId.json';
  }
}

class BookDeconstructionStagedAnalysisPromotionResult {
  const BookDeconstructionStagedAnalysisPromotionResult({
    required this.runId,
    required this.packageId,
    required this.packageVersionId,
    required this.mountStatus,
    required this.changedPaths,
    required this.warningCodes,
  });

  final String runId;
  final String packageId;
  final String packageVersionId;
  final String mountStatus;
  final List<String> changedPaths;
  final List<String> warningCodes;
}
