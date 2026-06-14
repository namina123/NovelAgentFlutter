import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SessionContextRendererService', () {
    final modeService = SessionModeService();
    final messageService = SessionMessageService();
    final normalizer = SessionRecordNormalizerService(
      modeService: modeService,
      messageService: messageService,
    );
    final renderer = SessionContextRendererService(
      normalizerService: normalizer,
      messageService: messageService,
      modeService: modeService,
    );

    test(
      'renders working context, archive summary, pinned refs and guidance as separate blocks',
      () {
        // 中文注释: 这里验证 renderer 只消费稳定合同，把工作上下文、归档、固定引用和压缩指导分层输出。
        final session = <String, Object?>{
          'id': 'renderer-session',
          'title': '渲染会话',
          'mode': SessionRecordConstants.modeChapterDraft,
          'workflow_stage': 'draft',
          'public_status': '创作已启动',
          SessionRecordConstants.workingContextMessagesField: <Object?>[
            <String, Object?>{'role': 'user', 'content': '工作上下文第一条'},
            <String, Object?>{'role': 'assistant', 'content': '工作上下文第二条'},
          ],
          SessionRecordConstants.legacyContextMessagesField: <Object?>[
            <String, Object?>{'role': 'user', 'content': '旧桥接内容'},
          ],
          SessionRecordConstants.compactionSegmentsField: <Object?>[
            <String, Object?>{
              'id': 'segment-1',
              'title': '压缩片段 1',
              'summary': '更早历史摘要',
              'source_message_count': 2,
              'source_message_roles': <Object?>['user', 'assistant'],
            },
          ],
          SessionRecordConstants.pinnedContextRefsField: <Object?>[
            'scene.anchor',
          ],
        };
        final pressureSnapshot = SessionContextPressureSnapshot(
          settings: SessionTokenBudgetSettings(
            modelContextWindowTokens: 8000,
            reservedOutputTokens: 1000,
            warningThresholdRatio: 0.75,
            criticalThresholdRatio: 0.9,
          ),
          estimate: SessionTokenBudgetEstimate(
            systemPromptTokens: 120,
            messageTokens: 780,
            framingTokens: 20,
            countSource: SessionTokenCountSource.conservativeEstimate,
          ),
          pressureLevel: SessionContextPressureLevel.warning,
        );
        final guidance = CompactionGuidanceContract(
          guidanceId: 'guidance.session.renderer',
          title: '发送前压缩指导',
          summary: '只压缩工作上下文，不碰完整历史。',
          rules: <String>['优先保留 pinned context。', '压缩段必须可恢复。'],
          sourceScopeId: 'scope.session.renderer',
          outputPolicyId: 'policy.session.renderer',
        );
        final outputPolicy = CompactionOutputPolicy(
          policyId: 'policy.session.renderer',
          title: '压缩输出策略',
          outputFormat: 'structured_bullets',
          maxCharacters: 1200,
          maxBulletCount: 6,
        );
        final sourceScope = CompactionSourceScope(
          scopeId: 'scope.session.renderer',
          sourceKinds: <String>[
            SessionRecordConstants.transcriptMessagesField,
            SessionRecordConstants.workingContextMessagesField,
            SessionRecordConstants.compactionSegmentsField,
          ],
        );
        final continuationInstruction = RuntimeContinuationInstructionContract(
          instructionId: 'continuation.session.renderer',
          title: '恢复续跑指令',
          instruction: '先检查压缩结果是否足以继续，再决定是否读取更多历史。',
        );

        final markdown = renderer.sessionContextMarkdown(
          session,
          options: <String, Object?>{
            'pressure_snapshot': pressureSnapshot,
            'compaction_guidance': guidance,
            'compaction_output_policy': outputPolicy,
            'compaction_source_scope': sourceScope,
            'runtime_continuation_instruction': continuationInstruction,
          },
        );
        final summary = renderer.sessionPublicSummary(
          session,
          options: <String, Object?>{'pressure_snapshot': pressureSnapshot},
        );

        expect(markdown, contains('【上下文压力】'));
        expect(markdown, contains('【压缩指导】'));
        expect(markdown, contains('【压缩归档】'));
        expect(markdown, contains('【固定引用】'));
        expect(markdown, contains('【工作上下文】'));
        expect(markdown, contains('工作上下文第一条'));
        expect(markdown, isNot(contains('旧桥接内容')));
        expect(markdown, contains('发送前压缩指导'));
        expect(markdown, contains('压缩片段 1'));
        expect(markdown, contains('scene.anchor'));
        expect(markdown, contains('恢复续跑指令'));
        expect(summary, contains('压力 warning'));
        expect(summary, contains('已用 920 / 7000 token'));
        expect(summary, contains('来源 conservative_estimate'));
        expect(summary, isNot(contains('阈值')));
        expect(summary, isNot(contains('字｜')));
      },
    );
  });
}
