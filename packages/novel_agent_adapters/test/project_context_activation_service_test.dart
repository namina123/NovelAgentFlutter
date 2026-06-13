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
    late LocalNarrativeLedgerRepository ledgerRepository;
    late LocalConstraintBindingRepository bindingRepository;
    late KnowledgeCardRepository knowledgeCardRepository;
    late DesignElementRepository designElementRepository;
    late ResearchNoteRepository researchNoteRepository;
    late ReferenceWorkRepository referenceWorkRepository;
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
      ledgerRepository = LocalNarrativeLedgerRepository(
        workspacePort: workspacePort,
      );
      bindingRepository = LocalConstraintBindingRepository(
        workspacePort: workspacePort,
      );
      knowledgeCardRepository = SqliteKnowledgeCardRepository();
      designElementRepository = SqliteDesignElementRepository();
      researchNoteRepository = SqliteResearchNoteRepository();
      referenceWorkRepository = SqliteReferenceWorkRepository();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '上下文桥接测试',
        rootPath: tempDirectory.path,
      );
      service = ProjectContextActivationService(
        workspacePort: workspacePort,
        profileRepository: profileRepository,
        claimRepository: claimRepository,
        ledgerRepository: ledgerRepository,
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
        await ledgerRepository.appendLedgerEntry(
          project,
          NarrativeLedgerEntry(
            entryId: 'entry-claim-eclipse',
            claim: NarrativeStateClaim(
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
            disposition: NarrativeClaimDisposition.accepted,
            source: _source(),
          ),
          ledgerId: 'main-ledger',
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
            evidenceRefs: const <NarrativeEvidenceRef>[
              NarrativeEvidenceRef(
                evidenceType: 'chapter_excerpt',
                evidenceId: 'knowledge-evidence-1',
                summary: '钟楼轮回证据段落',
              ),
            ],
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
            evidenceRefs: const <NarrativeEvidenceRef>[
              NarrativeEvidenceRef(
                evidenceType: 'design_excerpt',
                evidenceId: 'design-evidence-1',
                summary: '镜潮呼应证据',
              ),
            ],
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
          (item) =>
              ValueReaders.stringValue(item.metadata['claim_id']) ==
                  'claim-eclipse' &&
              item.source == 'narrative_claim',
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
        expect(
          ValueReaders.stringValue(claimItem.metadata['source_kind']),
          'narrative_claim',
        );
        expect(
          ValueReaders.stringValue(claimItem.metadata['truth_status']),
          'formal_ledger',
        );
        expect(
          ValueReaders.stringValue(
            claimItem.metadata['source_of_truth_locator'],
          ),
          '.novel_agent/continuity/ledgers/main-ledger/entries.jsonl#entry-claim-eclipse',
        );
        expect(constraintItem.reasonDetails['required'], isTrue);
        expect(knowledgeItem.reasonDetails['required'], isTrue);
        expect(
          knowledgeItem.targetPath,
          'project-information://knowledge_cards/knowledge-loop-rule',
        );
        expect(
          ValueReaders.stringValue(
            knowledgeItem.metadata['source_of_truth_locator'],
          ),
          'project-information://knowledge_cards/knowledge-loop-rule',
        );
        expect(
          ValueReaders.mapList(knowledgeItem.metadata['evidence_refs']),
          isNotEmpty,
        );
        expect(
          designItem.activationReasons,
          contains(ContextActivationReasonCodes.manualPin),
        );
        expect(
          ValueReaders.stringValue(designItem.metadata['source_kind']),
          'project_design_element',
        );
        expect(
          ValueReaders.mapList(designItem.metadata['evidence_refs']),
          isNotEmpty,
        );
        expect(
          ValueReaders.stringValue(
            researchItem.metadata['activation_priority'],
          ),
          InformationActivationPriorities.reference,
        );
        expect(referenceItem.reasonDetails['required'], isFalse);
        expect(
          File(
            '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}knowledge_cards${Platform.pathSeparator}knowledge-loop-rule.json',
          ).existsSync(),
          isFalse,
        );
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
      'buildPlan downgrades raw claim submissions and hides rejected ledger entries from formal truth candidates',
      () async {
        await claimRepository.appendClaim(
          project,
          NarrativeStateClaim(
            claimId: 'claim-accepted',
            claimNamespace: 'continuity',
            claimLabel: '正式状态',
            claimPayload: const <String, Object?>{'fact': '已确认事实'},
            source: _source(),
            confidence: 0.95,
          ),
        );
        await claimRepository.appendClaim(
          project,
          NarrativeStateClaim(
            claimId: 'claim-pending',
            claimNamespace: 'continuity',
            claimLabel: '待裁决状态',
            claimPayload: const <String, Object?>{'fact': '尚待确认'},
            source: _source(),
            confidence: 0.6,
          ),
        );
        await claimRepository.appendClaim(
          project,
          NarrativeStateClaim(
            claimId: 'claim-rejected',
            claimNamespace: 'continuity',
            claimLabel: '已否决状态',
            claimPayload: const <String, Object?>{'fact': '已否决'},
            source: _source(),
            confidence: 0.4,
          ),
        );
        await ledgerRepository.appendLedgerEntry(
          project,
          NarrativeLedgerEntry(
            entryId: 'entry-accepted',
            claim: NarrativeStateClaim(
              claimId: 'claim-accepted',
              claimNamespace: 'continuity',
              claimLabel: '正式状态',
              claimPayload: const <String, Object?>{'fact': '已确认事实'},
              source: _source(),
              confidence: 0.95,
            ),
            disposition: NarrativeClaimDisposition.accepted,
            source: _source(),
          ),
          ledgerId: 'main-ledger',
        );
        await ledgerRepository.appendLedgerEntry(
          project,
          NarrativeLedgerEntry(
            entryId: 'entry-rejected',
            claim: NarrativeStateClaim(
              claimId: 'claim-rejected',
              claimNamespace: 'continuity',
              claimLabel: '已否决状态',
              claimPayload: const <String, Object?>{'fact': '已否决'},
              source: _source(),
              confidence: 0.4,
            ),
            disposition: NarrativeClaimDisposition.rejected,
            source: _source(),
          ),
          ledgerId: 'main-ledger',
        );

        final plan = await service.buildPlan(project: project);

        final acceptedItem = plan.items.singleWhere(
          (item) =>
              ValueReaders.stringValue(item.metadata['claim_id']) ==
                  'claim-accepted' &&
              item.source == 'narrative_claim',
        );
        final pendingItem = plan.items.singleWhere(
          (item) =>
              ValueReaders.stringValue(item.metadata['claim_id']) ==
                  'claim-pending' &&
              item.source == 'narrative_claim_submission',
        );

        expect(
          ValueReaders.stringValue(acceptedItem.metadata['truth_status']),
          'formal_ledger',
        );
        expect(
          ValueReaders.stringValue(pendingItem.metadata['truth_status']),
          'submission_log',
        );
        expect(
          ValueReaders.stringValue(
            pendingItem.metadata['source_of_truth_locator'],
          ),
          '.novel_agent/continuity/claims/claims.jsonl#claim-pending',
        );
        expect(
          plan.items.where(
            (item) =>
                ValueReaders.stringValue(item.metadata['claim_id']) ==
                'claim-rejected',
          ),
          isEmpty,
        );
        expect(
          ValueReaders.mapValue(plan.metadata['candidate_source_counts']),
          <String, Object?>{
            'narrative_claim': 1,
            'narrative_claim_submission': 1,
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
            evidenceRefs: const <NarrativeEvidenceRef>[
              NarrativeEvidenceRef(
                evidenceType: 'design_excerpt',
                evidenceId: 'design-selected-evidence-1',
                summary: '钟声回扣证据',
              ),
            ],
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
        final designSection = selectedSections.firstWhere(
          (entry) =>
              ValueReaders.stringValue(entry['item_id']) ==
              'design:design-selected',
        );
        expect(
          ValueReaders.stringValue(designSection['source_of_truth_locator']),
          'project-information://design_elements/design-selected',
        );
        expect(
          ValueReaders.stringValue(designSection['source_display']),
          isNotEmpty,
        );
        expect(ValueReaders.mapList(designSection['source_refs']), isNotEmpty);
        expect(
          ValueReaders.mapList(designSection['evidence_refs']),
          isNotEmpty,
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

    test(
      'buildReport prioritizes recent chapter handoff assets for focused chapter execution',
      () async {
        await _writeFile(
          tempDirectory.path,
          'premise/project_brief.md',
          '项目简介：一个需要长期保持章节衔接的故事。',
        );
        await _writeFile(
          tempDirectory.path,
          'specs/project_spec.md',
          '规格：正文必须承接上一章状态继续推进。',
        );
        await _writeFile(
          tempDirectory.path,
          'styles/seed_autopilot_style.md',
          '风格：保持口吻连续。',
        );
        await _writeFile(
          tempDirectory.path,
          'outlines/story/总纲.md',
          '总纲：主角在小镇站稳脚跟。',
        );
        await _writeFile(
          tempDirectory.path,
          'outlines/chapters/章节任务清单.md',
          '第02章：探镇。第03章：落脚。',
        );
        await _writeFile(
          tempDirectory.path,
          'world/seed_autopilot_world_anchor.md',
          '世界锚点：明代江南小镇。',
        );
        await _writeFile(
          tempDirectory.path,
          'assets/characters/protagonist_lu_an.md',
          '主角卡：陆安，刚刚进入小镇。',
        );
        await _writeFile(
          tempDirectory.path,
          'summaries/第02章摘要：找到落脚处.summary.md',
          '第02章摘要：陆安找到王保正家，已经敲门并开口询问落户之事。',
        );
        await _writeFile(
          tempDirectory.path,
          'assets/timeline/第02章_探镇.timeline.md',
          '第02章时间线：陆安在章末已经站到王保正面前并提出落户问题。',
        );
        await _writeFile(
          tempDirectory.path,
          'chapters/第02章_探镇.md',
          '# 第02章\n\n前文铺垫。\n\n王保正家的门终于开了。陆安把冻僵的手缩回袖里，先把准备好的说辞咽了一遍，又盯住门槛里那双旧布鞋。那人没让他进门，只站在门内问他是哪来的。陆安知道自己已经站到这一步，不能再退回去装糊涂，于是把“想在镇上寻个落脚处、愿意先做粗活换口饭”这句话慢慢说了出来。门里的人没立刻答，先把他从头到脚看了一遍。巷口的风钻进来，吹得门板吱呀一响。陆安没再补话，只等着对方开口。',
        );
        await _writeFile(
          tempDirectory.path,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章_探镇.md.json',
          '{"submission":{"summary":"第02章交付：章末已到王保正门前并发问。","final_state_summary":{"location":"王保正家门口","active_goal":"争取一个能暂时落脚的机会","next_chapter_handoff":"从王保正的回应继续，不要回退到寻路或敲门前。"}}}',
        );

        final report = await service.buildReport(
          project: project,
          taskType: 'chapter',
          chapterLabel: '第03章',
          budgetChars: 2600,
          reservedOutputChars: 200,
          maxFiles: 5,
          pinnedRelativePaths: const <String>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ],
        );

        final selectedIds = report.selectedItemIds;
        final summaryId = 'file:summaries/第02章摘要：找到落脚处.summary.md';
        final timelineId = 'file:assets/timeline/第02章_探镇.timeline.md';
        final deliveryId =
            'file:.novel_agent/continuity/deliveries/submission_chapters_第02章_探镇.md.json';
        final continuationPointId = 'chapter_tail:chapters/第02章_探镇.md';
        final specId = 'file:specs/project_spec.md';

        expect(selectedIds, contains(summaryId));
        expect(selectedIds, contains(timelineId));
        expect(selectedIds, contains(deliveryId));
        expect(selectedIds, contains(continuationPointId));
        expect(
          selectedIds.indexOf(summaryId),
          lessThan(selectedIds.indexOf(specId)),
        );
        expect(
          selectedIds.indexOf(timelineId),
          lessThan(selectedIds.indexOf(specId)),
        );
        expect(
          selectedIds.indexOf(deliveryId),
          lessThan(selectedIds.indexOf(specId)),
        );
        expect(
          selectedIds.indexOf(continuationPointId),
          lessThan(selectedIds.indexOf(specId)),
        );
        final selectedSections = ValueReaders.mapList(
          report.metadata['selected_context_sections'],
        );
        final deliverySection = selectedSections.firstWhere(
          (entry) => ValueReaders.stringValue(entry['item_id']) == deliveryId,
        );
        final continuationSection = selectedSections.firstWhere(
          (entry) =>
              ValueReaders.stringValue(entry['item_id']) == continuationPointId,
        );
        expect(
          ValueReaders.stringValue(deliverySection['selected_text']),
          contains('上一章已完成剧情（不要重复重演）'),
        );
        expect(
          ValueReaders.stringValue(deliverySection['selected_text']),
          contains('从王保正的回应继续'),
        );
        expect(
          ValueReaders.stringValue(continuationSection['selected_text']),
          contains('优先承接锚点：从王保正的回应继续'),
        );
      },
    );

    test(
      'buildReport applies chapter handoff assets to continuation writing tasks beyond raw chapter type',
      () async {
        await _writeFile(
          tempDirectory.path,
          'specs/project_spec.md',
          '规格：分章续写必须承接上一章章末状态。',
        );
        await _writeFile(
          tempDirectory.path,
          'summaries/第02章：摸底.summary.md',
          '第02章摘要：章末已经把落脚请求说出口，下一章应直接承接回应。',
        );
        await _writeFile(
          tempDirectory.path,
          'assets/timeline/第02章_摸底.timeline.md',
          '第02章时间线：王保正已经开门，陆安已说明来意。',
        );
        await _writeFile(
          tempDirectory.path,
          'chapters/第02章_摸底.md',
          '# 第02章\n\n陆安把话说完，只等门里的人给一句回音。',
        );
        await _writeFile(
          tempDirectory.path,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章_摸底.md.json',
          '{"submission":{"summary":"第02章交付：章末已提出落脚请求。","final_state_summary":{"next_chapter_handoff":"直接从对方回应继续。"}}}',
        );

        final report = await service.buildReport(
          project: project,
          taskType: 'book_deconstruction_continuation',
          chapterLabel: '第03章',
          budgetChars: 2600,
          reservedOutputChars: 200,
          maxFiles: 4,
          pinnedRelativePaths: const <String>['specs/project_spec.md'],
        );

        expect(
          report.selectedItemIds,
          containsAll(<String>[
            'file:summaries/第02章：摸底.summary.md',
            'file:assets/timeline/第02章_摸底.timeline.md',
            'file:.novel_agent/continuity/deliveries/submission_chapters_第02章_摸底.md.json',
            'chapter_tail:chapters/第02章_摸底.md',
          ]),
        );
        final selectedSections = ValueReaders.mapList(
          report.metadata['selected_context_sections'],
        );
        final continuationSection = selectedSections.firstWhere(
          (entry) =>
              ValueReaders.stringValue(entry['item_id']) ==
              'chapter_tail:chapters/第02章_摸底.md',
        );
        expect(
          ValueReaders.stringValue(continuationSection['selected_text']),
          contains('优先承接锚点：直接从对方回应继续。'),
        );
      },
    );

    test(
      'buildReport recognizes Chinese chapter numerals for continuity handoff selection',
      () async {
        await _writeFile(
          tempDirectory.path,
          'summaries/第02章：摸底.summary.md',
          '第02章摘要：章末已经把落脚请求说出口，下一章应直接承接回应。',
        );
        await _writeFile(
          tempDirectory.path,
          'assets/timeline/第02章_摸底.timeline.md',
          '第02章时间线：王保正已经开门，陆安已说明来意。',
        );
        await _writeFile(
          tempDirectory.path,
          'chapters/第02章_摸底.md',
          '# 第02章\n\n陆安把话说完，只等门里的人给一句回音。',
        );
        await _writeFile(
          tempDirectory.path,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章_摸底.md.json',
          '{"submission":{"summary":"第02章交付：章末已提出落脚请求。","final_state_summary":{"next_chapter_handoff":"直接从对方回应继续。"}}}',
        );

        final report = await service.buildReport(
          project: project,
          taskType: 'chapter',
          chapterLabel: '第三章',
          budgetChars: 2400,
          reservedOutputChars: 200,
          maxFiles: 4,
        );

        expect(
          report.selectedItemIds,
          containsAll(<String>[
            'file:summaries/第02章：摸底.summary.md',
            'file:assets/timeline/第02章_摸底.timeline.md',
            'file:.novel_agent/continuity/deliveries/submission_chapters_第02章_摸底.md.json',
            'chapter_tail:chapters/第02章_摸底.md',
          ]),
        );
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
