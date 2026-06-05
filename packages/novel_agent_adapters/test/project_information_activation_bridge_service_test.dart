import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectInformationActivationBridgeService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late LocalKnowledgeCardRepository knowledgeCardRepository;
    late LocalDesignElementRepository designElementRepository;
    late LocalResearchNoteRepository researchNoteRepository;
    late LocalReferenceWorkRepository referenceWorkRepository;
    late ProjectInformationActivationBridgeService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-information-activation-bridge-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '信息激活桥接测试',
        rootPath: tempDirectory.path,
      );
      knowledgeCardRepository = LocalKnowledgeCardRepository(
        workspacePort: workspacePort,
      );
      designElementRepository = LocalDesignElementRepository(
        workspacePort: workspacePort,
      );
      researchNoteRepository = LocalResearchNoteRepository(
        workspacePort: workspacePort,
      );
      referenceWorkRepository = LocalReferenceWorkRepository(
        workspacePort: workspacePort,
      );
      service = ProjectInformationActivationBridgeService(
        workspacePort: workspacePort,
        knowledgeCardRepository: knowledgeCardRepository,
        designElementRepository: designElementRepository,
        researchNoteRepository: researchNoteRepository,
        referenceWorkRepository: referenceWorkRepository,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'buildItems converts knowledge design research and reference records with activation metadata',
      () async {
        await knowledgeCardRepository.appendKnowledgeCard(
          project,
          ProjectKnowledgeCard(
            cardId: 'knowledge-1',
            cardNamespace: 'project.rules',
            cardType: 'world_rule',
            title: '月蚀规则',
            summary: '月蚀后角色记忆不会重置。',
            contentPayload: const <String, Object?>{
              'fact': '主角会保留记忆',
              'note': '不要让旁白直接解释原因',
            },
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.normal,
              preferredBudgetChars: 80,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.88,
            lifecycleStatus: InformationLifecycleStatuses.accepted,
          ),
        );
        await designElementRepository.appendDesignElement(
          project,
          DesignElementCard(
            designId: 'design-1',
            designNamespace: 'project.symbol',
            designLabel: '镜潮回扣',
            designPayload: const <String, Object?>{'pattern': '镜与潮在章首章尾回扣'},
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.pinned,
              preferredBudgetChars: 180,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.91,
            lifecycleStatus: InformationLifecycleStatuses.proposed,
          ),
        );
        await researchNoteRepository.appendResearchNote(
          project,
          const ResearchNote(
            researchId: 'research-1',
            query: '镜潮互文',
            sourceKind: 'gateway_search',
            sourceUrlOrRef: 'https://example.com/mirror-tide',
            citation: 'Mirror Tide',
            summary: '镜与潮常共同承担身份映照。',
            usableFacts: <Object?>['镜与潮常共同承担身份映照'],
            createdBy: 'researcher-agent',
            usagePolicy: InformationUsagePolicy(
              usageMode: InformationUsageModes.referenceOnly,
              citationRiskLevel: InformationCitationRiskLevels.normal,
            ),
            metadata: <String, Object?>{'preferred_budget_chars': 90},
          ),
        );
        await referenceWorkRepository.appendReferenceWork(
          project,
          ReferenceWorkRecord(
            referenceWorkId: 'reference-1',
            title: '潮镜原典',
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            relationshipToProject: 'inspiration_reference',
            declaredUsageIntent: '只吸收意象边界',
            allowedUsageSummary: '不直接复写剧情与段落。',
            requiresConfirmation: true,
          ),
        );

        final items = await service.buildItems(
          project,
          taskType: 'chapter_draft',
        );

        expect(
          items.map((item) => item.source),
          containsAll(<String>[
            'project_knowledge_card',
            'project_design_element',
            'project_research_note',
            'project_reference_work',
          ]),
        );
        final knowledgeItem = items.singleWhere(
          (item) => item.itemId == 'knowledge:knowledge-1',
        );
        final designItem = items.singleWhere(
          (item) => item.itemId == 'design:design-1',
        );
        final researchItem = items.singleWhere(
          (item) => item.itemId == 'research:research-1',
        );
        final referenceItem = items.singleWhere(
          (item) => item.itemId == 'reference:reference-1',
        );

        expect(
          ValueReaders.boolValue(
            knowledgeItem.metadata['activation_text_policy_clipped'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.intValue(
            knowledgeItem.metadata['preferred_budget_chars'],
          ),
          80,
        );
        expect(
          ValueReaders.mapList(knowledgeItem.metadata['source_refs']),
          isNotEmpty,
        );
        expect(
          designItem.activationReasons,
          contains(ContextActivationReasonCodes.manualPin),
        );
        expect(
          ValueReaders.mapList(designItem.metadata['source_refs']),
          isNotEmpty,
        );
        expect(
          ValueReaders.stringValue(
            researchItem.metadata['activation_priority'],
          ),
          InformationActivationPriorities.reference,
        );
        expect(
          ValueReaders.stringValue(researchItem.metadata['source_url_or_ref']),
          'https://example.com/mirror-tide',
        );
        expect(referenceItem.reasonDetails['required'], isTrue);
        expect(
          ValueReaders.mapList(referenceItem.metadata['source_refs']),
          isNotEmpty,
        );
      },
    );
  });
}

InformationSourceRef _sourceRef() {
  return const InformationSourceRef(
    sourceRef: NarrativeSourceRef(
      sourceType: NarrativeSourceTypes.user,
      sourceId: 'information-source-1',
      label: 'user',
    ),
    sourceAuthority: InformationSourceAuthorities.userDeclared,
    roleAuthority: InformationRoleAuthorities.user,
    researchDepth: InformationResearchDepths.none,
  );
}
