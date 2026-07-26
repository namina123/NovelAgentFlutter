import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectReferenceProjectionService alignment summary', () {
    late Directory tempDirectory;
    late Directory substrateDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late SqliteReferenceEvidenceSubstrate substrate;
    late SqliteProjectReferenceAttachmentLayer attachmentLayer;
    late LocalKnowledgeCardRepository knowledgeRepository;
    late LocalDesignElementRepository designRepository;
    late LocalResearchNoteRepository researchRepository;
    late LocalReferenceWorkRepository referenceRepository;
    late ProjectInformationProjectionWriterService projectionWriter;
    late ProjectReferenceProjectionService projectionService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'project_reference_alignment_summary_test_',
      );
      substrateDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}substrate',
      )..createSync(recursive: true);
      workspacePort = LocalProjectWorkspacePort();
      substrate = SqliteReferenceEvidenceSubstrate(
        substrateRootPath: substrateDirectory.path,
      );
      attachmentLayer = SqliteProjectReferenceAttachmentLayer();
      knowledgeRepository = LocalKnowledgeCardRepository(
        workspacePort: workspacePort,
      );
      designRepository = LocalDesignElementRepository(
        workspacePort: workspacePort,
      );
      researchRepository = LocalResearchNoteRepository(
        workspacePort: workspacePort,
      );
      referenceRepository = LocalReferenceWorkRepository(
        workspacePort: workspacePort,
      );
      projectionWriter = ProjectInformationProjectionWriterService(
        workspacePort: workspacePort,
        knowledgeCardRepository: knowledgeRepository,
        designElementRepository: designRepository,
        researchNoteRepository: researchRepository,
        referenceWorkRepository: referenceRepository,
      );
      projectionService = ProjectReferenceProjectionService(
        substrate: substrate,
        attachmentLayer: attachmentLayer,
        workspacePort: workspacePort,
        knowledgeCardRepository: knowledgeRepository,
        designElementRepository: designRepository,
        researchNoteRepository: researchRepository,
        referenceWorkRepository: referenceRepository,
        projectionWriterService: projectionWriter,
      );
      project = ProjectDescriptor(
        id: 'project_knowledge_base',
        name: '资料知识库项目',
        rootPath: tempDirectory.path,
        projectType: 'knowledge_base',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      await substrate.upsertPackageSnapshot(_referenceSnapshot());
      await attachmentLayer.upsertAttachment(
        project,
        const ProjectReferenceAttachment(
          attachmentId: 'attach_pkg_reference',
          projectId: 'project_knowledge_base',
          packageId: 'pkg_reference',
          packageVersionId: 'v1',
          visibilityMode: ReferenceVisibilityModes.discoverable,
          accessLevel: ReferenceAccessLevels.projectable,
          allowsProjection: true,
          attachedAt: '2026-06-14T08:00:00Z',
          displayLabel: '资料治理挂载',
        ),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'writes 项目资料总览 and keeps the three user-facing layers visible',
      () async {
        // 中文注释: 这里验证 reference projection 会把项目资料、待审核资产和可提升正式资产统一写进知识目录中的总览页。
        final result = await projectionService.projectMountedEntries(
          project,
          const ReferenceProjectionRequest(
            packageId: 'pkg_reference',
            packageVersionId: 'v1',
            requestedBy: 'tester',
          ),
        );

        expect(result.status, ReferenceProjectionStatuses.applied);
        expect(
          result.generatedProjectionPaths,
          contains('knowledge/项目资料总览.md'),
        );
        final summaryFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}knowledge${Platform.pathSeparator}项目资料总览.md',
        );
        expect(await summaryFile.exists(), isTrue);
        final summaryMarkdown = await summaryFile.readAsString();
        expect(summaryMarkdown, contains('项目资料总览'));
        expect(summaryMarkdown, contains('项目私有草稿资产'));
        expect(summaryMarkdown, contains('待审核资产'));
        expect(summaryMarkdown, contains('可提升到参考资产库的正式资产'));
        expect(summaryMarkdown, contains('项目资料挂载'));
        expect(summaryMarkdown, contains('参考资产库'));

        final projectedCard = await knowledgeRepository.readKnowledgeCard(
          project,
          cardId: 'ref_entry_draft',
        );
        expect(projectedCard, isNotNull);
        expect(
          projectedCard!.metadata['project_visibility_state_label'],
          '项目私有草稿资产',
        );
        expect(projectedCard.metadata['project_surface_label'], '项目资料');
        expect(projectedCard.metadata['project_mount_label'], '项目资料挂载');
        expect(projectedCard.metadata['reference_library_label'], '参考资产库');
      },
    );
  });
}

