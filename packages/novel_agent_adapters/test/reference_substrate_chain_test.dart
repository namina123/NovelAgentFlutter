import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Reference substrate main chains', () {
    late Directory tempDirectory;
    late Directory substrateDirectory;
    late Directory projectDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late SqliteReferenceEvidenceSubstrate substrate;
    late SqliteProjectReferenceAttachmentLayer attachmentLayer;
    late LocalKnowledgeCardRepository knowledgeRepository;
    late LocalDesignElementRepository designRepository;
    late LocalResearchNoteRepository researchRepository;
    late LocalReferenceWorkRepository referenceRepository;
    late ProjectInformationProjectionWriterService projectionWriter;
    late ProjectReferenceProjectionService projectionService;
    late ProjectInformationPromotionService promotionService;
    late ProjectDescriptor project;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'reference_substrate_chain_test_',
      );
      substrateDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}substrate',
      )..createSync(recursive: true);
      projectDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}project',
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
        knowledgeCardRepository: knowledgeRepository,
        designElementRepository: designRepository,
        researchNoteRepository: researchRepository,
        referenceWorkRepository: referenceRepository,
        projectionWriterService: projectionWriter,
      );
      promotionService = ProjectInformationPromotionService(
        substrate: substrate,
        knowledgeCardRepository: knowledgeRepository,
        designElementRepository: designRepository,
        researchNoteRepository: researchRepository,
        referenceWorkRepository: referenceRepository,
      );
      project = ProjectDescriptor(
        id: 'project_hp',
        name: '哈利波特同人测试项目',
        rootPath: projectDirectory.path,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'covers projection, bundle import/export, permission gate and explicit promotion',
      () async {
        await substrate.upsertPackageSnapshot(_referenceSnapshot());
        await attachmentLayer.upsertAttachment(
          project,
          const ProjectReferenceAttachment(
            attachmentId: 'attach_hp_v1',
            projectId: 'project_hp',
            packageId: 'pkg_hp',
            packageVersionId: 'v1',
            visibilityMode: ReferenceVisibilityModes.discoverable,
            accessLevel: ReferenceAccessLevels.projectable,
            allowsProjection: true,
            attachedAt: '2026-06-07T12:00:00Z',
          ),
        );

        final projectionResult = await projectionService.projectMountedEntries(
          project,
          const ReferenceProjectionRequest(
            packageId: 'pkg_hp',
            packageVersionId: 'v1',
            requestedBy: 'tester',
          ),
        );

        expect(projectionResult.status, ReferenceProjectionStatuses.applied);
        expect(projectionResult.knowledgeCardIds, contains('ref_entry_fact'));
        final projectedCard = await knowledgeRepository.readKnowledgeCard(
          project,
          cardId: 'ref_entry_fact',
        );
        expect(projectedCard, isNotNull);
        final projectionFile = File(
          '${projectDirectory.path}${Platform.pathSeparator}knowledge${Platform.pathSeparator}项目知识摘要.md',
        );
        expect(await projectionFile.exists(), isTrue);

        final substrateEntriesAfterProjection = await substrate.listEntries(
          packageId: 'pkg_hp',
          packageVersionId: 'v1',
        );
        expect(substrateEntriesAfterProjection, hasLength(2));

        final bundleDirectory = Directory(
          '${tempDirectory.path}${Platform.pathSeparator}bundle_export',
        );
        final exportService = ReferenceBundleExportService(
          substrate: substrate,
        );
        await exportService.exportToDirectory(
          bundleDirectory.path,
          const ReferenceBundleExportRequest(
            packageId: 'pkg_hp',
            packageVersionId: 'v1',
            bundleId: 'bundle_hp_v1',
            createdAt: '2026-06-07T12:10:00Z',
            createdBy: 'tester',
          ),
        );
        expect(
          File(
            '${bundleDirectory.path}${Platform.pathSeparator}manifest.json',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '${bundleDirectory.path}${Platform.pathSeparator}payload${Platform.pathSeparator}entries.json',
          ).existsSync(),
          isTrue,
        );

        final importSubstrateDirectory = Directory(
          '${tempDirectory.path}${Platform.pathSeparator}substrate_imported',
        )..createSync(recursive: true);
        final importedSubstrate = SqliteReferenceEvidenceSubstrate(
          substrateRootPath: importSubstrateDirectory.path,
        );
        final importService = ReferenceBundleImportService(
          substrate: importedSubstrate,
        );
        final importResult = await importService.importFromDirectory(
          bundleDirectory.path,
        );
        expect(importResult.packageId, 'pkg_hp');
        final importedSnapshot = await importedSubstrate.readPackageSnapshot(
          packageId: 'pkg_hp',
          packageVersionId: 'v1',
        );
        expect(importedSnapshot, isNotNull);
        expect(importedSnapshot!.entries, hasLength(2));

        final restrictedProject = ProjectDescriptor(
          id: 'project_restricted',
          name: '受限项目',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}restricted_project',
        );
        await Directory(restrictedProject.rootPath).create(recursive: true);
        await attachmentLayer.upsertAttachment(
          restrictedProject,
          const ProjectReferenceAttachment(
            attachmentId: 'attach_hp_summary',
            projectId: 'project_restricted',
            packageId: 'pkg_hp',
            packageVersionId: 'v1',
            visibilityMode: ReferenceVisibilityModes.discoverable,
            accessLevel: ReferenceAccessLevels.summaryOnly,
            allowsProjection: false,
            attachedAt: '2026-06-07T12:20:00Z',
          ),
        );
        final deniedProjection = await projectionService.projectMountedEntries(
          restrictedProject,
          const ReferenceProjectionRequest(
            packageId: 'pkg_hp',
            packageVersionId: 'v1',
            requestedBy: 'tester',
          ),
        );
        expect(deniedProjection.status, ReferenceProjectionStatuses.denied);
        final deniedCard = await knowledgeRepository.readKnowledgeCard(
          restrictedProject,
          cardId: 'ref_entry_fact',
        );
        expect(deniedCard, isNull);

        await knowledgeRepository.appendKnowledgeCard(
          project,
          ProjectKnowledgeCard(
            cardId: 'card_project_only',
            cardNamespace: 'fanfic_branch',
            cardType: 'branch_fact',
            title: '斯内普提前暴露真相',
            summary: '第二卷前半段就暴露伏地魔操控线索。',
            contentPayload: const <String, Object?>{
              'fact': 'snape reveals early',
            },
            sourceRefs: <InformationSourceRef>[
              InformationSourceRef(
                sourceRef: const NarrativeSourceRef(
                  sourceType: 'project_note',
                  sourceId: 'local-001',
                ),
                sourceAuthority: InformationSourceAuthorities.userDeclared,
                roleAuthority: InformationRoleAuthorities.writer,
                researchDepth: InformationResearchDepths.standard,
              ),
            ],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.normal,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.91,
            lifecycleStatus: 'confirmed',
          ),
        );

        final promotionResult = await promotionService.promote(
          project,
          const ReferencePromotionRequest(
            packageId: 'pkg_hp',
            packageKind: ReferencePackageKinds.referenceWorkPackage,
            displayName: '哈利波特原作与同人偏离包',
            packageVersionId: 'v1',
            versionLabel: '2026.06',
            sourceProjectId: 'project_hp',
            sourceArtifactKind: ProjectInformationArtifactKinds.knowledgeCard,
            sourceArtifactId: 'card_project_only',
            promotedAt: '2026-06-07T12:30:00Z',
            promotedBy: 'tester',
            targetEntryKind: ReferenceEntryKinds.divergenceSnapshot,
          ),
        );
        expect(promotionResult.status, ReferencePromotionStatuses.promoted);
        final substrateEntriesAfterPromotion = await substrate.listEntries(
          packageId: 'pkg_hp',
          packageVersionId: 'v1',
        );
        expect(substrateEntriesAfterPromotion, hasLength(3));
        final promotedEntry = substrateEntriesAfterPromotion.firstWhere(
          (entry) => entry.entryId == 'knowledge_card_card_project_only',
        );
        expect(promotedEntry.entryKind, ReferenceEntryKinds.divergenceSnapshot);
        final originalCard = await knowledgeRepository.readKnowledgeCard(
          project,
          cardId: 'card_project_only',
        );
        expect(originalCard, isNotNull);
        expect(originalCard!.title, '斯内普提前暴露真相');
      },
    );
  });
}

