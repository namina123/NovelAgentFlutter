import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Session context action service', () {
    final modeService = SessionModeService();
    final messageService = SessionMessageService();
    final normalizer = SessionRecordNormalizerService(
      modeService: modeService,
      messageService: messageService,
    );
    final renderer = SessionContextRendererService(
      normalizerService: normalizer,
      messageService: messageService,
    );
    final decisionService = SessionCompactionDecisionService();
    final actionService = SessionContextActionService(
      normalizerService: normalizer,
      rendererService: renderer,
      compactionDecisionService: decisionService,
    );

    test(
      'inspectContext projects context and summary without merging contracts',
      () {
        // 中文注释: inspectContext 只做投影，不应该把压力快照、归档和工作窗口重新揉成一段文本。
        final pressureSnapshot = SessionContextPressureSnapshot(
          settings: SessionTokenBudgetSettings(
            modelContextWindowTokens: 2000,
            reservedOutputTokens: 200,
            warningThresholdRatio: 0.75,
            criticalThresholdRatio: 0.9,
          ),
          estimate: SessionTokenBudgetEstimate(
            systemPromptTokens: 120,
            messageTokens: 980,
            framingTokens: 60,
          ),
          pressureLevel: SessionContextPressureLevel.warning,
        );
        final session = <String, Object?>{
          'id': 'context-action-session',
          'title': '动作面会话',
          'mode': SessionRecordConstants.modeChapterDraft,
          'workflow_stage': 'draft',
          'public_status': '运行中',
          SessionRecordConstants.workingContextMessagesField: <Object?>[
            <String, Object?>{'role': 'user', 'content': '第一条正文'},
            <String, Object?>{'role': 'assistant', 'content': '第二条正文'},
          ],
          SessionRecordConstants.compactionSegmentsField: <Object?>[
            <String, Object?>{
              'title': '压缩段 1',
              'summary': '更早历史摘要',
              'source_message_count': 2,
              'source_message_roles': <String>['user', 'assistant'],
            },
          ],
          SessionRecordConstants.pinnedContextRefsField: <Object?>[
            'scene.anchor',
          ],
        };

        final result = actionService.inspectContext(
          session,
          options: <String, Object?>{'pressure_snapshot': pressureSnapshot},
        );
        final payload = ValueReaders.mapValue(result.payload);

        expect(result.actionKind, SessionContextActionKind.inspectContext);
        expect(result.ok, isTrue);
        expect(payload['public_summary'], contains('压力 warning'));
        expect(payload['context_markdown'], contains('【上下文压力】'));
        expect(payload['context_markdown'], contains('【压缩归档】'));
        expect(payload['context_markdown'], contains('【固定引用】'));
        expect(payload['context_markdown'], contains('【工作上下文】'));
        expect(
          ValueReaders.mapValue(
            payload['session_record'],
          )[SessionRecordConstants.workingContextMessagesField],
          hasLength(2),
        );
        expect(result.validateBasics(), isEmpty);
        expect(
          SessionContextActionResult.fromJson(result.toJson()).actionKind,
          SessionContextActionKind.inspectContext,
        );
      },
    );

    test('compactNow returns the formal compact decision package', () {
      // 中文注释: compactNow 只复用正式决策服务，不应在动作层引入新的压缩实现。
      final session = <String, Object?>{
        'id': 'compact-action-session',
        'mode': SessionRecordConstants.modeChapterDraft,
        'workflow_stage': 'draft',
        SessionRecordConstants.workingContextMessagesField:
            List<Object?>.generate(
              14,
              (index) => <String, Object?>{
                'role': 'user',
                'content': '正文内容${'x' * 400}-$index',
              },
            ),
      };
      final settings = SessionTokenBudgetSettings(
        modelContextWindowTokens: 2000,
        reservedOutputTokens: 200,
        warningThresholdRatio: 0.75,
        criticalThresholdRatio: 0.9,
      );

      final result = actionService.compactNow(
        session,
        settings: settings,
        triggerKind: SessionCompactionTriggerKind.preflightToolRound,
      );
      final payload = ValueReaders.mapValue(result.payload);
      final decision = SessionCompactionDecision.fromJson(
        ValueReaders.mapValue(payload['decision']),
      );

      expect(result.actionKind, SessionContextActionKind.compactNow);
      expect(result.ok, isTrue);
      expect(payload['should_compact'], isTrue);
      expect(decision.actionKind, SessionCompactionActionKind.compactNow);
      expect(decision.plan.keepRecentMessageCount, 6);
      expect(decision.plan.compactionMessageIndices, <int>[
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);
      expect(result.validateBasics(), isEmpty);
    });

    test(
      'clearWorkingContext keeps transcript and archive while pinning stays stable',
      () {
        // 中文注释: clear / pin / unpin 都只能改稳定引用和工作窗口，不允许损坏完整历史。
        final session = <String, Object?>{
          'id': 'clear-action-session',
          'mode': SessionRecordConstants.modeChapterDraft,
          'workflow_stage': 'draft',
          SessionRecordConstants.transcriptMessagesField: <Object?>[
            <String, Object?>{'role': 'user', 'content': '完整历史 1'},
            <String, Object?>{'role': 'assistant', 'content': '完整历史 2'},
          ],
          SessionRecordConstants.workingContextMessagesField: <Object?>[
            <String, Object?>{'role': 'user', 'content': '工作窗口 1'},
            <String, Object?>{'role': 'assistant', 'content': '工作窗口 2'},
          ],
          SessionRecordConstants.compactionSegmentsField: <Object?>[
            <String, Object?>{
              'title': '旧压缩段',
              'summary': '旧归档摘要',
              'source_message_count': 2,
            },
          ],
          SessionRecordConstants.pinnedContextRefsField: <Object?>[
            'scene.anchor',
          ],
        };

        final cleared = actionService.clearWorkingContext(
          session,
          now: '2026-06-14T10:00:00Z',
        );
        final clearedRecord = ValueReaders.mapValue(
          ValueReaders.mapValue(cleared.payload)['session_record'],
        );

        expect(
          cleared.actionKind,
          SessionContextActionKind.clearWorkingContext,
        );
        expect(
          clearedRecord[SessionRecordConstants.workingContextMessagesField],
          isEmpty,
        );
        expect(
          clearedRecord[SessionRecordConstants.legacyContextMessagesField],
          isEmpty,
        );
        expect(
          clearedRecord[SessionRecordConstants.transcriptMessagesField],
          hasLength(2),
        );
        expect(
          clearedRecord[SessionRecordConstants.compactionSegmentsField],
          hasLength(1),
        );
        expect(
          clearedRecord[SessionRecordConstants.pinnedContextRefsField],
          hasLength(1),
        );

        final pin = actionService.pinContextSegment(
          clearedRecord,
          'timeline.anchor',
          now: '2026-06-14T10:01:00Z',
        );
        final pinRecord = ValueReaders.mapValue(
          ValueReaders.mapValue(pin.payload)['session_record'],
        );
        expect(
          pinRecord[SessionRecordConstants.pinnedContextRefsField],
          <String>['scene.anchor', 'timeline.anchor'],
        );

        final pinAgain = actionService.pinContextSegment(
          pinRecord,
          'timeline.anchor',
          now: '2026-06-14T10:02:00Z',
        );
        expect(pinAgain.reason, 'context_ref_already_pinned');

        final unpin = actionService.unpinContextSegment(
          pinRecord,
          'timeline.anchor',
          now: '2026-06-14T10:03:00Z',
        );
        final unpinRecord = ValueReaders.mapValue(
          ValueReaders.mapValue(unpin.payload)['session_record'],
        );
        expect(
          unpinRecord[SessionRecordConstants.pinnedContextRefsField],
          <String>['scene.anchor'],
        );
      },
    );

    test('inspectCompactionGuidance preserves layered instruction order', () {
      // 中文注释: guidance inspect 要把分层顺序直接暴露出来，不能把它折叠成单一 prompt 字符串。
      final guidance = CompactionGuidanceContract(
        guidanceId: 'guidance.session.preflight',
        title: '发送前压缩指导',
        summary: '只压缩工作上下文，不碰完整历史。',
        rules: <String>['优先保留 pinned context。'],
        sourceScopeId: 'scope.session.preflight',
        outputPolicyId: 'policy.session.compact',
      );
      final outputPolicy = CompactionOutputPolicy(
        policyId: 'policy.session.compact',
        title: '压缩输出策略',
      );
      final sourceScope = CompactionSourceScope(
        scopeId: 'scope.session.preflight',
        sourceKinds: <String>[
          'transcript_messages',
          'working_context_messages',
        ],
      );
      final instruction = RuntimeContinuationInstructionContract(
        instructionId: 'continuation.session.resume',
        title: '恢复续跑指令',
        instruction: '续跑时先检查压缩结果。',
      );
      final frame = CompactionPromptInjectionFrame(
        systemFoundation: 'system foundation',
        projectGuidance: 'project guidance',
        compactionGuidance: guidance,
        contextPayload: 'context payload',
        currentUserPrompt: '原始用户提示词',
        runtimeContinuationInstruction: instruction,
      );

      final result = actionService.inspectCompactionGuidance(
        frame: frame,
        useRuntimeContinuationInstruction: true,
      );
      final payload = ValueReaders.mapValue(result.payload);
      final decodedFrame = CompactionPromptInjectionFrame.fromJson(
        ValueReaders.mapValue(payload['frame']),
      );

      expect(
        result.actionKind,
        SessionContextActionKind.inspectCompactionGuidance,
      );
      expect(result.ok, isTrue);
      expect(payload['ordered_section_kinds'], <Object?>[
        'system_foundation',
        'project_guidance',
        'compaction_guidance',
        'context_payload',
        'runtime_continuation_instruction',
      ]);
      expect(decodedFrame.currentUserPrompt, '原始用户提示词');
      expect(decodedFrame.compactionGuidance.summary, guidance.summary);
      expect(outputPolicy.validateBasics(), isEmpty);
      expect(sourceScope.validateBasics(), isEmpty);
      expect(instruction.validateBasics(), isEmpty);
    });
  });
}
