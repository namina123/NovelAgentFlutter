import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('RuntimeBaselineExecutionModeService', () {
    final service = RuntimeBaselineExecutionModeService();

    test('maps continuous autonomous baseline to seed runtime mode', () {
      expect(
        service.resolveRuntimeMode(runtimeBaselineId: 'continuous_autonomous'),
        TaskRuntimeConstants.modeSeedToFullNovel,
      );
    });

    test(
      'maps chapter collaboration autorun baseline to outline runtime mode',
      () {
        expect(
          service.resolveRuntimeMode(
            runtimeBaselineId: 'chapter_collaboration_autorun',
          ),
          TaskRuntimeConstants.modeHumanOutlineAiDraft,
        );
      },
    );
  });
}
