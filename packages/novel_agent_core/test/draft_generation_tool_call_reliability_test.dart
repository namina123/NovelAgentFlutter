import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Draft generation tool call reliability', () {
    test(
      'write_project_file only flow cannot distinguish sidecar-only write from chapter delivery',
      () async {
        // 中文注释: 这里锁定当前低层文件写入流的结构性不足：只写 sidecar 时，核心只能看见“有写入”，却不知道章节正文并未交付。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_sidecar_1',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'tracking/continuity_sidecars/第01章.json',
                    'content':
                        '{"chapter_path":"chapters/第01章.md","segments":[],"transitions":[]}',
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
          ],
        );
        final toolExecutionPort = _SequencedToolExecutionPort(
          responses: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'relative_path': 'tracking/continuity_sidecars/第01章.json',
              'changed_paths': <Object?>[
                'tracking/continuity_sidecars/第01章.json',
              ],
            },
          ],
        );
        final useCase = _buildUseCase(
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: toolExecutionPort,
        );

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '继续写第一章，并记录连续性 sidecar。',
          modelId: 'test-model',
          intent: 'draft',
        );

        expect(toolExecutionPort.executedCalls, hasLength(1));
        expect(
          result.writtenPaths,
          contains('tracking/continuity_sidecars/第01章.json'),
        );
        expect(
          result.writtenPaths.where((path) => path.startsWith('chapters/')),
          isEmpty,
        );
        expect(result.draftMarkdown, isEmpty);
        expect(result.stoppedByToolError, isFalse);
      },
    );

    test(
      'split chapter and sidecar writes can fail after chapter write already succeeded',
      () async {
        // 中文注释: 这里锁定双 write_project_file 方案的另一个脆弱点：正文已写成功，但 sidecar 失败时整轮仍会被打成工具失败。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_chapter_1',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'chapters/第01章.md',
                    'content': '# 第01章\n\n正文内容',
                  },
                },
                <String, Object?>{
                  'id': 'call_sidecar_1',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'tracking/continuity_sidecars/第01章.json',
                    'content':
                        '{"chapter_path":"chapters/第01章.md","segments":[{"segment_id":"seg_1"}]}',
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
          ],
        );
        final toolExecutionPort = _SequencedToolExecutionPort(
          responses: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'relative_path': 'chapters/第01章.md',
              'changed_paths': <Object?>['chapters/第01章.md'],
            },
            <String, Object?>{
              'ok': false,
              'relative_path': 'tracking/continuity_sidecars/第01章.json',
              'changed_paths': const <Object?>[],
              'error': 'content is required.',
            },
          ],
        );
        final useCase = _buildUseCase(
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: toolExecutionPort,
        );

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '继续写第一章，并同时提交连续性 sidecar。',
          modelId: 'test-model',
          intent: 'draft',
        );

        expect(toolExecutionPort.executedCalls, hasLength(2));
        expect(result.writtenPaths, contains('chapters/第01章.md'));
        expect(result.stoppedByToolError, isTrue);
        expect(result.toolErrorSummary, contains('content is required.'));
        expect(result.draftMarkdown, isEmpty);
      },
    );

    test(
      'repeated read only rounds are stopped before they are mistaken for progress',
      () async {
        // 中文注释: 这里验证当前至少能拦住连续相同的只读空转，避免“看起来一直在调用工具”却没有任何章节交付。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            _readOnlyRoundResult(),
            _readOnlyRoundResult(),
            _readOnlyRoundResult(),
          ],
        );
        final toolExecutionPort = _SequencedToolExecutionPort(
          responses: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'relative_path': 'outline/总纲.md',
              'content': '# 总纲\n测试内容',
              'changed_paths': const <Object?>[],
            },
            <String, Object?>{
              'ok': true,
              'relative_path': 'outline/总纲.md',
              'content': '# 总纲\n测试内容',
              'changed_paths': const <Object?>[],
            },
          ],
        );
        final useCase = _buildUseCase(
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: toolExecutionPort,
        );

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '继续推进当前章节。',
          modelId: 'test-model',
          intent: 'draft',
        );

        expect(toolExecutionPort.executedCalls, hasLength(2));
        expect(result.stoppedByToolError, isTrue);
        expect(result.toolErrorSummary, contains('工具重复空转'));
        expect(result.writtenPaths, isEmpty);
      },
    );
  });

  group('Draft generation domain tool reliability matrix', () {
    test(
      'writer chapter delivery tool yields explicit delivery contract',
      () async {
        final catalog = NarrativeDomainToolCatalog();
        final dispatcher = _buildDomainToolDispatcher();

        final parsed = catalog.parseRequest(
          callId: 'writer-call-001',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.writer,
          ),
          arguments: <String, Object?>{
            'chapter_path': 'chapters/第01章.md',
            'chapter_content': '# 第01章\n\n正文内容',
            'title': '第01章',
            'submission': _validSubmissionJson(chapterId: 'chapter-001'),
            'constraint_coverage': <String, Object?>{'length': 'covered'},
          },
        );

        expect(parsed.isSuccess, isTrue);

        final outcome = await dispatcher.dispatch(request: parsed.request!);
        final stateResult =
            outcome.outcomePayload['state_result'] as Map<String, Object?>;

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(
          outcome.outcomePayload['delivery_state'],
          ChapterDeliveryStateStatuses.delivered,
        );
        expect(outcome.outcomePayload['chapter_body_state'], 'delivered');
        expect(outcome.outcomePayload['sidecar_state'], 'accepted');
        expect(stateResult['submission_accepted'], isTrue);
      },
    );

    test(
      'reviewer semantic review tool stays structured and non-scheduling',
      () async {
        final catalog = NarrativeDomainToolCatalog();
        final dispatcher = _buildDomainToolDispatcher();

        final parsed = catalog.parseRequest(
          callId: 'reviewer-call-001',
          toolName: NarrativeDomainToolNames.submitSemanticReview,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.reviewer,
          ),
          arguments: <String, Object?>{
            'review_id': 'review-001',
            'recommended_disposition': 'repair',
            'findings': <Object?>[
              <String, Object?>{
                'finding_id': 'finding-001',
                'severity': 'blocking',
                'summary': '需要返修。',
                'unable_to_locate_evidence': true,
                'unlocatable_reason': '本轮只有摘要。',
                'confidence': 0.8,
              },
            ],
          },
        );

        expect(parsed.isSuccess, isTrue);

        final outcome = await dispatcher.dispatch(request: parsed.request!);

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.proposed);
        expect(outcome.outcomePayload['review_advances_workflow'], isFalse);
        expect(outcome.outcomePayload['blocking_finding_count'], 1);
      },
    );

    test(
      'recovery can distinguish missing body from repaired chapter delivery',
      () async {
        final catalog = NarrativeDomainToolCatalog();
        final dispatcher = _buildDomainToolDispatcher();

        final missingBody = catalog.parseRequest(
          callId: 'recovery-call-001',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.recovery,
          ),
          arguments: <String, Object?>{
            'chapter_path': 'chapters/第09章.md',
            'chapter_content': '   ',
            'title': '第09章',
            'submission': _validSubmissionJson(chapterId: 'chapter-009'),
          },
        );
        final repaired = catalog.parseRequest(
          callId: 'recovery-call-002',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.recovery,
          ),
          arguments: <String, Object?>{
            'chapter_path': 'chapters/第09章.md',
            'chapter_content': '# 第09章\n\n补写后的正文内容',
            'title': '第09章',
            'submission': _validSubmissionJson(chapterId: 'chapter-009'),
          },
        );

        expect(missingBody.isSuccess, isTrue);
        expect(repaired.isSuccess, isTrue);

        final missingOutcome = await dispatcher.dispatch(
          request: missingBody.request!,
        );
        final repairedOutcome = await dispatcher.dispatch(
          request: repaired.request!,
        );

        expect(
          missingOutcome.outcomeStatus,
          DomainToolOutcomeStatuses.invalidPayload,
        );
        expect(
          missingOutcome.outcomePayload['delivery_state'],
          ChapterDeliveryStateStatuses.missingOutputRecoverable,
        );
        expect(
          missingOutcome.outcomePayload['sidecar_state'],
          'blocked_by_chapter_failure',
        );
        expect(
          repairedOutcome.outcomeStatus,
          DomainToolOutcomeStatuses.accepted,
        );
        expect(
          repairedOutcome.outcomePayload['delivery_state'],
          ChapterDeliveryStateStatuses.delivered,
        );
      },
    );

    test(
      'architect can use profile proposal plus clarification instead of brittle file writes',
      () async {
        final catalog = NarrativeDomainToolCatalog();
        final dispatcher = _buildDomainToolDispatcher();

        final profileProposal = catalog.parseRequest(
          callId: 'architect-call-001',
          toolName: NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.deconstruction,
          ),
          arguments: <String, Object?>{
            'proposal_id': 'proposal-001',
            'profile_patch': <String, Object?>{
              'namespace': 'project.custom.profile',
              'display_name': '自定义解释器',
              'future_patch_payload': <String, Object?>{'layers': 3},
            },
          },
        );
        final clarification = catalog.parseRequest(
          callId: 'architect-call-002',
          toolName: NarrativeDomainToolNames.requestProfileClarification,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.deconstruction,
          ),
          arguments: <String, Object?>{
            'question': '这个规则只作用于当前项目，还是作为后续项目模板？',
            'options': <Object?>[
              <String, Object?>{'label': '仅当前项目'},
              <String, Object?>{'label': '作为后续模板'},
            ],
            'freeform_allowed': true,
            'blocking': true,
            'reason': '需要确认 profile 适用范围。',
          },
        );

        expect(profileProposal.isSuccess, isTrue);
        expect(clarification.isSuccess, isTrue);

        final proposalOutcome = await dispatcher.dispatch(
          request: profileProposal.request!,
        );
        final clarificationOutcome = await dispatcher.dispatch(
          request: clarification.request!,
        );

        expect(
          proposalOutcome.outcomeStatus,
          DomainToolOutcomeStatuses.proposed,
        );
        expect(
          proposalOutcome.outcomePayload['requires_user_confirmation'],
          isFalse,
        );
        expect(
          clarificationOutcome.outcomeStatus,
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        expect(clarificationOutcome.outcomePayload['blocks_progress'], isTrue);
        expect(clarificationOutcome.outcomePayload['option_count'], 2);
      },
    );
  });
}

