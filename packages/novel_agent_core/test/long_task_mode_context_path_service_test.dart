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

    test('merges continuity persistent paths into long-task context paths', () {
      const bundle = ProjectContinuityBundle(
        id: 'continuity_main',
        displayName: '连续性主线',
        canonicalAssetReferences: <ContinuityAssetReference>[
          ContinuityAssetReference(
            assetKind: ContinuityAssetKind.worldRuleSet,
            assetId: 'global_rules',
            sourcePath: 'analysis/continuity/bible.md',
          ),
        ],
        scopes: <ContinuationScope>[
          ContinuationScope(
            id: 'global',
            displayName: '全局',
            kind: ContinuationScopeKind.global,
          ),
        ],
        frames: <ContinuityFrame>[
          ContinuityFrame(
            id: 'mainline',
            displayName: '主线',
            scopeId: 'global',
            metadata: <String, Object?>{
              'tail_window_paths': <Object?>['summaries/tail_window.md'],
            },
          ),
        ],
        defaultFrameId: 'mainline',
      );

      final paths = service.persistentContextPaths(
        TaskRuntimeConstants.modeSeedToFullNovel,
        const <String, Object?>{
          'persistent_context_paths': <Object?>['styles/default.md'],
        },
        continuityBundle: bundle,
      );

      expect(paths, <String>[
        'styles/default.md',
        'analysis/continuity/bible.md',
        'summaries/tail_window.md',
      ]);
    });
  });
}
