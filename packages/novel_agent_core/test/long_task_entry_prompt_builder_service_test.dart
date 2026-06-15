import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskEntryPromptBuilderService', () {
    test(
      'create queue prompt requires option-style staged collection before queue creation',
      () {
        const service = LongTaskEntryPromptBuilderService();

        final prompt = service.build(
          actionId: 'long_task.create_queue',
          payload: const <String, Object?>{'mode': 'seed_autopilot_novel'},
        );

        expect(prompt, contains('必须调用 present_user_options'));
        expect(prompt, contains('一次只确认一个维度'));
        expect(prompt, contains('2-4 个清晰选项'));
        expect(prompt, contains('每轮问题都允许用户直接自由补充'));
        expect(prompt, contains('不要直接生成庞大任务链'));
        expect(prompt, contains('项目事实获取合同'));
        expect(prompt, contains('pending_confirmation'));
        expect(prompt, contains('核心承诺、世界边界、主角驱动力'));
      },
    );
  });
}