GenerateDraftUseCase _buildUseCase({
  required ProjectWorkspacePort workspacePort,
  required LlmGateway gateway,
  required ToolExecutionPort toolExecutionPort,
}) {
  return GenerateDraftUseCase(
    projectWorkspacePort: workspacePort,
    llmGateway: gateway,
    toolExecutionPort: toolExecutionPort,
    contextAssemblerService: ContextAssemblerService(
      budgetService: ContextBudgetService(),
      staticSectionService: ContextStaticSectionService(
        projectPromptContract: ProjectPromptContract(),
      ),
      projectFileSectionService: ContextProjectFileSectionService(),
    ),
    projectPromptContract: ProjectPromptContract(),
    skillRoutingPolicyService: const _NoPreloadSkillRoutingPolicyService(),
  );
}

JsonMap _readOnlyRoundResult() {
  return <String, Object?>{
    'ok': true,
    'content': '',
    'tool_calls': <Object?>[
      <String, Object?>{
        'id': 'call_read_1',
        'name': 'read_project_file',
        'arguments': <String, Object?>{'relative_path': 'outline/总纲.md'},
      },
    ],
    'message': const <String, Object?>{'role': 'assistant', 'content': ''},
  };
}

class _FakeProjectWorkspacePort implements ProjectWorkspacePort {
  _FakeProjectWorkspacePort({
    required List<JsonMap> entries,
    required Map<String, String> files,
  }) : _entries = entries,
       _files = files;

