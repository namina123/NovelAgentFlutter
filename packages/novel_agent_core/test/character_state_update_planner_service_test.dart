import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('CharacterStateUpdatePlannerService', () {
    test('merges request into stable profile and latest state snapshot', () {
      const service = CharacterStateUpdatePlannerService();
      const existing = CharacterProfile(
        id: 'hero_alpha',
        displayName: '林澈',
        summary: '主角，冷静克制。',
        currentStatus: '潜伏中',
        currentStateSummary: '上一章刚潜入敌营。',
        latestStageLabel: '第2章后',
        latestUpdatedAt: '2026-05-25T12:00:00Z',
        latestSourcePaths: <String>['chapters/ch02.md'],
        storyRole: '主角',
      );

      final plan = service.plan(
        request: const CharacterStateUpdateRequest(
          name: '林澈',
          status: '身份暴露前夜',
          role: '主角',
          content: '他已经拿到关键情报，但也意识到自己的掩护即将失效。',
          stageId: 'chapter_03',
          stageLabel: '第3章后',
          sourcePaths: <String>['chapters/ch03.md'],
          relatedTimelineIds: <String>['timeline.chapter03.break'],
        ),
        existingProfile: existing,
        updatedAt: '2026-05-26T08:00:00Z',
      );

      expect(plan.profile.id, 'hero_alpha');
      expect(plan.profile.displayName, '林澈');
      expect(plan.profile.summary, '主角，冷静克制。');
      expect(plan.profile.currentStatus, '身份暴露前夜');
      expect(plan.profile.currentStateSummary, contains('关键情报'));
      expect(plan.profile.latestStageLabel, '第3章后');
      expect(plan.profile.latestUpdatedAt, '2026-05-26T08:00:00Z');
      expect(plan.profile.latestSourcePaths, <String>['chapters/ch03.md']);
      expect(plan.latestState.characterId, 'hero_alpha');
      expect(plan.latestState.id, 'hero_alpha.chapter_03');
      expect(plan.latestState.relatedTimelineIds, <String>[
        'timeline.chapter03.break',
      ]);
    });

    test(
      'derives stable id from name when no existing profile is available',
      () {
        const service = CharacterStateUpdatePlannerService();

        final plan = service.plan(
          request: const CharacterStateUpdateRequest(name: '苏九', status: '刚入城'),
          updatedAt: '2026-05-26T09:00:00Z',
        );

        expect(plan.profile.id, '苏九');
        expect(plan.profile.summary, '刚入城');
        expect(plan.latestState.id, '苏九.latest');
      },
    );
  });
}
