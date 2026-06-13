import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectInformationActivationBridgeService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late KnowledgeCardRepository knowledgeCardRepository;
    late DesignElementRepository designElementRepository;
    late ResearchNoteRepository researchNoteRepository;
    late ReferenceWorkRepository referenceWorkRepository;
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
      knowledgeCardRepository = SqliteKnowledgeCardRepository();
      designElementRepository = SqliteDesignElementRepository();
      researchNoteRepository = SqliteResearchNoteRepository();
      referenceWorkRepository = SqliteReferenceWorkRepository();
      service = ProjectInformationActivationBridgeService(
        workspacePort: workspacePort,
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
            evidenceRefs: const <NarrativeEvidenceRef>[
              NarrativeEvidenceRef(
                evidenceType: 'reference_excerpt',
                evidenceId: 'knowledge-evidence-1',
                summary: '月蚀回忆段落摘录',
              ),
            ],
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
            evidenceRefs: const <NarrativeEvidenceRef>[
              NarrativeEvidenceRef(
                evidenceType: 'design_note',
                evidenceId: 'design-evidence-1',
                summary: '镜潮设计草图',
              ),
            ],
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
          ValueReaders.mapList(knowledgeItem.metadata['evidence_refs']),
          isNotEmpty,
        );
        expect(
          knowledgeItem.targetPath,
          'project-information://knowledge_cards/knowledge-1',
        );
        expect(
          ValueReaders.stringValue(
            knowledgeItem.metadata['source_of_truth_locator'],
          ),
          'project-information://knowledge_cards/knowledge-1',
        );
        expect(
          ValueReaders.stringValue(knowledgeItem.metadata['source_display']),
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
          ValueReaders.mapList(designItem.metadata['evidence_refs']),
          isNotEmpty,
        );
        expect(
          designItem.targetPath,
          'project-information://design_elements/design-1',
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
        expect(
          ValueReaders.stringValue(researchItem.metadata['source_display']),
          'Mirror Tide',
        );
        expect(referenceItem.reasonDetails['required'], isFalse);
        expect(
          ValueReaders.mapList(referenceItem.metadata['source_refs']),
          isNotEmpty,
        );
        final referenceActivationText = ValueReaders.stringValue(
          referenceItem.metadata['activation_text'],
        );
        expect(referenceActivationText, contains('source_display:'));
        expect(referenceActivationText, contains('source_ref_count: 1'));
        expect(referenceActivationText, isNot(contains('source_refs:')));
        expect(
          ValueReaders.stringValue(
            referenceItem.metadata['source_of_truth_locator'],
          ),
          'project-information://reference_works/reference-1',
        );
        expect(
          File(
            '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}knowledge_cards${Platform.pathSeparator}knowledge-1.json',
          ).existsSync(),
          isFalse,
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