  final List<JsonMap> _entries;
  final Map<String, String> _files;

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return _entries;
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return _files[relativePath];
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _FakeLlmGateway extends LlmGateway {
  _FakeLlmGateway({List<JsonMap> scriptedResults = const <JsonMap>[]})
    : _scriptedResults = List<JsonMap>.from(scriptedResults);

  final List<JsonMap> _scriptedResults;

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async {
    final result = await requestChat(
      request: ChatRequest.textPrompt(prompt: prompt, modelId: modelId),
    );
    return ValueReaders.stringValue(result['content']);
  }

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    if (_scriptedResults.isNotEmpty) {
      return _scriptedResults.removeAt(0);
    }
    return <String, Object?>{
      'ok': true,
      'content': '',
      'tool_calls': const <Object?>[],
      'message': const <String, Object?>{'role': 'assistant', 'content': ''},
    };
  }
}

class _SequencedToolExecutionPort implements ToolExecutionPort {
  _SequencedToolExecutionPort({required List<JsonMap> responses})
    : _responses = List<JsonMap>.from(responses);

  final List<JsonMap> _responses;
  final List<JsonMap> executedCalls = <JsonMap>[];

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    executedCalls.add(ValueReaders.deepCopyMap(toolCall));
    if (_responses.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'unexpected tool execution',
        'changed_paths': const <Object?>[],
      };
    }
    return _responses.removeAt(0);
  }
}

