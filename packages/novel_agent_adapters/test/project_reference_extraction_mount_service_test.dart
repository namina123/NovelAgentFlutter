import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectReferenceExtractionMountService', () {
    late Directory tempDirectory;
    late Directory substrateDirectory;
    late Directory projectDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late SqliteReferenceEvidenceSubstrate substrate;
    late SqliteKnowledgeCardRepository knowledgeRepository;
    late ProjectReferenceExtractionMountService mountService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'project_reference_extraction_mount_test_',
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
      knowledgeRepository = SqliteKnowledgeCardRepository();
      mountService = ProjectReferenceExtractionMountService(
        workspacePort: workspacePort,
      );
      project = ProjectDescriptor(
        id: 'project_mount_test',
        name: '参考挂载测试项目',
        rootPath: projectDirectory.path,
      );
      await substrate.upsertPackageSnapshot(_referenceSnapshot());
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('attaches package and projects mounted entries into project', () async {
      final result = await mountService.attachAndProjectIfRequested(
        project: project,
        substrate: substrate,
        request: const ProjectReferenceExtractionRequest(
          sourceFilePath: 'unused.txt',
        ),
        packageId: 'pkg_hp',
        packageVersionId: 'v1',
        displayName: '哈利波特原作包',
        attachedAt: '2026-06-08T01:00:00Z',
      );

      expect(result.status, ProjectReferenceMountStatuses.applied);
      expect(result.projectionResult, isNotNull);
      expect(result.knowledgeCardIds, contains('ref_entry_fact'));
      final projectedCard = await knowledgeRepository.readKnowledgeCard(
        project,
        cardId: 'ref_entry_fact',
      );
      expect(projectedCard, isNotNull);
      expect(
        File(
          '${project.rootPath}${Platform.pathSeparator}knowledge${Platform.pathSeparator}项目知识摘要.md',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}knowledge_cards${Platform.pathSeparator}ref_entry_fact.json',
        ).existsSync(),
        isFalse,
      );
      final attachmentLayer = SqliteProjectReferenceAttachmentLayer();
      final attachment = await attachmentLayer.readAttachment(
        project,
        packageId: 'pkg_hp',
      );
      expect(attachment, isNotNull);
      expect(attachment!.displayLabel, '哈利波特原作包');
    });

    test('can attach without projecting mounted entries', () async {
      final result = await mountService.attachAndProjectIfRequested(
        project: project,
        substrate: substrate,
        request: const ProjectReferenceExtractionRequest(
          sourceFilePath: 'unused.txt',
          projectMountedEntries: false,
          attachToProject: true,
        ),
        packageId: 'pkg_hp',
        packageVersionId: 'v1',
        displayName: '哈利波特原作包',
        attachedAt: '2026-06-08T01:10:00Z',
      );

      expect(result.status, ProjectReferenceMountStatuses.attachedOnly);
      expect(result.projectionResult, isNull);
      final attachmentLayer = SqliteProjectReferenceAttachmentLayer();
      final attachment = await attachmentLayer.readAttachment(
        project,
        packageId: 'pkg_hp',
      );
      expect(attachment, isNotNull);
      expect(
        File(
          '${project.rootPath}${Platform.pathSeparator}knowledge${Platform.pathSeparator}项目知识摘要.md',
        ).existsSync(),
        isFalse,
      );
    });

    test(
      'can opt into json compatibility export without changing sqlite-first primary sink',
      () async {
        mountService = ProjectReferenceExtractionMountService(
          workspacePort: workspacePort,
          projectionPortFactory:
              SqliteFirstProjectReferenceProjectionPortFactory(
                workspacePort: workspacePort,
                enableJsonCompatibilityExport: true,
              ),
        );

        final result = await mountService.attachAndProjectIfRequested(
          project: project,
          substrate: substrate,
          request: const ProjectReferenceExtractionRequest(
            sourceFilePath: 'unused.txt',
          ),
          packageId: 'pkg_hp',
          packageVersionId: 'v1',
          displayName: '哈利波特原作包',
          attachedAt: '2026-06-08T01:20:00Z',
        );

        expect(result.status, ProjectReferenceMountStatuses.applied);
        expect(result.projectionResult, isNotNull);
        expect(
          await knowledgeRepository.readKnowledgeCard(
            project,
            cardId: 'ref_entry_fact',
          ),
          isNotNull,
        );
        expect(
          File(
            '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}knowledge_cards${Platform.pathSeparator}ref_entry_fact.json',
          ).existsSync(),
          isTrue,
        );
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
        entryId: 'entry_boundary',
        packageId: 'pkg_hp',
        packageVersionId: 'v1',
        entryNamespace: 'style',
        entryKind: ReferenceEntryKinds.referenceWorkBoundary,
        title: '引用边界',
        summary: '提取内容可做内部分析，不应直接替代原文引用。',
        payload: const <String, Object?>{'declared_usage_intent': '内部分析'},
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
