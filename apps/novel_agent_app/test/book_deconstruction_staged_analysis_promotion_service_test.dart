import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_staged_analysis_promotion_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('promotes only the explicitly identified staged package', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'book_deconstruction_staged_analysis_promotion_test_',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final projectDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}project',
    );
    await projectDirectory.create(recursive: true);
    final project = ProjectDescriptor(
      id: 'staged-analysis-project',
      name: '暂存分析推广测试',
      rootPath: projectDirectory.path,
      projectType: 'book_deconstruction',
    );
    final pathService = ProjectReferenceExtractionPathService();
    final substrate = SqliteReferenceEvidenceSubstrate(
      substrateRootPath: pathService.substrateRootPath(project),
    );
    final stagedSnapshot = _snapshot();
    await substrate.upsertPackageSnapshot(stagedSnapshot);
    final stagingWorkspace = _InMemoryStagingWorkspace(
      _stagingRun(stagedSnapshot),
    );

    final service = BookDeconstructionStagedAnalysisPromotionService(
      stagingWorkspaceFactory: (_) => stagingWorkspace,
    );
    await service.validate(
      project: project,
      runId: 'staged-run-1',
      packageId: 'staged-package-1',
      packageVersionId: 'staged-version-1',
    );
    final result = await service.promote(
      project: project,
      runId: 'staged-run-1',
      packageId: 'staged-package-1',
      packageVersionId: 'staged-version-1',
    );

    expect(result.mountStatus, ProjectReferenceMountStatuses.applied);
    expect(result.packageId, 'staged-package-1');
    expect(result.packageVersionId, 'staged-version-1');
    expect(result.changedPaths, isNotEmpty);
    final projected = await SqliteKnowledgeCardRepository().readKnowledgeCard(
      project,
      cardId: 'ref_staged-entry-1',
    );
    expect(projected, isNotNull);
  });

  test('refuses a staged run whose package identity does not match', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'book_deconstruction_staged_analysis_missing_test_',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final project = ProjectDescriptor(
      id: 'staged-analysis-mismatch-project',
      name: '暂存分析包不匹配',
      rootPath: tempDirectory.path,
      projectType: 'book_deconstruction',
    );

    final stagingWorkspace = _InMemoryStagingWorkspace(
      _stagingRun(_snapshot()),
    );
    await expectLater(
      BookDeconstructionStagedAnalysisPromotionService(
        stagingWorkspaceFactory: (_) => stagingWorkspace,
      ).validate(
        project: project,
        runId: 'staged-run-1',
        packageId: 'another-package',
        packageVersionId: 'staged-version-1',
      ),
      throwsA(isA<StateError>()),
    );
  });
}

ReferenceExtractionStagingRun _stagingRun(ReferencePackageSnapshot snapshot) {
  return ReferenceExtractionStagingRun(
    runId: 'staged-run-1',
    packageId: snapshot.packageRecord.packageId,
    packageVersionId: snapshot.packageVersionRecord.packageVersionId,
    sourceDocumentTitle: '拆书源文',
    sourceLanguage: 'zh-CN',
    targetLanguage: 'zh-CN',
    groupResolution: const ReferenceExtractionGroupResolution(
      selectedGroup: ResolvedAgentGroupProfile(
        id: 'test-group',
        name: 'test',
        description: 'test',
        orchestration: 'single',
        members: <ResolvedAgentGroupMemberProfile>[],
      ),
      resolutionKind: 'test',
      executionProfile: ReferenceExtractionExecutionProfile(
        taskFamilyId: 'reference_extraction',
        executionMode: 'single',
        instructionProfileId: 'test',
        toolPermissionProfileId: 'test',
      ),
    ),
    seedSnapshot: snapshot,
    finalizedSnapshot: snapshot,
    runStatus: ReferenceExtractionRunStatuses.completedPublishable,
    deliveryDecision: const ReferenceExtractionDeliveryDecision(
      deliveryStatus: ReferenceExtractionDeliveryStatuses.publishable,
    ),
  );
}

class _InMemoryStagingWorkspace implements ReferenceExtractionStagingWorkspace {
  _InMemoryStagingWorkspace(this._run);

  ReferenceExtractionStagingRun? _run;

  @override
  Future<ReferenceExtractionStagingRun?> readRun(String runId) async {
    return _run?.runId == runId ? _run : null;
  }

  @override
  Future<void> upsertRun(ReferenceExtractionStagingRun run) async {
    _run = run;
  }
}

ReferencePackageSnapshot _snapshot() {
  const sourceRef = InformationSourceRef(
    sourceRef: NarrativeSourceRef(
      sourceType: 'book_deconstruction',
      sourceId: 'source-document',
      label: '拆书源文',
    ),
    sourceAuthority: InformationSourceAuthorities.sourceDocument,
    roleAuthority: InformationRoleAuthorities.deconstructor,
    researchDepth: InformationResearchDepths.deep,
  );
  return ReferencePackageSnapshot(
    packageRecord: const ReferencePackageRecord(
      packageId: 'staged-package-1',
      packageKind: ReferencePackageKinds.referenceWorkPackage,
      displayName: '步骤③暂存分析包',
      latestVersionId: 'staged-version-1',
      lifecycleStatus: 'active',
      createdAt: '2026-07-23T00:00:00Z',
      updatedAt: '2026-07-23T00:00:00Z',
    ),
    packageVersionRecord: const ReferencePackageVersionRecord(
      packageVersionId: 'staged-version-1',
      packageId: 'staged-package-1',
      versionLabel: 'staged',
      createdAt: '2026-07-23T00:00:00Z',
      createdBy: 'test',
    ),
    entries: <ReferenceEntryRecord>[
      ReferenceEntryRecord(
        entryId: 'staged-entry-1',
        packageId: 'staged-package-1',
        packageVersionId: 'staged-version-1',
        entryNamespace: 'book_deconstruction',
        entryKind: ReferenceEntryKinds.knowledgeFact,
        title: '暂存分析事实',
        summary: '只有在确认中显式选择后才可应用。',
        payload: const <String, Object?>{'fact': 'staged'},
        sourceRefs: const <InformationSourceRef>[sourceRef],
        activationPolicy: const InformationActivationPolicy(
          activationPriority: InformationActivationPriorities.reference,
        ),
        usagePolicy: const InformationUsagePolicy(
          usageMode: InformationUsageModes.referenceOnly,
          citationRiskLevel: InformationCitationRiskLevels.normal,
        ),
        confidence: 0.9,
        lifecycleStatus: 'active',
      ),
    ],
  );
}
