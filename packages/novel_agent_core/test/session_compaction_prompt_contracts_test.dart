import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Compaction prompt contracts', () {
    test(
      'round-trips layered compaction prompt contracts without merging user prompt',
      () {
        // 中文注释: 这里验证 guidance、output policy、source scope 和 continuation instruction 都保持独立层级。
        final guidance = CompactionGuidanceContract(
          guidanceId: 'guidance.session.preflight',
          title: '发送前压缩指导',
          summary: '只压缩工作上下文，不碰完整历史。',
          rules: <String>['优先保留 pinned context。', '压缩段必须可恢复。'],
          sourceScopeId: 'scope.session.preflight',
          outputPolicyId: 'policy.session.compact',
        );
        final outputPolicy = CompactionOutputPolicy(
          policyId: 'policy.session.compact',
          title: '压缩输出策略',
          outputFormat: 'structured_bullets',
          maxCharacters: 1200,
          maxBulletCount: 6,
        );
        final sourceScope = CompactionSourceScope(
          scopeId: 'scope.session.preflight',
          sourceKinds: <String>[
            'transcript_messages',
            'working_context_messages',
            'compaction_segments',
          ],
          allowLegacyContextBridge: true,
          allowCurrentUserPrompt: true,
          allowRuntimeContinuationInstruction: true,
        );
        final continuationInstruction = RuntimeContinuationInstructionContract(
          instructionId: 'continuation.session.resume',
          title: '恢复续跑指令',
          instruction: '续跑时先检查压缩结果是否足以继续，再决定是否读取更多历史。',
          triggerKinds: <String>[
            'resume_before_send',
            'resume_before_tool_round',
          ],
        );
        final frame = CompactionPromptInjectionFrame(
          systemFoundation: 'system foundation',
          projectGuidance: 'project guidance',
          compactionGuidance: guidance,
          contextPayload: 'context payload',
          currentUserPrompt: '用户原始提示词',
          runtimeContinuationInstruction: continuationInstruction,
        );

        expect(guidance.validateBasics(), isEmpty);
        expect(outputPolicy.validateBasics(), isEmpty);
        expect(sourceScope.validateBasics(), isEmpty);
        expect(continuationInstruction.validateBasics(), isEmpty);
        expect(frame.validateBasics(), isEmpty);

        expect(guidance.toJson(), containsPair('summary', '只压缩工作上下文，不碰完整历史。'));
        expect(outputPolicy.toJson(), containsPair('max_characters', 1200));
        expect(
          sourceScope.toJson(),
          containsPair('allow_runtime_continuation_instruction', isTrue),
        );
        expect(
          continuationInstruction.toJson(),
          containsPair('instruction_id', 'continuation.session.resume'),
        );

        final decodedGuidance = CompactionGuidanceContract.fromJson(
          guidance.toJson(),
        );
        final decodedOutputPolicy = CompactionOutputPolicy.fromJson(
          outputPolicy.toJson(),
        );
        final decodedSourceScope = CompactionSourceScope.fromJson(
          sourceScope.toJson(),
        );
        final decodedContinuationInstruction =
            RuntimeContinuationInstructionContract.fromJson(
              continuationInstruction.toJson(),
            );
        final decodedFrame = CompactionPromptInjectionFrame.fromJson(
          frame.toJson(),
        );

        expect(decodedGuidance.guidanceId, guidance.guidanceId);
        expect(decodedGuidance.rules, guidance.rules);
        expect(decodedOutputPolicy.policyId, outputPolicy.policyId);
        expect(decodedOutputPolicy.maxCharacters, 1200);
        expect(decodedSourceScope.scopeId, sourceScope.scopeId);
        expect(decodedSourceScope.sourceKinds, <String>[
          'transcript_messages',
          'working_context_messages',
          'compaction_segments',
        ]);
        expect(
          decodedContinuationInstruction.instruction,
          continuationInstruction.instruction,
        );
        expect(decodedFrame.currentUserPrompt, '用户原始提示词');
        expect(decodedFrame.compactionGuidance.summary, guidance.summary);
        expect(decodedFrame.runtimeContinuationInstruction, isNotNull);
        expect(
          decodedFrame.runtimeContinuationInstruction!.instructionId,
          continuationInstruction.instructionId,
        );
        expect(decodedFrame.currentUserPrompt, isNot(contains('发送前压缩指导')));
        expect(
          decodedFrame.orderedSectionKinds(),
          <CompactionPromptInjectionSectionKind>[
            CompactionPromptInjectionSectionKind.systemFoundation,
            CompactionPromptInjectionSectionKind.projectGuidance,
            CompactionPromptInjectionSectionKind.compactionGuidance,
            CompactionPromptInjectionSectionKind.contextPayload,
            CompactionPromptInjectionSectionKind.currentUserPrompt,
          ],
        );
        expect(
          decodedFrame.orderedSectionKinds(
            useRuntimeContinuationInstruction: true,
          ),
          <CompactionPromptInjectionSectionKind>[
            CompactionPromptInjectionSectionKind.systemFoundation,
            CompactionPromptInjectionSectionKind.projectGuidance,
            CompactionPromptInjectionSectionKind.compactionGuidance,
            CompactionPromptInjectionSectionKind.contextPayload,
            CompactionPromptInjectionSectionKind.runtimeContinuationInstruction,
          ],
        );
      },
    );

    test('keeps injection section kinds stable as JSON values', () {
      // 中文注释: 注入分段标识是协议级字符串，必须能稳定往返。
      expect(
        CompactionPromptInjectionSectionKind.compactionGuidance.toJsonValue(),
        'compaction_guidance',
      );
      expect(
        CompactionPromptInjectionSectionKind.fromJsonValue(
          'runtime_continuation_instruction',
        ),
        CompactionPromptInjectionSectionKind.runtimeContinuationInstruction,
      );
    });
  });
}
