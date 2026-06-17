import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WritingModelReasoningProfileService', () {
    test('projects relay override for siliconflow deepseek offering', () {
      // 中文注释: 这里验证中转 offering 的 enable_thinking override 能覆盖 canonical 默认 thinking object 策略。
      final service = WritingModelReasoningProfileService();

      final result = service.resolve(
        providerId: 'siliconflow',
        modelId: 'deepseek-ai/DeepSeek-V4-Flash',
        baseUrl: 'https://api.siliconflow.cn/v1',
      );

      expect(result['supports_reasoning'], isTrue);
      expect(result['reasoning_mode_behavior'], 'hybrid_default_on');
      expect(result['reasoning_can_toggle'], isTrue);
      final toggle =
          result['reasoning_toggle_parameter_strategy'] as Map<String, Object?>;
      expect(toggle['kind'], 'boolean');
      expect(toggle['key'], 'enable_thinking');
      expect(
        result['reasoning_effort_options'],
        ['low', 'medium', 'high', 'max'],
      );
    });

    test('projects non-toggle reasoning for thinking-only models', () {
      // 中文注释: 这里验证 only-thinking 模型不会再被错误投影为可开关模型。
      final service = WritingModelReasoningProfileService();

      final result = service.resolve(
        providerId: 'moonshot',
        modelId: 'kimi-k2-thinking',
        baseUrl: 'https://platform.kimi.ai',
      );

      expect(result['supports_reasoning'], isTrue);
      expect(result['reasoning_mode_behavior'], 'thinking_only');
      expect(result['reasoning_can_toggle'], isFalse);
      expect(result['reasoning_supports_effort'], isFalse);
    });
  });
}
