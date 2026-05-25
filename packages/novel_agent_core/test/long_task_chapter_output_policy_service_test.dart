import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskChapterOutputPolicyService', () {
    final service = LongTaskChapterOutputPolicyService(
      modeService: LongTaskModeService(),
    );

    test('keeps sample chapter in drafts for seed_to_full', () {
      final path = service.defaultOutputPath(
        mode: TaskRuntimeConstants.modeSeedToFullNovel,
        stage: 'sample',
        fileStem: '第01章_seed_to_full',
      );

      expect(path, 'drafts/第01章_seed_to_full.md');
    });

    test('writes normal seed_to_full chapter to chapters', () {
      final path = service.defaultOutputPath(
        mode: TaskRuntimeConstants.modeSeedToFullNovel,
        stage: 'draft',
        fileStem: '第02章_seed_to_full',
      );

      expect(path, 'chapters/第02章_seed_to_full.md');
    });

    test('keeps human outline mode draft oriented', () {
      final path = service.defaultOutputPath(
        mode: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        stage: 'draft',
        fileStem: '第03章_伏笔推进',
      );

      expect(path, 'drafts/第03章_伏笔推进.md');
    });
  });
}
