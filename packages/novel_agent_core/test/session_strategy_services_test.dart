import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Session strategy services', () {
    test('default inclusion strategy excludes failed assistant messages', () {
      // 中文注释: 默认策略只允许成功助手正文进入上下文，失败提示留给展示层处理。
      final strategy = DefaultSessionMessageInclusionStrategy();

      expect(strategy.includeInContext(role: 'user'), isTrue);
      expect(strategy.includeInContext(role: 'assistant'), isTrue);
      expect(
        strategy.includeInContext(role: 'assistant', outcome: 'failure'),
        isFalse,
      );
      expect(strategy.includeInContext(role: 'system'), isFalse);
    });

    test('compression strategy resolves threshold from percent and model profile', () {
      // 中文注释: 压缩阈值策略应根据模型窗口和百分比推导真实字符阈值。
      final service = SessionCompressionStrategyService();

      final threshold = service.thresholdChars(
        strategySettings: const <String, Object?>{
          'compression_threshold_percent': 50,
        },
        modelProfile: const <String, Object?>{
          'compression_context_length': 20000,
        },
      );

      expect(threshold, 20000);
    });
  });
}
