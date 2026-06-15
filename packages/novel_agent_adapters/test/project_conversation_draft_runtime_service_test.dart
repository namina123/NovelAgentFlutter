import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectConversationDraftRuntimeService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectWorkspaceToolHostAdapter hostPort;
    late ProjectTaskRepository taskRepository;
    late KnowledgeCardRepository knowledgeCardRepository;
    late DesignElementRepository designElementRepository;
    late ExpressionConstraintProfileRepository profileRepository;
    late ProjectExpressionConstraintBindingRepository bindingRepository;
    late ProjectToolDispatcher dispatcher;
    late ProjectConversationDraftRuntimeService service;
    late ProjectDescriptor project;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-conversation-runtime-',
      );
      workspacePort = LocalProjectWorkspacePort();
      hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      knowledgeCardRepository = SqliteKnowledgeCardRepository();
      designElementRepository = SqliteDesignElementRepository();
      profileRepository = ExpressionConstraintProfileRepository(
        workspacePort: workspacePort,
      );
      bindingRepository = ProjectExpressionConstraintBindingRepository(
        workspacePort: workspacePort,
      );
      dispatcher = ProjectToolDispatcher(hostPort: hostPort);
      service = ProjectConversationDraftRuntimeService(
        workspacePort: workspacePort,
        hostPort: hostPort,
        taskRepository: taskRepository,
      );
      project = ProjectDescriptor(
        id: 'conversation_runtime_project',
        name: '普通会话项目',
        rootPath: tempDirectory.path,
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'outline/总纲.md',
        '# 总纲\n第一章是回京夜雨。',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'styles/default.md',
        '# 风格\n保持冷峻，少解释。',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'prepareDraftRun builds activation context and prioritizes submit_chapter_delivery',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );

        expect(
          preparation.activationReportPath,
          contains('conversation_draft'),
        );
        expect(
          preparation.sessionContextMarkdown,
          contains('Activation Report'),
        );
        expect(preparation.exposedToolIds.first, 'submit_chapter_delivery');
        expect(preparation.exposedToolIds, isNot(contains('set_agent_tasks')));
        expect(preparation.exposedToolIds, isNot(contains('call_sub_agent')));
      },
    );

    test(
      'prepareDraftRun hides call_sub_agent for single-member collaboration groups',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'single_agent_writer',
            'agents': <String>['writer'],
            'primary_agent_id': 'writer',
            'metadata': <String, Object?>{'derived_from_single_agent': true},
          },
        );

        expect(preparation.exposedToolIds, isNot(contains('call_sub_agent')));
        expect(
          preparation.exposedToolIds,
          contains(NarrativeDomainToolNames.submitChapterDelivery),
        );
      },
    );

    test(
      'prepareDraftRun injects information activation, keeps research request visible, and gates heavy extraction for chapter flow',
      () async {
        await knowledgeCardRepository.appendKnowledgeCard(
          project,
          ProjectKnowledgeCard(
            cardId: 'knowledge-loop-rule',
            cardNamespace: 'project.rules',
            cardType: 'world_rule',
            title: '轮回规则',
            summary: '钟楼轮回会在午夜前十五分钟重置。',
            contentPayload: const <String, Object?>{'fact': '主角会保留轮回前一轮的短时记忆'},
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.required,
              preferredBudgetChars: 220,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.92,
            lifecycleStatus: InformationLifecycleStatuses.accepted,
          ),
        );
        await designElementRepository.appendDesignElement(
          project,
          DesignElementCard(
            designId: 'design-night-rain',
            designNamespace: 'project.structure',
            designLabel: '夜雨回扣',
            designPayload: const <String, Object?>{
              'pattern': '每章夜雨都回扣角色是否选择回头',
            },
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.pinned,
              preferredBudgetChars: 220,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.81,
            lifecycleStatus: InformationLifecycleStatuses.proposed,
          ),
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final selectedSections = ValueReaders.mapList(
          ValueReaders.mapValue(
            preparation.activationReport['metadata'],
          )['selected_context_sections'],
        );
        final selectedKinds = selectedSections
            .map((item) => ValueReaders.stringValue(item['source_kind']))
            .toSet();

        expect(preparation.sessionContextMarkdown, contains('轮回规则'));
        expect(preparation.sessionContextMarkdown, contains('夜雨回扣'));
        expect(selectedKinds, contains('project_knowledge_card'));
        expect(selectedKinds, contains('project_design_element'));
        expect(
          preparation.exposedToolIds,
          contains(NarrativeDomainToolNames.requestExternalResearch),
        );
        expect(
          preparation.exposedToolIds,
          contains(NarrativeDomainToolNames.submitResearchNote),
        );
        expect(
          preparation.exposedToolIds,
          isNot(contains(NarrativeDomainToolNames.proposeKnowledgeCard)),
        );
        expect(
          preparation.exposedToolIds,
          isNot(contains(NarrativeDomainToolNames.proposeDesignElement)),
        );
        expect(
          preparation.exposedToolIds,
          isNot(contains(NarrativeDomainToolNames.linkInformationEvidence)),
        );
        expect(
          preparation.exposedToolIds,
          isNot(contains(NarrativeDomainToolNames.proposeReferenceWork)),
        );
      },
    );

    test(
      'prepareDraftRun boosts continuity assets for continuation writing when title identifies the target chapter',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'summaries/第02章摘要.summary.md',
          '# 第02章摘要\n\n陆安已经站到王保正门口，门刚打开，对方先问来意。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'assets/timeline/第02章_探镇.timeline.md',
          '# 第02章时间线\n\n- 陆安走到王保正家门外\n- 门被打开\n- 对话切入落户问题',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/第02章.md',
          '# 第02章\n\n陆安抬手时门已经从里头开了半扇。',
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'book_deconstruction_continuation',
          chapterLabelHint: '继续写第03章',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );

        final metadata = ValueReaders.mapValue(
          preparation.activationReport['metadata'],
        );
        expect(ValueReaders.stringValue(metadata['chapter_label']), '第03章');
        final selectedSections = ValueReaders.mapList(
          metadata['selected_context_sections'],
        );
        final selectedPaths = selectedSections
            .map((item) => ValueReaders.stringValue(item['target_path']))
            .toList(growable: false);

        expect(selectedPaths, contains('summaries/第02章摘要.summary.md'));
        expect(selectedPaths, contains('assets/timeline/第02章_探镇.timeline.md'));
      },
    );

    test(
      'prepareDraftRun resolves target chapter from mixed prompt that also references previous chapter',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'summaries/第02章摘要.summary.md',
          '# 第02章摘要\n\n陆安已经站到王保正门口，门刚打开，对方先问来意。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'assets/timeline/第02章_探镇.timeline.md',
          '# 第02章时间线\n\n- 陆安走到王保正家门外\n- 门被打开\n- 对话切入落户问题',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/第02章.md',
          '# 第02章\n\n陆安抬手时门已经从里头开了半扇。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章.md.json',
          '{"submission":{"summary":"第02章交付：门已经打开。","final_state_summary":{"next_chapter_handoff":"直接从门内回应继续。"}}}',
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          chapterLabelHint: '先承接当前项目里第02章章末已经落定的状态，不要回退铺垫，直接把第三章正式写出来。',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );

        final metadata = ValueReaders.mapValue(
          preparation.activationReport['metadata'],
        );
        expect(ValueReaders.stringValue(metadata['chapter_label']), '第03章');
        expect(
          ValueReaders.mapList(metadata['selected_context_sections']).any(
            (entry) =>
                ValueReaders.stringValue(entry['item_id']) ==
                'file:.novel_agent/continuity/deliveries/submission_chapters_第02章.md.json',
          ),
          isTrue,
        );
        expect(
          ValueReaders.mapList(metadata['selected_context_sections']).any(
            (entry) =>
                ValueReaders.stringValue(entry['item_id']) ==
                'chapter_tail:chapters/第02章.md',
          ),
          isTrue,
        );
      },
    );

    test(
      'prepareDraftRun surfaces continuity guard for ordinary chapter drafting when previous chapter handoff exists',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/第02章.md',
          '# 第02章\n\n陆安把来意说完，只等门里的人给一句回音。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章.md.json',
          '{"submission":{"summary":"第02章交付：章末已把落脚请求说出口。","final_state_summary":{"location":"王保正家门口","next_chapter_handoff":"直接从对方回应继续，不要重新敲门或重复自我介绍。"}}}',
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          chapterLabelHint: '继续写第03章',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final markdown = preparation.sessionContextMarkdown;

        expect(markdown, contains('## Chapter Continuity Guard'));
        expect(markdown, contains('必须直接承接上一章章末锚点：直接从对方回应继续，不要重新敲门或重复自我介绍。'));
        expect(markdown, contains('上一章已完成剧情禁止重复重演：第02章交付：章末已把落脚请求说出口。'));
        final guardIndex = markdown.indexOf('## Chapter Continuity Guard');
        final constraintIndex = markdown.indexOf('## Execution Constraints');
        expect(guardIndex, greaterThanOrEqualTo(0));
        if (constraintIndex >= 0) {
          expect(guardIndex, lessThan(constraintIndex));
        }
      },
    );

    test(
      'prepareDraftRun falls back to previous chapter tail guard for ordinary chapter drafting when delivery sidecar is absent',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/第02章.md',
          '# 第02章\n\n王保正没有立刻让路，只隔着半扇门看了陆安一眼，问他到底想求个什么活路。陆安已经把来意说完，只等这一句回音落下来。',
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          chapterLabelHint: '继续写第03章',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final markdown = preparation.sessionContextMarkdown;

        expect(markdown, contains('## Chapter Continuity Guard'));
        expect(markdown, contains('上一章章末原文锚点：# 第02章 王保正没有立刻让路'));
        expect(markdown, contains('不要把这段章末原文里已经发生的动作、对话或到达重新写一遍'));
      },
    );

    test(
      'finalizeDraftRun keeps builtin expression profiles inactive when project has no binding',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: _chapterDraftResult(project),
          title: '第01章',
        );

        final constraints = ValueReaders.mapValue(
          artifacts.writingExecutionResult['constraints'],
        );
        expect(
          ValueReaders.boolValue(constraints['expression_constraint_active']),
          isFalse,
        );
        expect(
          ValueReaders.boolValue(
            constraints['expression_constraint_evidence_missing'],
          ),
          isFalse,
        );
        expect(
          ValueReaders.stringValue(constraints['summary']),
          contains('当前项目没有启用 binding'),
        );
      },
    );

    test(
      'prepareDraftRun resolves adaptive expression policy from project bindings and keeps tool bridge clean',
      () async {
        await _saveExpressionConstraintBinding(
          profileRepository: profileRepository,
          bindingRepository: bindingRepository,
          project: project,
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );

        expect(
          ValueReaders.stringValue(
            preparation
                .executionConstraints['expression_constraint_policy_mode'],
          ),
          ExpressionConstraintExecutionPolicyModes.adaptive,
        );
        expect(
          ValueReaders.boolValue(
            preparation.executionConstraints['expression_constraint_applied'],
          ),
          isTrue,
        );
        expect(preparation.sessionContextMarkdown, contains('表达限制'));
        expect(
          preparation.activationReport.toString(),
          isNot(contains('expression_constraint_policy_mode')),
        );
        expect(
          preparation.exposedToolIds.join(','),
          isNot(contains('expression_constraint_policy_mode')),
        );
      },
    );

    test(
      'finalizeDraftRun records adaptive expression summary for ordinary chapter runs',
      () async {
        await _saveExpressionConstraintBinding(
          profileRepository: profileRepository,
          bindingRepository: bindingRepository,
          project: project,
        );
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: _chapterDraftResult(project),
          title: '第01章',
        );

        final constraints = ValueReaders.mapValue(
          artifacts.writingExecutionResult['constraints'],
        );
        expect(
          ValueReaders.stringValue(
            constraints['expression_constraint_policy_mode'],
          ),
          ExpressionConstraintExecutionPolicyModes.adaptive,
        );
        expect(
          ValueReaders.boolValue(constraints['expression_constraint_applied']),
          isTrue,
        );
        expect(
          ValueReaders.boolValue(
            constraints['expression_constraint_review_required'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.boolValue(
            constraints['expression_constraint_evidence_missing'],
          ),
          isTrue,
        );
        final projection = ValueReaders.mapValue(
          artifacts.writingExecutionResult['expression_constraint_projection'],
        );
        expect(ValueReaders.boolValue(projection['present']), isTrue);
        expect(ValueReaders.boolValue(projection['applied']), isTrue);
        expect(ValueReaders.stringValue(projection['status']), isNotEmpty);
      },
    );

    test(
      'finalizeDraftRun distinguishes disabled and force expression policy overrides for ordinary chapter runs',
      () async {
        await _saveExpressionConstraintBinding(
          profileRepository: profileRepository,
          bindingRepository: bindingRepository,
          project: project,
        );
        final disabledPreparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.disabled,
        );
        final forcePreparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
        );

        final disabledArtifacts = await service.finalizeDraftRun(
          project: project,
          preparation: disabledPreparation,
          result: _chapterDraftResult(project),
          title: '第01章',
        );
        final forceArtifacts = await service.finalizeDraftRun(
          project: project,
          preparation: forcePreparation,
          result: _chapterDraftResult(project),
          title: '第01章',
        );

        final disabledConstraints = ValueReaders.mapValue(
          disabledArtifacts.writingExecutionResult['constraints'],
        );
        final forceConstraints = ValueReaders.mapValue(
          forceArtifacts.writingExecutionResult['constraints'],
        );

        expect(
          ValueReaders.stringValue(
            disabledConstraints['expression_constraint_policy_mode'],
          ),
          ExpressionConstraintExecutionPolicyModes.disabled,
        );
        expect(
          ValueReaders.boolValue(
            disabledConstraints['expression_constraint_evidence_missing'],
          ),
          isFalse,
        );
        expect(
          ValueReaders.stringValue(
            forceConstraints['expression_constraint_policy_mode'],
          ),
          ExpressionConstraintExecutionPolicyModes.force,
        );
        expect(
          ValueReaders.boolValue(
            forceConstraints['expression_constraint_applied'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.boolValue(
            forceConstraints['expression_constraint_review_required'],
          ),
          isFalse,
        );
        expect(
          ValueReaders.boolValue(
            forceConstraints['expression_constraint_evidence_missing'],
          ),
          isFalse,
        );
        expect(
          ValueReaders.stringValue(
            forceConstraints['expression_constraint_injection_strength'],
          ),
          ExpressionConstraintInjectionStrengths.full,
        );
        expect(
          ValueReaders.stringValue(
            forceConstraints['expression_constraint_violation_disposition'],
          ),
          ExpressionConstraintViolationDispositions.repair,
        );
      },
    );

    test(
      'finalizeDraftRun keeps low residual surface expression risks non-blocking',
      () async {
        await _saveExpressionConstraintBinding(
          profileRepository: profileRepository,
          bindingRepository: bindingRepository,
          project: project,
        );
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: _chapterDraftResult(
            project,
            content: '# 第01章\n\n他停了一下——不是因为害怕，而是终于看懂了账本。',
          ),
          title: '第01章',
        );

        final constraints = ValueReaders.mapValue(
          artifacts.writingExecutionResult['constraints'],
        );
        final gate = ValueReaders.mapValue(
          constraints['expression_constraint_gate'],
        );
        expect(
          ValueReaders.boolValue(
            constraints['expression_constraint_violation_recorded'],
          ),
          isTrue,
        );
        expect(ValueReaders.boolValue(gate['repair_required']), isFalse);
        expect(
          ValueReaders.stringValue(gate['recommended_disposition']),
          ExpressionConstraintGateRecommendedDispositions.remind,
        );
        expect(
          ValueReaders.stringList(gate['risk_signals']).join('\n'),
          contains('正文表面风险命中'),
        );
      },
    );

    test(
      'prepareDraftRun maps deconstruction followup analysis to lighter deconstruction expression policy',
      () async {
        await _saveExpressionConstraintBinding(
          profileRepository: profileRepository,
          bindingRepository: bindingRepository,
          project: project,
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'book_deconstruction_followup',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );

        expect(
          ValueReaders.stringValue(
            preparation
                .executionConstraints['expression_constraint_injection_strength'],
          ),
          ExpressionConstraintInjectionStrengths.brief,
        );
        expect(
          ValueReaders.stringValue(
            preparation
                .executionConstraints['expression_constraint_review_requirement'],
          ),
          ExpressionConstraintReviewRequirements.whenApplied,
        );
        expect(
          ValueReaders.stringList(
            preparation
                .executionConstraints['expression_constraint_applied_reasons'],
          ),
          contains('deconstruction_turn'),
        );
      },
    );

    test(
      'prepareDraftRun keeps deconstruction continuation writing on shared writing bridge',
      () async {
        await _saveExpressionConstraintBinding(
          profileRepository: profileRepository,
          bindingRepository: bindingRepository,
          project: project,
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'book_deconstruction_continuation',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );

        expect(
          ValueReaders.stringValue(
            preparation
                .executionConstraints['expression_constraint_injection_strength'],
          ),
          ExpressionConstraintInjectionStrengths.sections,
        );
        expect(
          ValueReaders.stringList(
            preparation
                .executionConstraints['expression_constraint_applied_reasons'],
          ),
          contains('primary_writing_turn'),
        );
        expect(
          ValueReaders.boolValue(
            preparation
                .executionConstraints['expression_constraint_technical_turn_excluded'],
          ),
          isFalse,
        );
      },
    );

    test(
      'prepareDraftRun keeps explainer summary adaptive brief and force full',
      () async {
        await _saveExpressionConstraintBinding(
          profileRepository: profileRepository,
          bindingRepository: bindingRepository,
          project: project,
        );

        final adaptivePreparation = await service.prepareDraftRun(
          project,
          taskType: 'book_explainer_summary',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final forcePreparation = await service.prepareDraftRun(
          project,
          taskType: 'book_explainer_summary',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
        );

        expect(
          ValueReaders.stringValue(
            adaptivePreparation
                .executionConstraints['expression_constraint_injection_strength'],
          ),
          ExpressionConstraintInjectionStrengths.brief,
        );
        expect(
          ValueReaders.stringValue(
            adaptivePreparation
                .executionConstraints['expression_constraint_review_requirement'],
          ),
          ExpressionConstraintReviewRequirements.whenApplied,
        );
        expect(
          ValueReaders.stringValue(
            forcePreparation
                .executionConstraints['expression_constraint_injection_strength'],
          ),
          ExpressionConstraintInjectionStrengths.full,
        );
        expect(
          ValueReaders.stringValue(
            forcePreparation
                .executionConstraints['expression_constraint_violation_disposition'],
          ),
          ExpressionConstraintViolationDispositions.repair,
        );
      },
    );

    test(
      'prepareDraftRun keeps research-oriented deconstruction summary under information-discipline priority',
      () async {
        await _saveExpressionConstraintBinding(
          profileRepository: profileRepository,
          bindingRepository: bindingRepository,
          project: project,
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'book_deconstruction_research_summary',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
        );

        expect(
          ValueReaders.boolValue(
            preparation.executionConstraints['expression_constraint_applied'],
          ),
          isFalse,
        );
        expect(
          ValueReaders.boolValue(
            preparation
                .executionConstraints['expression_constraint_technical_turn_excluded'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.stringList(
            preparation
                .executionConstraints['expression_constraint_skipped_reasons'],
          ),
          contains('research_execution_turn'),
        );
      },
    );

    test(
      'finalizeDraftRun merges auto research changed paths and reports executed research summary',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'review',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '核查回京礼制是否准确',
          prompt: '核查回京礼制是否准确',
          modelId: 'test-model',
          draftMarkdown: '已补齐资料。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_research_1',
              'name': NarrativeDomainToolNames.requestExternalResearch,
              'result': <String, Object?>{
                'ok': true,
                'changed_paths': <Object?>[
                  '.novel_agent/information/research_requests/research_request_call_research_1.json',
                ],
                'tool_result_summary': '已登记并自动执行资料研究：外部资料研究',
                'domain_outcome': <String, Object?>{
                  'metadata': <String, Object?>{
                    'adapter_persistence': <String, Object?>{
                      'changed_paths': <Object?>[
                        '.novel_agent/information/research_requests/research_request_call_research_1.json',
                      ],
                    },
                  },
                  'outcome_payload': <String, Object?>{
                    'network_execution_performed': true,
                    'research_execution_summary': '已自动补齐回京礼制资料。',
                    'research_execution': <String, Object?>{
                      'executed_network': true,
                      'summary': '已自动补齐回京礼制资料。',
                      'changed_paths': <Object?>[
                        '.novel_agent/information/research_notes/gateway_call_research_1.json',
                        'research/研究摘要.md',
                      ],
                      'gateway_summary': <String, Object?>{
                        'source_quality_summary': <String, Object?>{
                          'requires_rigorous_sources': false,
                          'meets_source_requirement': true,
                        },
                      },
                    },
                  },
                },
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '资料核查',
        );

        expect(artifacts.informationStatus, 'executed_research');
        expect(artifacts.informationSummary, contains('已自动补齐回京礼制资料'));
        expect(
          artifacts.informationChangedPaths,
          containsAll(<String>[
            '.novel_agent/information/research_requests/research_request_call_research_1.json',
            '.novel_agent/information/research_notes/gateway_call_research_1.json',
            'research/研究摘要.md',
          ]),
        );
        expect(
          artifacts.changedPaths,
          containsAll(<String>[
            '.novel_agent/information/research_requests/research_request_call_research_1.json',
            '.novel_agent/information/research_notes/gateway_call_research_1.json',
            'research/研究摘要.md',
          ]),
        );
        final writingExecutionResult = artifacts.writingExecutionResult;
        expect(
          ValueReaders.stringValue(writingExecutionResult['workflow_kind']),
          'review',
        );
        expect(
          ValueReaders.stringValue(writingExecutionResult['overall_status']),
          WritingExecutionOutcomeStatuses.success,
        );
        expect(
          ValueReaders.stringValue(writingExecutionResult['summary']),
          contains('Information：已自动补齐回京礼制资料'),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                writingExecutionResult['information'],
              )['evidence_gate'],
            )['recommended_disposition'],
          ),
          InformationEvidenceRecommendedDispositions.accept,
        );
      },
    );

    test(
      'finalizeDraftRun reports waiting confirmation when research request remains pending',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'review',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '需要再确认是否联网查证',
          prompt: '需要再确认是否联网查证',
          modelId: 'test-model',
          draftMarkdown: '已登记待研究请求。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_research_pending',
              'name': NarrativeDomainToolNames.requestExternalResearch,
              'result': <String, Object?>{
                'ok': true,
                'tool_result_summary': '已登记待研究请求，等待用户确认：外部资料研究',
                'domain_outcome': <String, Object?>{
                  'outcome_payload': <String, Object?>{
                    'requires_user_confirmation': true,
                    'research_execution_summary': '待确认是否联网检索礼制资料。',
                    'research_execution': <String, Object?>{
                      'await_user_confirmation': true,
                      'summary': '待确认是否联网检索礼制资料。',
                      'changed_paths': <Object?>[
                        '.novel_agent/information/research_requests/research_request_call_research_pending.json',
                      ],
                    },
                  },
                },
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '资料确认',
        );

        expect(artifacts.informationStatus, 'waiting_confirmation');
        expect(artifacts.informationSummary, contains('待确认是否联网检索礼制资料'));
        expect(
          artifacts.changedPaths,
          contains(
            '.novel_agent/information/research_requests/research_request_call_research_pending.json',
          ),
        );
        expect(
          ValueReaders.stringValue(
            artifacts.writingExecutionResult['workflow_kind'],
          ),
          'review',
        );
        expect(
          ValueReaders.stringValue(
            artifacts.writingExecutionResult['overall_status'],
          ),
          WritingExecutionOutcomeStatuses.userActionRequired,
        );
        expect(
          ValueReaders.stringValue(
            artifacts.writingExecutionResult['next_action'],
          ),
          'resume_when_user_confirms',
        );
      },
    );

    test(
      'finalizeDraftRun keeps rigorous source insufficiency as evidence warning in shared result',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'review',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '补一轮严谨资料核查',
          prompt: '补一轮严谨资料核查',
          modelId: 'test-model',
          draftMarkdown: '已补充初步资料。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_research_rigorous',
              'name': NarrativeDomainToolNames.requestExternalResearch,
              'result': <String, Object?>{
                'ok': true,
                'tool_result_summary': '已执行资料研究，但严谨来源仍不足。',
                'domain_outcome': <String, Object?>{
                  'outcome_payload': <String, Object?>{
                    'network_execution_performed': true,
                    'research_execution_summary': '已执行资料研究，但严谨来源仍不足。',
                    'research_execution': <String, Object?>{
                      'executed_network': true,
                      'summary': '已执行资料研究，但严谨来源仍不足。',
                      'changed_paths': <Object?>['research/严谨来源补充.md'],
                      'gateway_summary': <String, Object?>{
                        'source_quality_summary': <String, Object?>{
                          'requires_rigorous_sources': true,
                          'meets_source_requirement': false,
                        },
                      },
                    },
                  },
                },
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '严谨资料核查',
        );

        expect(artifacts.informationStatus, 'source_insufficient');
        expect(artifacts.informationSummary, contains('严谨来源仍不足'));
        expect(
          ValueReaders.stringValue(
            artifacts.writingExecutionResult['overall_status'],
          ),
          WritingExecutionOutcomeStatuses.success,
        );
        final information = ValueReaders.mapValue(
          artifacts.writingExecutionResult['information'],
        );
        final evidenceGate = ValueReaders.mapValue(
          information['evidence_gate'],
        );
        expect(ValueReaders.boolValue(information['requires_repair']), isFalse);
        expect(
          ValueReaders.stringValue(evidenceGate['severity']),
          InformationEvidenceGateSeverities.warning,
        );
        expect(
          ValueReaders.stringValue(evidenceGate['recommended_disposition']),
          InformationEvidenceRecommendedDispositions.accept,
        );
        expect(
          ValueReaders.stringValue(artifacts.writingExecutionResult['summary']),
          contains('Information：已执行资料研究，但严谨来源仍不足'),
        );
      },
    );

    test(
      'finalizeDraftRun maps deconstruction followup into shared writing execution workflow kind',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'book_deconstruction_followup',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续整理拆书续写方向',
          prompt: '继续整理拆书续写方向',
          modelId: 'test-model',
          draftMarkdown: '已整理后续方向。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: const <Object?>[],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '拆书续写方向',
        );

        expect(
          ValueReaders.stringValue(
            artifacts.writingExecutionResult['workflow_kind'],
          ),
          'deconstruction_followup',
        );
        expect(
          ValueReaders.intValue(
            ValueReaders.mapValue(
              artifacts.writingExecutionResult['information'],
            )['selected_item_count'],
          ),
          greaterThanOrEqualTo(0),
        );
      },
    );

    test(
      'finalizeDraftRun reports no information change when no research or information tools ran',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'review',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '直接润色这段',
          prompt: '直接润色这段',
          modelId: 'test-model',
          draftMarkdown: '已完成润色。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: const <Object?>[],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '润色',
        );

        expect(artifacts.informationStatus, 'no_information_change');
        expect(artifacts.informationSummary, '无 information 变更。');
        expect(artifacts.informationChangedPaths, isEmpty);
      },
    );

    test(
      'finalizeDraftRun backfills submit_chapter_delivery for ordinary write_project_file chapter output',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第一章',
          prompt: '继续写第一章',
          modelId: 'test-model',
          draftMarkdown: '章节已保存。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_write_1',
              'name': 'write_project_file',
              'arguments': <String, Object?>{
                'content_type': 'chapter',
                'title': '第01章',
                'content': '# 第01章\n\n夜雨沿着宫墙流下，回京的人没有回头。',
              },
              'result': <String, Object?>{
                'ok': true,
                'relative_path': 'chapters/chapter_01.md',
                'changed_paths': <Object?>['chapters/chapter_01.md'],
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>['chapters/chapter_01.md'],
          changedPaths: const <String>['chapters/chapter_01.md'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第01章',
        );
        final deliveryRecordPath = _chapterDeliveryRecordPath(
          artifacts.outputPath,
        );

        final activationReportFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${preparation.activationReportPath.replaceAll('/', Platform.pathSeparator)}',
        );
        final deliveryRecordFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${deliveryRecordPath.replaceAll('/', Platform.pathSeparator)}',
        );
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}chapter_01.md',
        );

        expect(artifacts.outputPath, 'chapters/chapter_01.md');
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['tool_name']),
          'submit_chapter_delivery',
        );
        expect(await activationReportFile.exists(), isTrue);
        expect(await deliveryRecordFile.exists(), isTrue);
        expect(await chapterFile.exists(), isTrue);
        expect(await chapterFile.readAsString(), contains('夜雨沿着宫墙流下'));
        expect(
          artifacts.changedPaths,
          containsAll(<String>[
            preparation.activationReportPath,
            'chapters/chapter_01.md',
            deliveryRecordPath,
          ]),
        );
      },
    );

    test(
      'finalizeDraftRun backfills submit_chapter_delivery for chaptered continuation write_project_file output',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'book_deconstruction_continuation',
          chapterLabelHint: '继续写第03章',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第03章',
          prompt: '继续写第03章',
          modelId: 'test-model',
          draftMarkdown: '第03章已续写。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_write_3',
              'name': 'write_project_file',
              'arguments': <String, Object?>{
                'content_type': 'chapter',
                'title': '第03章',
                'content': '# 第03章\n\n门开后，陆安没有再从镇口回头，而是顺着上一句直接接过王保正的话。',
              },
              'result': <String, Object?>{
                'ok': true,
                'relative_path': 'chapters/第03章.md',
                'changed_paths': <Object?>['chapters/第03章.md'],
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>['chapters/第03章.md'],
          changedPaths: const <String>['chapters/第03章.md'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第03章',
        );
        final deliveryRecordPath = _chapterDeliveryRecordPath(
          artifacts.outputPath,
        );

        final deliveryRecordFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${deliveryRecordPath.replaceAll('/', Platform.pathSeparator)}',
        );
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}第03章.md',
        );

        expect(artifacts.outputPath, 'chapters/第03章.md');
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['tool_name']),
          'submit_chapter_delivery',
        );
        expect(await deliveryRecordFile.exists(), isTrue);
        expect(await chapterFile.exists(), isTrue);
        expect(await chapterFile.readAsString(), contains('直接接过王保正的话'));
        expect(
          artifacts.changedPaths,
          containsAll(<String>[
            preparation.activationReportPath,
            'chapters/第03章.md',
            deliveryRecordPath,
          ]),
        );
      },
    );

    test(
      'finalizeDraftRun rejects ordinary chapter delivery when chapter length stays below configured minimum',
      () async {
        final narrativeBindingRepository = LocalConstraintBindingRepository(
          workspacePort: workspacePort,
        );
        await narrativeBindingRepository.appendBinding(
          project,
          NarrativeConstraintBindingProposal(
            bindingId: 'ordinary_chapter_length_binding',
            constraintType: 'chapter_length',
            constraintLabel: '普通分章字数窗口',
            scope: const ConstraintBindingScope(
              appliesTo: <String>[ConstraintBindingAppliesTo.writing],
              stageIds: <String>['draft', 'chapter_write'],
            ),
            policy: const ConstraintBindingPolicy(
              hardExecutionPolicy: <String, Object?>{'target_word_count': 2200},
            ),
            source: const NarrativeSourceRef(
              sourceType: NarrativeSourceTypes.user,
              sourceId: 'test-user',
              label: 'test-user',
            ),
            constraintPayload: const <String, Object?>{
              'target_word_count': 2200,
              'preferred_min': 1600,
              'preferred_max': 2600,
            },
          ),
        );
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          chapterLabelHint: '继续写第03章',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第03章',
          prompt: '继续写第03章',
          modelId: 'test-model',
          draftMarkdown: '第03章已续写。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_write_short_3',
              'name': 'write_project_file',
              'arguments': <String, Object?>{
                'content_type': 'chapter',
                'title': '第03章',
                'content': '# 第03章\n\n雨停了，周砚只回了一句便收了声。',
              },
              'result': <String, Object?>{
                'ok': true,
                'relative_path': 'chapters/第03章.md',
                'changed_paths': <Object?>['chapters/第03章.md'],
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>['chapters/第03章.md'],
          changedPaths: const <String>['chapters/第03章.md'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        expect(
          () => service.finalizeDraftRun(
            project: project,
            preparation: preparation,
            result: result,
            title: '第03章',
          ),
          throwsA(
            predicate<Object?>(
              (error) =>
                  error is StateError &&
                  '$error'.contains('未通过字数 gate') &&
                  '$error'.contains('低于最小要求 1600'),
            ),
          ),
        );
      },
    );

    test(
      'finalizeDraftRun keeps information changed paths when ordinary chapter flow submits knowledge and design delta',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final knowledgeArguments = <String, Object?>{
          'card_id': 'knowledge-night-rain',
          'card_namespace': 'project.rules',
          'card_type': 'world_rule',
          'title': '夜雨归京规则',
          'summary': '归京相关章节必须让夜雨承担迟疑与回望。',
          'content_payload': const <String, Object?>{
            'rule': '归京章节里的夜雨应回扣主角是否回头',
          },
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
                'source_id': 'writer-agent',
              },
              'source_authority': InformationSourceAuthorities.aiInferred,
              'role_authority': InformationRoleAuthorities.writer,
              'research_depth': InformationResearchDepths.quick,
            },
          ],
          'activation_policy': const <String, Object?>{
            'activation_priority': InformationActivationPriorities.required,
            'preferred_budget_chars': 180,
          },
          'usage_policy': const <String, Object?>{
            'usage_mode': InformationUsageModes.normal,
            'citation_risk_level': InformationCitationRiskLevels.low,
          },
          'confidence': 0.89,
        };
        final designArguments = <String, Object?>{
          'design_id': 'design-night-rain',
          'design_namespace': 'project.structure',
          'design_label': '夜雨回扣',
          'design_payload': const <String, Object?>{
            'pattern': '章末夜雨解释章首回京动作里的迟疑',
          },
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
                'source_id': 'writer-agent',
              },
              'source_authority': InformationSourceAuthorities.aiInferred,
              'role_authority': InformationRoleAuthorities.writer,
              'research_depth': InformationResearchDepths.quick,
            },
          ],
          'activation_policy': const <String, Object?>{
            'activation_priority': InformationActivationPriorities.pinned,
            'preferred_budget_chars': 180,
          },
          'usage_policy': const <String, Object?>{
            'usage_mode': InformationUsageModes.normal,
            'citation_risk_level': InformationCitationRiskLevels.low,
          },
          'confidence': 0.78,
          'uncertainty': '后续章节还要继续验证回扣强度。',
        };
        final knowledgeResult = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'call_knowledge_1',
            'name': NarrativeDomainToolNames.proposeKnowledgeCard,
            'source_type': NarrativeSourceTypes.writer,
            'arguments': knowledgeArguments,
          },
        );
        final designResult = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'call_design_1',
            'name': NarrativeDomainToolNames.proposeDesignElement,
            'source_type': NarrativeSourceTypes.writer,
            'arguments': designArguments,
          },
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第一章',
          prompt: '继续写第一章',
          modelId: 'test-model',
          draftMarkdown: '章节已保存。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_knowledge_1',
              'name': NarrativeDomainToolNames.proposeKnowledgeCard,
              'arguments': knowledgeArguments,
              'result': knowledgeResult,
              'ok': ValueReaders.boolValue(knowledgeResult['ok']),
            },
            <String, Object?>{
              'id': 'call_design_1',
              'name': NarrativeDomainToolNames.proposeDesignElement,
              'arguments': designArguments,
              'result': designResult,
              'ok': ValueReaders.boolValue(designResult['ok']),
            },
            <String, Object?>{
              'id': 'call_write_1',
              'name': 'write_project_file',
              'arguments': <String, Object?>{
                'content_type': 'chapter',
                'title': '第01章',
                'content': '# 第01章\n\n夜雨沿着宫墙流下，回京的人还是回头了。',
              },
              'result': <String, Object?>{
                'ok': true,
                'relative_path': 'chapters/chapter_01.md',
                'changed_paths': <Object?>['chapters/chapter_01.md'],
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>['chapters/chapter_01.md'],
          changedPaths: _mergeChangedPaths(<String>[
            'chapters/chapter_01.md',
            ...ValueReaders.stringList(knowledgeResult['changed_paths']),
            ...ValueReaders.stringList(designResult['changed_paths']),
          ]),
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第01章',
        );

        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['tool_name']),
          NarrativeDomainToolNames.submitChapterDelivery,
        );
        expect(
          artifacts.changedPaths,
          containsAll(<String>[
            preparation.activationReportPath,
            '.novel_agent/information/knowledge_cards/knowledge-night-rain.json',
            '.novel_agent/information/design_elements/design-night-rain.json',
            'knowledge/项目知识摘要.md',
            'knowledge/设计元素摘要.md',
            'chapters/chapter_01.md',
          ]),
        );
      },
    );

    test(
      'finalizeDraftRun recovers invalid submit_chapter_delivery attempt when chapter payload is still salvageable',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第四章',
          prompt: '继续写第四章',
          modelId: 'test-model',
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_delivery_invalid_1',
              'name': 'submit_chapter_delivery',
              'arguments': <String, Object?>{
                'chapter_path': 'chapters/第04章.md',
                'content': '# 第04章 第二层频道\n\n沈临川在静电噪声里听见第二个频道慢慢抬头。',
                'submission': <String, Object?>{'submission_id': ''},
              },
              'result': <String, Object?>{
                'ok': false,
                'error': '领域工具参数不合法。',
                'tool_result_summary': '领域工具参数不合法，需要修正后重试。',
              },
              'ok': false,
            },
          ],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: true,
          toolErrorSummary: 'submit_chapter_delivery：领域工具参数不合法。',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第04章《第二层频道》',
        );
        final deliveryRecordPath = _chapterDeliveryRecordPath(
          artifacts.outputPath,
        );

        final deliveryRecordFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${deliveryRecordPath.replaceAll('/', Platform.pathSeparator)}',
        );
        final resolvedChapterPath = artifacts.outputPath.replaceAll(
          '/',
          Platform.pathSeparator,
        );
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}$resolvedChapterPath',
        );

        expect(
          artifacts.outputPath,
          ValueReaders.stringValue(artifacts.chapterDelivery['chapter_path']),
        );
        expect(artifacts.outputPath, startsWith('chapters/第04章'));
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['delivery_state']),
          'delivered',
        );
        expect(await deliveryRecordFile.exists(), isTrue);
        expect(await chapterFile.exists(), isTrue);
        expect(await chapterFile.readAsString(), contains('第二个频道慢慢抬头'));
        expect(
          artifacts.changedPaths,
          contains(preparation.activationReportPath),
        );
        expect(artifacts.changedPaths, contains(artifacts.outputPath));
        expect(artifacts.changedPaths, contains(deliveryRecordPath));
      },
    );

    test(
      'finalizeDraftRun keeps failed chapter delivery diagnostic without projecting unsaved output path',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第三章',
          prompt: '继续写第三章',
          modelId: 'test-model',
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_delivery_invalid_continuity_1',
              'name': NarrativeDomainToolNames.submitChapterDelivery,
              'arguments': <String, Object?>{
                'chapter_path': 'chapters/第03章.md',
                'chapter_content': '# 第03章\n\n王保正刚把话说完，门外的人又把同一句话重复了一遍。',
                'title': '第03章',
              },
              'result': <String, Object?>{
                'ok': false,
                'error': '章节开篇疑似回退重演上一章末尾已完成动作，没有直接承接下一章入口。',
                'domain_outcome_status': 'invalid_payload',
                'domain_outcome': <String, Object?>{
                  'outcome_status': 'invalid_payload',
                  'outcome_payload': <String, Object?>{
                    'chapter_path': 'chapters/第03章.md',
                    'delivery_state': 'delivered',
                    'chapter_body_state': 'delivered',
                    'sidecar_state': 'missing',
                    'state_result': <String, Object?>{
                      'chapter_body_delivered': true,
                      'submission_accepted': false,
                    },
                  },
                },
              },
              'ok': false,
            },
          ],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: true,
          toolErrorSummary: 'submit_chapter_delivery：章节开篇疑似回退重演上一章末尾已完成动作。',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第03章',
        );
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}第03章.md',
        );

        expect(artifacts.outputPath, isEmpty);
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['chapter_path']),
          'chapters/第03章.md',
        );
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['outcome_status']),
          'invalid_payload',
        );
        expect(await chapterFile.exists(), isFalse);
        expect(artifacts.changedPaths, isNot(contains('chapters/第03章.md')));
        expect(
          artifacts.changedPaths,
          contains(preparation.activationReportPath),
        );
      },
    );

    test(
      'finalizeDraftRun supplements accepted delivery that is missing submission sidecar',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第一章',
          prompt: '继续写第一章',
          modelId: 'test-model',
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_delivery_invalid_1',
              'name': 'submit_chapter_delivery',
              'arguments': <String, Object?>{
                'chapter_path': 'chapters/第01章.md',
                'chapter_content': '# 第01章\n\n夜雨沿着宫墙流下。',
                'submission': <String, Object?>{'submission_id': ''},
              },
              'result': <String, Object?>{
                'ok': false,
                'error': '领域工具参数不合法。',
                'tool_result_summary': '领域工具参数不合法，需要修正后重试。',
              },
              'ok': false,
            },
            <String, Object?>{
              'id': 'call_delivery_repairable_1',
              'name': 'submit_chapter_delivery',
              'arguments': <String, Object?>{
                'chapter_path': 'chapters/第01章.md',
                'chapter_content': '# 第01章\n\n夜雨沿着宫墙流下。',
              },
              'result': <String, Object?>{
                'ok': true,
                'domain_outcome': <String, Object?>{
                  'outcome_status': 'accepted',
                  'outcome_payload': <String, Object?>{
                    'delivery_id':
                        'delivery:call_delivery_repairable_1:chapters/第01章.md',
                    'chapter_path': 'chapters/第01章.md',
                    'delivery_state': 'delivered_needs_repair',
                    'chapter_body_state': 'delivered',
                    'sidecar_state': 'missing',
                    'state_result': <String, Object?>{
                      'chapter_body_delivered': true,
                      'submission_accepted': false,
                    },
                  },
                },
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>['chapters/第01章.md'],
          changedPaths: const <String>['chapters/第01章.md'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: true,
          toolErrorSummary: 'submit_chapter_delivery：领域工具参数不合法。',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第01章《午夜热线》',
        );

        expect(
          artifacts.outputPath,
          ValueReaders.stringValue(artifacts.chapterDelivery['chapter_path']),
        );
        expect(artifacts.outputPath, startsWith('chapters/第01章'));
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['delivery_state']),
          'delivered',
        );
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['sidecar_state']),
          'accepted',
        );
        expect(
          artifacts.changedPaths,
          contains(_chapterDeliveryRecordPath(artifacts.outputPath)),
        );
      },
    );

    test(
      'finalizeDraftRun auto-delivery stores continuity-aware summary instead of placeholder text',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第二章',
          prompt: '继续写第二章',
          modelId: 'test-model',
          draftMarkdown: '# 第02章\n\n陆安站在门前敲了三下，门里的人应了一声，脚步声已经到了门后。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_write_2',
              'name': 'write_project_file',
              'arguments': <String, Object?>{
                'content_type': 'chapter',
                'title': '第02章',
                'content': '# 第02章\n\n陆安站在门前敲了三下，门里的人应了一声，脚步声已经到了门后。',
              },
              'result': <String, Object?>{
                'ok': true,
                'relative_path': 'chapters/第02章.md',
                'changed_paths': <Object?>['chapters/第02章.md'],
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>['chapters/第02章.md'],
          changedPaths: const <String>['chapters/第02章.md'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第02章',
        );
        final deliveryRecord = await workspacePort.readTextFile(
          project.rootPath,
          _chapterDeliveryRecordPath(artifacts.outputPath),
        );
        final deliveryJson = ValueReaders.mapValue(jsonDecode(deliveryRecord!));
        final submission = ValueReaders.mapValue(deliveryJson['submission']);
        final finalState = ValueReaders.mapValue(
          submission['final_state_summary'],
        );

        expect(
          ValueReaders.stringValue(submission['summary']),
          contains('章末落点'),
        );
        expect(
          ValueReaders.stringValue(submission['summary']),
          isNot(contains('ordinary conversation chapter delivery')),
        );
        expect(
          ValueReaders.stringValue(finalState['next_chapter_handoff']),
          contains('不要回退重演'),
        );
        expect(
          ValueReaders.stringValue(finalState['chapter_end_excerpt']),
          contains('脚步声已经到了门后'),
        );
      },
    );

    test(
      'finalizeDraftRun rejects chapter task that only planned or delegated without formal delivery',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第四章',
          prompt: '继续写第四章',
          modelId: 'test-model',
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_plan_1',
              'name': 'set_agent_tasks',
              'arguments': <String, Object?>{
                'tasks': <Object?>[
                  <String, Object?>{'title': '先列提纲'},
                ],
              },
              'result': <String, Object?>{
                'ok': true,
                'changed_paths': <Object?>['tasks/写作第04章正文.task.json'],
              },
              'ok': true,
            },
            <String, Object?>{
              'id': 'call_sub_1',
              'name': 'call_sub_agent',
              'arguments': <String, Object?>{
                'agent_id': 'story_writer',
                'task': '先整理第04章思路',
              },
              'result': <String, Object?>{
                'ok': true,
                'result_markdown': '先做了章节计划。',
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>[],
          changedPaths: const <String>['tasks/写作第04章正文.task.json'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        expect(
          () => service.finalizeDraftRun(
            project: project,
            preparation: preparation,
            result: result,
            title: '第04章《第二层频道》',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('只执行了计划/委派/读取类工具'),
            ),
          ),
        );
      },
    );
  });
}

