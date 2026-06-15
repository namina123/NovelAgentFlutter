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

    test(
      'import article mode does not treat knowledge projection as write target',
      () {
        const service = SessionGoalPromptBuilderService();

        final prompt = service.build(
          mode: SessionRecordConstants.modeImportArticle,
        );

        expect(prompt, contains('不要直接归档到 knowledge/ 投影'));
        expect(prompt, isNot(contains('归档到 knowledge/、scenes/ 或 chapters/')));
      },
    );

    test('smart opening prompt includes tri-state acquisition contract', () {
      const service = SessionGoalPromptBuilderService();

      final prompt = service.build(
        mode: SessionRecordConstants.modeSmartOpening,
        project: const <String, Object?>{'project_type': 'novel'},
      );

      expect(prompt, contains('项目事实获取合同'));
      expect(
        prompt,
        contains('confirmed、pending_confirmation、tentative_assumption'),
      );
      expect(prompt, contains('不要静默补完长期项目事实'));
      expect(prompt, contains('不要替用户锁死主角稳定设定'));
    });

    test('continue writing prompt exposes the next chapter target hint', () {
      const service = SessionGoalPromptBuilderService();

      final prompt = service.build(
        mode: SessionRecordConstants.modeContinueWriting,
        activeDocumentPath: 'chapters/第02章_摸底.md',
        activeDocumentExcerpt: '# 第02章 摸底\n\n门里的人还没把话说完。',
      );

      expect(prompt, contains('当前打开文件指向第02章'));
      expect(prompt, contains('第03章作为续写目标'));
      expect(prompt, contains('不要重新从第02章门前动作起笔'));
    });
  });
}
