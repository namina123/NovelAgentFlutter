import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskChapterOutputPolicyService', () {
    final service = LongTaskChapterOutputPolicyService(
      modeService: LongTaskModeService(),
    );

    test('writes sample chapter to samples for seed_to_full', () {
      final path = service.defaultOutputPath(
        mode: TaskRuntimeConstants.modeSeedToFullNovel,
        stage: 'sample',
        fileStem: '第01章_seed_to_full',
      );

      expect(path, 'samples/第01章_seed_to_full.md');
    });

    test('writes normal seed_to_full chapter to chapters', () {
      final path = service.defaultOutputPath(
        mode: TaskRuntimeConstants.modeSeedToFullNovel,
        stage: 'draft',
        fileStem: '第02章_seed_to_full',
      );

      expect(path, 'chapters/第02章_seed_to_full.md');
    });

    test('keeps human outline mode chapter oriented', () {
      final path = service.defaultOutputPath(
        mode: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        stage: 'draft',
        fileStem: '第03章_伏笔推进',
      );

      expect(path, 'chapters/第03章_伏笔推进.md');
    });

    test(
      'delegates chapter stem normalization to shared chapter path policy',
      () {
        expect(
          service.chapterFileStem(chapterNumber: 4, title: '第04章'),
          '第04章',
        );
        expect(
          service.chapterFileStem(chapterNumber: 4, title: '第04章：族中压力'),
          '第04章_族中压力',
        );
        expect(
          service.chapterFileStem(chapterNumber: 4, title: '族中压力'),
          '第04章_族中压力',
        );
        expect(service.chapterFileStem(chapterNumber: 4, title: '第4章'), '第04章');
      },
    );
  });
}