ReferencePackageSnapshot _referenceSnapshot() {
  final sourceRef = InformationSourceRef(
    sourceRef: const NarrativeSourceRef(
      sourceType: 'imported_book',
      sourceId: 'hp_original_volume_1',
      label: '哈利波特原作',
    ),
    sourceAuthority: InformationSourceAuthorities.sourceDocument,
    roleAuthority: InformationRoleAuthorities.deconstructor,
    researchDepth: InformationResearchDepths.deep,
  );
  return ReferencePackageSnapshot(
    packageRecord: const ReferencePackageRecord(
      packageId: 'pkg_hp',
      packageKind: ReferencePackageKinds.referenceWorkPackage,
      displayName: '哈利波特原作包',
      packageNamespace: 'hp',
      description: '原作可复用参考资产包',
      latestVersionId: 'v1',
      lifecycleStatus: 'active',
      createdAt: '2026-06-07T12:00:00Z',
      updatedAt: '2026-06-07T12:00:00Z',
    ),
    packageVersionRecord: const ReferencePackageVersionRecord(
      packageVersionId: 'v1',
      packageId: 'pkg_hp',
      versionLabel: '2026.06',
      createdAt: '2026-06-07T12:00:00Z',
      createdBy: 'tester',
    ),
    entries: <ReferenceEntryRecord>[
      ReferenceEntryRecord(
        entryId: 'entry_fact',
        packageId: 'pkg_hp',
        packageVersionId: 'v1',
        entryNamespace: 'wizarding_world',
        entryKind: ReferenceEntryKinds.knowledgeFact,
        title: '魔杖选择巫师',
        summary: '原作中明确由魔杖选择巫师。',
        payload: const <String, Object?>{'fact': 'wand chooses wizard'},
        sourceRefs: <InformationSourceRef>[sourceRef],
        activationPolicy: const InformationActivationPolicy(
          activationPriority: InformationActivationPriorities.required,
        ),
        usagePolicy: const InformationUsagePolicy(
          usageMode: InformationUsageModes.referenceOnly,
          citationRiskLevel: InformationCitationRiskLevels.normal,
        ),
        confidence: 0.96,
        lifecycleStatus: 'active',
      ),
      ReferenceEntryRecord(
        entryId: 'entry_style',
        packageId: 'pkg_hp',
        packageVersionId: 'v1',
        entryNamespace: 'style',
        entryKind: ReferenceEntryKinds.styleTechnique,
        title: '奇观递进式儿童冒险视角',
        summary: '通过新奇感逐步扩大魔法世界范围。',
        payload: const <String, Object?>{'technique': 'wonder escalation'},
        sourceRefs: <InformationSourceRef>[sourceRef],
        activationPolicy: const InformationActivationPolicy(
          activationPriority: InformationActivationPriorities.reference,
        ),
        usagePolicy: const InformationUsagePolicy(
          usageMode: InformationUsageModes.referenceOnly,
          citationRiskLevel: InformationCitationRiskLevels.normal,
        ),
        confidence: 0.84,
        lifecycleStatus: 'active',
      ),
    ],
  );
}
