import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SessionGoalPromptBuilderService', () {
    test('requires present_user_options when asking user to choose', () {
      // 中文注释: 智能开局类入口应明确要求用选项工具，而不是把选择题直接吐成普通正文。
      const service = SessionGoalPromptBuilderService();

      final prompt = service.build(
        mode: SessionRecordConstants.modeSmartOpening,
      );

      expect(prompt, contains('必须调用 present_user_options'));
      expect(prompt, contains('给出选项时使用 present_user_options'));
    });
  });
}
