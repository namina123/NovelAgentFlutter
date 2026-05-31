import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExposurePolicyService', () {
    const service = ToolExposurePolicyService();

    test('exposes start_long_task_run only for long task projects', () {
      expect(
        service.isToolExposed(
          'start_long_task_run',
          hostPlatform: HostPlatform.windows,
          projectType: 'long_novel',
        ),
        isTrue,
      );
      expect(
        service.isToolExposed(
          'start_long_task_run',
          hostPlatform: HostPlatform.windows,
          projectType: 'novel',
        ),
        isFalse,
      );
    });

    test('hides start_long_task_run from sub agents', () {
      expect(
        service.isToolExposed(
          'start_long_task_run',
          hostPlatform: HostPlatform.windows,
          projectType: 'long_novel',
          isSubAgent: true,
        ),
        isFalse,
      );
    });
  });
}