class _NoPreloadSkillRoutingPolicyService extends SkillRoutingPolicyService {
  const _NoPreloadSkillRoutingPolicyService();

  @override
  SkillActivationSignal buildActivationSignal({
    required String intent,
    required String projectType,
    required String userPrompt,
    JsonMap routeContext = const <String, Object?>{},
  }) {
    return SkillActivationSignal(
      stageId: 'mock_test',
      intent: intent,
      taskType: '',
      projectType: projectType,
      userPrompt: userPrompt,
      metadata: routeContext,
    );
  }

  @override
  SkillRoutingPolicy resolvePolicy(SkillActivationSignal signal) {
    return const SkillRoutingPolicy(
      stageId: 'mock_test',
      presets: <StageSkillPreset>[],
    );
  }

  @override
  List<JsonMap> buildPreloadToolCalls(
    SkillRoutingPolicy policy,
    SkillLoadMemory memory,
  ) {
    return const <JsonMap>[];
  }

  @override
  List<String> buildGuidanceLines(
    SkillRoutingPolicy policy, {
    SkillLoadMemory? skillLoadMemory,
  }) {
    return const <String>[];
  }
}

NarrativeDomainToolDispatchService _buildDomainToolDispatcher() {
  return NarrativeDomainToolDispatchService(
    handlers: <NarrativeDomainToolHandler>[
      SubmitChapterDeliveryHandler(),
      const SubmitNarrativeStateClaimsHandler(),
      const ProposeNarrativeProfileUpdateHandler(),
      const SubmitSemanticReviewHandler(),
      const ProposeConstraintBindingHandler(),
      const RequestProfileClarificationHandler(),
    ],
  );
}

Map<String, Object?> _validSubmissionJson({required String chapterId}) {
  return <String, Object?>{
    'submission_id': 'submission-$chapterId',
    'chapter_ref': <String, Object?>{
      'ref_type': NarrativeRefTypes.chapter,
      'ref_id': chapterId,
    },
    'segments': <Object?>[
      <String, Object?>{
        'segment_id': 'segment-$chapterId',
        'order_index': 0,
        'summary': '有效片段。',
      },
    ],
  };
}