ReferencePackageSnapshot _referenceSnapshot() {
  final sourceRef = InformationSourceRef(
    sourceRef: const NarrativeSourceRef(
      sourceType: 'imported_book',
      sourceId: 'reference_package_v1',
      label: '参考包来源',
    ),
    sourceAuthority: InformationSourceAuthorities.sourceDocument,
    roleAuthority: InformationRoleAuthorities.deconstructor,
    researchDepth: InformationResearchDepths.standard,
  );
  return ReferencePackageSnapshot(
    packageRecord: const ReferencePackageRecord(
      packageId: 'pkg_reference',
      packageKind: ReferencePackageKinds.referenceWorkPackage,
      displayName: '参考资产库包',
      packageNamespace: 'reference',
      description: '资料知识库对齐包',
      latestVersionId: 'v1',
      lifecycleStatus: 'active',
      createdAt: '2026-06-14T08:00:00Z',
      updatedAt: '2026-06-14T08:00:00Z',
    ),
    packageVersionRecord: const ReferencePackageVersionRecord(
      packageVersionId: 'v1',
      packageId: 'pkg_reference',
      versionLabel: '2026.06',
      createdAt: '2026-06-14T08:00:00Z',
      createdBy: 'tester',
    ),
    entries: <ReferenceEntryRecord>[
      ReferenceEntryRecord(
        entryId: 'entry_draft',
        packageId: 'pkg_reference',
        packageVersionId: 'v1',
        entryNamespace: 'project',
        entryKind: ReferenceEntryKinds.knowledgeFact,
        title: '项目私有草稿条目',
        summary: '尚未进入审核流程。',
        payload: const <String, Object?>{'status': 'draft'},
        sourceRefs: <InformationSourceRef>[sourceRef],
        activationPolicy: const InformationActivationPolicy(
          activationPriority: InformationActivationPriorities.normal,
        ),
        usagePolicy: const InformationUsagePolicy(
          usageMode: InformationUsageModes.normal,
          citationRiskLevel: InformationCitationRiskLevels.low,
        ),
        confidence: 0.82,
        lifecycleStatus: 'draft',
      ),
      ReferenceEntryRecord(
        entryId: 'entry_review',
        packageId: 'pkg_reference',
        packageVersionId: 'v1',
        entryNamespace: 'project',
        entryKind: ReferenceEntryKinds.designElement,
        title: '待审核设计元素',
        summary: '需要人工复核后再提升。',
        payload: const <String, Object?>{'status': 'review'},
        sourceRefs: <InformationSourceRef>[sourceRef],
        activationPolicy: const InformationActivationPolicy(
          activationPriority: InformationActivationPriorities.reference,
        ),
        usagePolicy: const InformationUsagePolicy(
          usageMode: InformationUsageModes.referenceOnly,
          citationRiskLevel: InformationCitationRiskLevels.normal,
        ),
        confidence: 0.86,
        lifecycleStatus: 'under_review',
      ),
      ReferenceEntryRecord(
        entryId: 'entry_formal',
        packageId: 'pkg_reference',
        packageVersionId: 'v1',
        entryNamespace: 'project',
        entryKind: ReferenceEntryKinds.referenceWorkBoundary,
        title: '可提升正式边界',
        summary: '已具备正式挂载或提升条件。',
        payload: const <String, Object?>{'status': 'formal'},
        sourceRefs: <InformationSourceRef>[sourceRef],
        activationPolicy: const InformationActivationPolicy(
          activationPriority: InformationActivationPriorities.required,
        ),
        usagePolicy: const InformationUsagePolicy(
          usageMode: InformationUsageModes.referenceOnly,
          citationRiskLevel: InformationCitationRiskLevels.normal,
        ),
        confidence: 0.94,
        lifecycleStatus: 'confirmed',
      ),
    ],
  );
}
