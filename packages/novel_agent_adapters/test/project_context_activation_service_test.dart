import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectContextActivationService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late LocalNarrativeProfileRepository profileRepository;
    late LocalNarrativeClaimRepository claimRepository;
    late LocalConstraintBindingRepository bindingRepository;
    late LocalKnowledgeCardRepository knowledgeCardRepository;
    late LocalDesignElementRepository designElementRepository;
    late LocalResearchNoteRepository researchNoteRepository;
    late LocalReferenceWorkRepository referenceWorkRepository;
    late ProjectContextActivationService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-context-activation-',
      );
      workspacePort = LocalProjectWorkspacePort();
      profileRepository = LocalNarrativeProfileRepository(
        workspacePort: workspacePort,
      );
      claimRepository = LocalNarrativeClaimRepository(
        workspacePort: workspacePort,
      );
      bindingRepository = LocalConstraintBindingRepository(
        workspacePort: workspacePort,
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
      project = ProjectDescriptor(
        id: 'project_1',
        name: '上下文桥接测试',
        rootPath: tempDirectory.path,
      );
      service = ProjectContextActivationService(
        workspacePort: workspacePort,
        profileRepository: profileRepository,
        claimRepository: claimRepository,
        bindingRepository: bindingRepository,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'buildPlan converts project files and structured sources into activation candidates',
      () async {
        await _writeFile(
          tempDirectory.path,
          'specs/story_rules.md',
          '设定规则：所有角色都必须记住月蚀之夜发生的事。',
        );
        await _writeFile(
          tempDirectory.path,
          'outlines/story/main_outline.md',
          '第一卷大纲：主角在遗迹中发现自我循环的证据。',
        );
        await profileRepository.appendProfile(
          project,
          NarrativeProfile(
            profileId: 'hero',
            profileNamespace: 'character',
            profileLabel: '主角',
            lifecycleStatus: NarrativeProfileLifecycleStatus.accepted,
            profilePayload: const <String, Object?>{
              'goal': '打破循环',
              'fear': '再次失去同伴',
            },
            profileExtensions: const <String, Object?>{'pinned': true},
            source: _source(),
            confidence: 0.97,
          ),
        );
        await claimRepository.appendClaim(
          project,
          NarrativeStateClaim(
            claimId: 'claim-eclipse',
            claimNamespace: 'continuity',
            claimLabel: '月蚀记忆一致',
            claimPayload: const <String, Object?>{'fact': '所有核心角色保留上一轮记忆'},
            contextRefs: const <NarrativeRef>[
              NarrativeRef(
                refType: NarrativeRefTypes.chapter,
                refId: 'chapter-12',
                relativePath: 'chapters/chapter_12.md',
                displayName: '第12章',
              ),
            ],
            source: _source(),
            confidence: 0.91,
          ),
        );
        await bindingRepository.appendBinding(
          project,
          NarrativeConstraintBindingProposal(
            bindingId: 'constraint-style',
            constraintType: 'style_rule',
            constraintLabel: '禁止全知旁白',
            constraintPayload: const <String, Object?>{
              'forbidden_patterns': <Object?>['作者解释', '全知上帝视角'],
            },
            scope: const ConstraintBindingScope(appliesTo: <String>['draft']),
            policy: const ConstraintBindingPolicy(
              requiresUserConfirmation: true,
            ),
            source: _source(),
            reason: '保持沉浸感',
          ),
        );
        await knowledgeCardRepository.appendKnowledgeCard(
          project,
          ProjectKnowledgeCard(
            cardId: 'knowledge-loop-rule',
            cardNamespace: 'project.rules',
            cardType: 'world_rule',
            title: '轮回规则',
            summary: '钟楼轮回每次都会在钟声前十五分钟重置。',
            contentPayload: const <String, Object?>{'fact': '主角会在钟楼轮回重置时保留记忆'},
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.required,
              preferredBudgetChars: 220,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.93,
            lifecycleStatus: InformationLifecycleStatuses.accepted,
          ),
        );
        await designElementRepository.appendDesignElement(
          project,
          DesignElementCard(
            designId: 'design-mirror-tide',
            designNamespace: 'project.symbol',
            designLabel: '镜潮回扣',
            designPayload: const <String, Object?>{'pattern': '镜与潮在章首章尾形成呼应'},
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            scopeRefs: const <NarrativeRef>[
              NarrativeRef(
                refType: NarrativeRefTypes.chapter,
                refId: 'chapter-01',
                relativePath: 'chapters/chapter_01.md',
                displayName: '第1章',
              ),
            ],
            linkedRefs: const <NarrativeRef>[
              NarrativeRef(
                refType: NarrativeRefTypes.chapter,
                refId: 'chapter-02',
                relativePath: 'chapters/chapter_02.md',
                displayName: '第2章',
              ),
            ],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.pinned,
              preferredBudgetChars: 240,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.82,
            lifecycleStatus: InformationLifecycleStatuses.proposed,
          ),
        );
        await researchNoteRepository.appendResearchNote(
          project,
          const ResearchNote(
            researchId: 'research-mirror-tide',
            query: '镜潮母题',
            sourceKind: 'gateway_search',
            sourceUrlOrRef: 'https://example.com/mirror-tide',
            citation: 'Mirror Tide Motif',
            summary: '镜与潮共同承担身份映照与命运回声。',
            usableFacts: <Object?>[
              '镜与潮常共同承担身份映照',
              <String, Object?>{'symbol': '潮声', 'function': '回声提示'},
            ],
            creativeSuggestions: <Object?>['可用于章节标题'],
            createdBy: 'researcher-agent',
            linkedCards: <NarrativeRef>[
              NarrativeRef(
                refType: InformationLinkedRefTypes.designElement,
                refId: 'design-mirror-tide',
              ),
            ],
            usagePolicy: InformationUsagePolicy(
              usageMode: InformationUsageModes.referenceOnly,
              citationRiskLevel: InformationCitationRiskLevels.normal,
            ),
          ),
        );
        await referenceWorkRepository.appendReferenceWork(
          project,
          ReferenceWorkRecord(
            referenceWorkId: 'reference-book-1',
            title: '潮镜原典',
            creator: '匿名作者',
            version: '第一版',
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            relationshipToProject: 'inspiration_reference',
            declaredUsageIntent: '只保留意象边界，不直接复写剧情',
            allowedUsageSummary: '允许吸收象征系统，不允许直接搬运段落。',
            riskNotes: <Object?>['禁止直接复用原文句子'],
            requiresConfirmation: true,
          ),
        );

        final plan = await service.buildPlan(
          project: project,
          taskType: 'chapter_draft',
          maxFiles: 4,
          pinnedRelativePaths: const <String>['specs/story_rules.md'],
        );

        expect(plan.items, isNotEmpty);
        expect(
          plan.items.map((item) => item.source),
          containsAll(<String>[
            'project_file',
            'narrative_profile',
            'narrative_claim',
            'narrative_constraint',
            'project_knowledge_card',
            'project_design_element',
            'project_research_note',
            'project_reference_work',
          ]),
        );
        final fileItem = plan.items.singleWhere(
          (item) => item.itemId == 'file:specs/story_rules.md',
        );
        final profileItem = plan.items.singleWhere(
          (item) => item.itemId == 'profile:hero',
        );
        final claimItem = plan.items.singleWhere(
          (item) => item.itemId == 'claim:claim-eclipse',
        );
        final constraintItem = plan.items.singleWhere(
          (item) => item.itemId == 'constraint:constraint-style',
        );
        final knowledgeItem = plan.items.singleWhere(
          (item) => item.itemId == 'knowledge:knowledge-loop-rule',
        );
        final designItem = plan.items.singleWhere(
          (item) => item.itemId == 'design:design-mirror-tide',
        );
        final researchItem = plan.items.singleWhere(
          (item) => item.itemId == 'research:research-mirror-tide',
        );
        final referenceItem = plan.items.singleWhere(
          (item) => item.itemId == 'reference:reference-book-1',
        );

        expect(
          fileItem.activationReasons,
          contains(ContextActivationReasonCodes.manualPin),
        );
        expect(
          ValueReaders.stringValue(fileItem.metadata['relative_path']),
          'specs/story_rules.md',
        );
        expect(
          profileItem.activationReasons,
          contains(ContextActivationReasonCodes.profilePolicy),
        );
        expect(
          ValueReaders.stringValue(profileItem.metadata['profile_namespace']),
          'character',
        );
        expect(claimItem.refs.single.relativePath, 'chapters/chapter_12.md');
        expect(constraintItem.reasonDetails['required'], isTrue);
        expect(knowledgeItem.reasonDetails['required'], isTrue);
        expect(
          designItem.activationReasons,
          contains(ContextActivationReasonCodes.manualPin),
        );
        expect(
          ValueReaders.stringValue(designItem.metadata['source_kind']),
          'project_design_element',
        );
        expect(
          ValueReaders.stringValue(
            researchItem.metadata['activation_priority'],
          ),
          InformationActivationPriorities.reference,
        );
        expect(referenceItem.reasonDetails['required'], isTrue);
        expect(
          ValueReaders.mapValue(plan.metadata['candidate_source_counts']),
          <String, Object?>{
            'project_file': 2,
            'narrative_profile': 1,
            'narrative_claim': 1,
            'narrative_constraint': 1,
            'project_knowledge_card': 1,
            'project_design_element': 1,
            'project_research_note': 1,
            'project_reference_work': 1,
          },
        );
      },
    );

    test(
      'buildReport exposes selected omitted and truncated sections with visible budget trimming',
      () async {
        await _writeFile(
          tempDirectory.path,
          'specs/core_rules.md',
          '核心规则：每次轮回结束后，主角会回到钟楼苏醒。'
              '这个设定不可被遗忘，也不可由旁白直接解释。',
        );
        await claimRepository.appendClaim(
          project,
          NarrativeStateClaim(
            claimId: 'claim-heavy',
            claimNamespace: 'continuity',
            claimLabel: '轮回规则补充',
            claimPayload: const <String, Object?>{
              'details':
                  '这是一个很长的说明，用来制造预算裁剪效果。'
                  '主角必须记住三次失败、两次背叛和一次失控。'
                  '每次轮回都会在钟声响起前十五分钟重置。'
                  '任何旁人都不知道重置已经发生。',
            },
            source: _source(),
            confidence: 0.88,
          ),
        );
        await knowledgeCardRepository.appendKnowledgeCard(
          project,
          ProjectKnowledgeCard(
            cardId: 'knowledge-core-rule',
            cardNamespace: 'project.rules',
            cardType: 'world_rule',
            title: '钟楼轮回核心规则',
            summary: '轮回重置前十五分钟的记忆必须连续。',
            contentPayload: const <String, Object?>{
              'rule': '每次重置都会保留主角记忆',
              'note': '旁白不可直接解释轮回机制',
            },
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.required,
              preferredBudgetChars: 100,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.95,
            lifecycleStatus: InformationLifecycleStatuses.accepted,
          ),
        );
        await designElementRepository.appendDesignElement(
          project,
          DesignElementCard(
            designId: 'design-selected',
            designNamespace: 'project.symbol',
            designLabel: '钟声回扣',
            designPayload: const <String, Object?>{
              'pattern': '章首钟声与章尾钟声形成闭环',
              'effect': '制造宿命感',
            },
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            linkedRefs: const <NarrativeRef>[
              NarrativeRef(
                refType: NarrativeRefTypes.chapter,
                refId: 'chapter-03',
                relativePath: 'chapters/chapter_03.md',
                displayName: '第3章',
              ),
            ],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.pinned,
              preferredBudgetChars: 120,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.9,
            lifecycleStatus: InformationLifecycleStatuses.accepted,
          ),
        );
        await researchNoteRepository.appendResearchNote(
          project,
          const ResearchNote(
            researchId: 'research-truncated',
            query: '钟楼回声母题',
            sourceKind: 'gateway_search',
            sourceUrlOrRef: 'https://example.com/belltower-echo',
            citation: 'Belltower Echo',
            summary:
                '这是一个偏长的研究摘要，用来配合 activation planner 制造 information source 的预算裁剪效果。'
                '它说明钟声如何反复触发人物记忆、预示循环闭环，并给出可追踪来源。',
            usableFacts: <Object?>[
              '钟声可作为轮回重置触发物',
              '回声常用于提示未被说出的真相',
              <String, Object?>{'symbol': '钟楼', 'effect': '命运闭环'},
            ],
            creativeSuggestions: <Object?>['在章末重复钟声意象'],
            createdBy: 'researcher-agent',
            usagePolicy: InformationUsagePolicy(
              usageMode: InformationUsageModes.referenceOnly,
              citationRiskLevel: InformationCitationRiskLevels.normal,
            ),
            metadata: <String, Object?>{'preferred_budget_chars': 120},
          ),
        );
        await referenceWorkRepository.appendReferenceWork(
          project,
          ReferenceWorkRecord(
            referenceWorkId: 'reference-omitted',
            title: '钟楼异闻录',
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            relationshipToProject: 'atmosphere_reference',
            declaredUsageIntent: '只参考氛围，不进入正文事实',
            allowedUsageSummary: '可参考情绪，不直接借用角色与剧情。',
            riskNotes: <Object?>['仅作边界提醒'],
            requiresConfirmation: false,
            metadata: <String, Object?>{
              'activation_priority': InformationActivationPriorities.background,
            },
          ),
        );

        final report = await service.buildReport(
          project: project,
          taskType: 'chapter_draft',
          budgetChars: 420,
          reservedOutputChars: 120,
          maxFiles: 3,
        );

        expect(report.budgetChars, 300);
        expect(report.selectedItemIds, isNotEmpty);
        expect(report.truncatedItemIds, isNotEmpty);
        expect(report.omittedItemIds, isNotEmpty);

        final truncatedItems = report.items
            .where((item) => item.truncated)
            .toList(growable: false);
        final omittedItems = report.items
            .where((item) => item.omitted)
            .toList(growable: false);
        final truncatedItem = truncatedItems.first;
        final omittedItem = omittedItems.first;
        final selectedSections = ValueReaders.mapList(
          report.metadata['selected_context_sections'],
        );
        final omittedSections = ValueReaders.mapList(
          report.metadata['omitted_context_sections'],
        );
        final truncatedSections = ValueReaders.mapList(
          report.metadata['truncated_context_sections'],
        );
        final designItem = report.items.singleWhere(
          (item) => item.itemId == 'design:design-selected',
        );
        final researchItem = report.items.singleWhere(
          (item) => item.itemId == 'research:research-truncated',
        );
        final referenceItem = report.items.singleWhere(
          (item) => item.itemId == 'reference:reference-omitted',
        );

        expect(
          ValueReaders.stringValue(
            truncatedItem.metadata['selected_text'],
          ).length,
          truncatedItem.includedChars,
        );
        expect(
          ValueReaders.intValue(truncatedItem.metadata['trimmed_chars']) > 0,
          isTrue,
        );
        expect(
          ValueReaders.stringValue(truncatedItem.metadata['explanation']),
          contains('Selected with'),
        );
        expect(
          ValueReaders.stringValue(omittedItem.metadata['explanation']),
          contains('Omitted because'),
        );
        expect(
          truncatedItems.every(
            (item) => ValueReaders.stringValue(
              item.metadata['explanation'],
            ).contains('Selected with'),
          ),
          isTrue,
        );
        expect(
          omittedItems.every(
            (item) => ValueReaders.stringValue(
              item.metadata['explanation'],
            ).contains('Omitted because'),
          ),
          isTrue,
        );
        expect(
          selectedSections.map(
            (entry) => ValueReaders.stringValue(entry['item_id']),
          ),
          containsAll(report.selectedItemIds),
        );
        expect(
          omittedSections.map(
            (entry) => ValueReaders.stringValue(entry['item_id']),
          ),
          containsAll(report.omittedItemIds),
        );
        expect(
          truncatedSections.map(
            (entry) => ValueReaders.stringValue(entry['item_id']),
          ),
          containsAll(report.truncatedItemIds),
        );
        expect(designItem.selected, isTrue);
        expect(
          ValueReaders.stringValue(designItem.metadata['source_kind']),
          'project_design_element',
        );
        expect(researchItem.truncated, isTrue);
        expect(
          ValueReaders.stringValue(researchItem.metadata['selected_text']),
          isNotEmpty,
        );
        expect(referenceItem.omitted, isTrue);
        expect(
          selectedSections.any(
            (entry) =>
                ValueReaders.stringValue(entry['item_id']) ==
                'design:design-selected',
          ),
          isTrue,
        );
        expect(
          truncatedSections.any(
            (entry) =>
                ValueReaders.stringValue(entry['item_id']) ==
                'research:research-truncated',
          ),
          isTrue,
        );
        expect(
          omittedSections.any(
            (entry) =>
                ValueReaders.stringValue(entry['item_id']) ==
                'reference:reference-omitted',
          ),
          isTrue,
        );
        expect(report.summary, contains('selected profiles'));
        expect(report.summary, contains('design'));
      },
    );
  });
}

Future<void> _writeFile(
  String rootPath,
  String relativePath,
  String content,
) async {
  final normalizedPath = relativePath.replaceAll('/', Platform.pathSeparator);
  final file = File('$rootPath${Platform.pathSeparator}$normalizedPath');
  await file.parent.create(recursive: true);
  await file.writeAsString(content, flush: true);
}

NarrativeSourceRef _source() {
  return const NarrativeSourceRef(
    sourceType: 'tool_call',
    sourceId: 'source-1',
    label: 'tool',
  );
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