InformationSourceRef _sourceRef() {
  return const InformationSourceRef(
    sourceRef: NarrativeSourceRef(
      sourceType: NarrativeSourceTypes.user,
      sourceId: 'user-seed',
    ),
    sourceAuthority: InformationSourceAuthorities.userDeclared,
    roleAuthority: InformationRoleAuthorities.user,
    researchDepth: InformationResearchDepths.none,
  );
}

Future<void> _saveExpressionConstraintBinding({
  required ExpressionConstraintProfileRepository profileRepository,
  required ProjectExpressionConstraintBindingRepository bindingRepository,
  required ProjectDescriptor project,
}) async {
  await profileRepository.saveProjectProfiles(
    project,
    const <ExpressionConstraintProfile>[
      ExpressionConstraintProfile(
        id: 'project_natural_expression',
        displayName: '项目自然表达',
        summary: '项目级自然表达约束。',
        kind: ExpressionConstraintKind.naturalExpression,
        rules: <String>['压低解释腔。'],
        riskSignals: <String>['——', '不是……而是……'],
      ),
    ],
  );
  await bindingRepository
      .saveBindings(project, const <ProjectExpressionConstraintBinding>[
        ProjectExpressionConstraintBinding(
          id: 'project_binding_1',
          profileId: 'project_natural_expression',
          defaultForProject: true,
        ),
      ]);
}

