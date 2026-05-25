import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskModeContextPathService', () {
    final modeService = LongTaskModeService();
    final pathPolicyService = LongTaskPathPolicyService();
    final service = LongTaskModeContextPathService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );

    test('uses persistent_context_paths when provided', () {
      final paths = service.persistentContextPaths(
        TaskRuntimeConstants.modeSeedToFullNovel,
        const <String, Object?>{
          'persistent_context_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
            'styles/seed_autopilot_style.md',
          ],
          'source_paths': <Object?>['outline/总纲.md'],
        },
      );

      expect(paths, <String>[
        'tracking/modes/seed_autopilot_novel/guidance.md',
        'styles/seed_autopilot_style.md',
      ]);
    });

    test(
      'merges persistent paths into task source paths without duplicates',
      () {
        final paths = service.mergeTaskSourcePaths(
          TaskRuntimeConstants.modeHumanOutlineAiDraft,
          const <String, Object?>{
            'persistent_context_paths': <Object?>[
              'tracking/modes/full_outline_consensus/guidance.md',
              'outline/full_outline_consensus_overview.md',
            ],
          },
          const <Object?>[
            'outline/full_outline_consensus_overview.md',
            'chapter_outlines/章节任务清单.md',
          ],
        );

        expect(paths, <String>[
          'tracking/modes/full_outline_consensus/guidance.md',
          'outline/full_outline_consensus_overview.md',
          'chapter_outlines/章节任务清单.md',
        ]);
      },
    );
  });
}
