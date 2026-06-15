import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectFactAcquisitionContractService', () {
    const service = ProjectFactAcquisitionContractService();

    test(
      'interactive opening contract keeps long-term facts out of tentative persistence',
      () {
        final contract = service.build(
          workflowId: 'interactive_opening',
          projectTypeId: 'novel',
        );
        final markdown = contract.renderMarkdown();

        expect(markdown, contains('pending_confirmation'));
        expect(markdown, contains('tentative_assumption'));
        expect(markdown, contains('主角稳定性格与处事风格'));
        expect(markdown, contains('不要静默补完长期项目事实'));
        expect(markdown, contains('不能直接落成项目规格'));
      },
    );

    test(
      'long task opening contract blocks queue expansion from tentative assumptions',
      () {
        final contract = service.build(
          workflowId: 'long_task_opening',
          projectTypeId: 'long_novel',
        );
        final markdown = contract.renderMarkdown();

        expect(markdown, contains('核心承诺'));
        expect(markdown, contains('不能停留在 tentative_assumption'));
        expect(markdown, contains('不要直接展开依赖这些候选的庞大任务链'));
        expect(markdown, contains('specs、总纲、卷纲、章纲或任务链'));
      },
    );
  });
}
