import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolStrategyService', () {
    test('keeps dangerous tools disabled by default', () {
      // 中文注释: 这里验证默认策略不会把危险工具直接开放给模型。
      final service = ToolStrategyService();

      final settings = service.defaultSettings();
      final toolEnabled = settings['tool_enabled'] as Map<String, Object?>;

      expect(toolEnabled['delete_project_file'], isFalse);
      expect(toolEnabled['restore_backup'], isFalse);
    });

    test('forces present_user_options only for matching intent', () {
      // 中文注释: 这里验证请求级策略只在选项型意图下要求工具选择，不会影响普通创作轮次。
      final service = ToolStrategyService();
      final settings = service.normalize(<String, Object?>{
        'force_tool_choice': true,
      });

      final result = service.requestOptionsForIntent(settings, 'user_options');

      expect(result['force_tool_choice'], isTrue);
      expect(result['preferred_tool'], 'present_user_options');
    });
  });
}