DraftGenerationResult _chapterDraftResult(
  ProjectDescriptor project, {
  String content = '# 第01章\n\n夜雨沿着宫墙流下，回京的人还是回头了。',
}) {
  return DraftGenerationResult(
    project: project,
    projectInfo: <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
    },
    userPrompt: '继续写第一章',
    prompt: '继续写第一章',
    modelId: 'test-model',
    draftMarkdown: content,
    contextPack: const <String, Object?>{},
    selectedPaths: const <String>['outline/总纲.md'],
    executedTools: <Object?>[
      <String, Object?>{
        'id': 'call_write_1',
        'name': 'write_project_file',
        'arguments': <String, Object?>{
          'content_type': 'chapter',
          'title': '第01章',
          'content': content,
        },
        'result': <String, Object?>{
          'ok': true,
          'relative_path': 'chapters/chapter_01.md',
          'changed_paths': <Object?>['chapters/chapter_01.md'],
        },
        'ok': true,
      },
    ],
    writtenPaths: const <String>['chapters/chapter_01.md'],
    changedPaths: const <String>['chapters/chapter_01.md'],
    transcriptMessages: const <JsonMap>[],
    waitingForUserChoice: false,
    reasoningContent: '',
    stoppedByToolError: false,
    toolErrorSummary: '',
  );
}

List<String> _mergeChangedPaths(List<String> paths) {
  final result = <String>[];
  for (final rawPath in paths) {
    final path = rawPath.trim();
    if (path.isEmpty || result.contains(path)) {
      continue;
    }
    result.add(path);
  }
  return result;
}

String _chapterDeliveryRecordPath(String chapterPath) {
  return OpenNarrativeStatePathService().deliveryPath(
    'submission:$chapterPath',
  );
}
