import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test('uses canonical outlines workspace paths for long task planning', () {
    const service = LongTaskPlanningArtifactPathService();

    expect(service.planningOutputPaths(), <String>[
      'specs/project_spec.md',
      'outlines/story/总纲.md',
      'outlines/chapters/章节任务清单.md',
    ]);
  });
}
