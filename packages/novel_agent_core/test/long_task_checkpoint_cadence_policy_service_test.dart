import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointCadencePolicyService', () {
    const service = LongTaskCheckpointCadencePolicyService();

    test('builds autorun baseline cadence without manual checkpoint interval', () {
      // 中文注释: 逐章协作自动推进基线不应凭空插回人工 checkpoint，只提供 batch 级节奏基线。
      final policy = service.policyForMode(
        TaskRuntimeConstants.modeHumanOutlineAiDraft,
        options: const <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
        },
      );

      expect(policy.checkpointPolicy, 'after_chapter_gate');
      expect(policy.baseCheckpointInterval, 0);
      expect(policy.effectiveCheckpointInterval, 0);
      expect(policy.baseBatchSteps, 4);
      expect(policy.baseBatchSeconds, 10800);
      expect(policy.validateBasics(), isEmpty);
    });

    test('escalates consecutive medium risk into high tightening', () {
      // 中文注释: 连续结构化中风险要自动升级为更紧的 batch/cadence，而不是只看最后一步。
      final policy = service.policyForRuntime(
        TaskRuntimeConstants.modeHumanOutlineAiDraft,
        record: <String, Object?>{
          'last_checkpoint_review_severity': 'medium',
          'last_writing_execution_category': 'waiting_user',
          'last_information_risk_category': 'checkpoint_user',
          'steps': const <Object?>[
            <String, Object?>{
              'checkpoint_review_severity': 'medium',
              'writing_execution_category': 'success',
              'information_risk_category': 'accept',
            },
            <String, Object?>{
              'checkpoint_review_severity': 'medium',
              'writing_execution_category': 'waiting_user',
              'information_risk_category': 'checkpoint_user',
            },
          ],
        },
        options: const <String, Object?>{
          'checkpoint_interval': 3,
          'max_steps': 4,
          'max_seconds': 7200,
        },
      );

      expect(policy.riskLevel, LongTaskCheckpointCadenceRiskLevels.high);
      expect(policy.trailingRiskCount, 2);
      expect(policy.effectiveCheckpointInterval, 1);
      expect(policy.effectiveBatchSteps, 1);
      expect(policy.effectiveBatchSeconds, 3600);
      expect(policy.tighteningApplied, isTrue);
      expect(policy.reasons, contains('consecutive_structured_risk_2'));
    });

    test('keeps autorun interval at zero while tightening critical batch', () {
      // 中文注释: autorun 模式在高风险时只能缩短批次，不能重新制造人工 checkpoint 任务。
      final policy = service.policyForRuntime(
        TaskRuntimeConstants.modeHumanOutlineAiDraft,
        record: <String, Object?>{
          'last_checkpoint_review_severity': 'critical',
          'last_writing_execution_category': 'technical_failed',
          'last_information_risk_category': 'manual_attention',
          'steps': const <Object?>[
            <String, Object?>{
              'checkpoint_review_severity': 'critical',
              'writing_execution_category': 'technical_failed',
              'information_risk_category': 'manual_attention',
            },
          ],
        },
        options: const <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'max_steps': 4,
          'max_seconds': 10800,
        },
      );

      expect(policy.riskLevel, LongTaskCheckpointCadenceRiskLevels.critical);
      expect(policy.effectiveCheckpointInterval, 0);
      expect(policy.effectiveBatchSteps, 1);
      expect(policy.effectiveBatchSeconds, 1800);
      expect(policy.tightenAfterChapter, isTrue);
    });
  });
}
