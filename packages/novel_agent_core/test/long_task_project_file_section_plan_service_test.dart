import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskProjectFileSectionPlanService', () {
    final service = LongTaskProjectFileSectionPlanService(
      pathPolicyService: LongTaskPathPolicyService(),
    );

    test(
      'splits persistent paths and task source paths into planned sections',
      () {
        final sections = service.build(const <String, Object?>{
          'source_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
            'styles/seed_autopilot_style.md',
            'outline/总纲.md',
          ],
          'metadata': <String, Object?>{
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
              'styles/seed_autopilot_style.md',
            ],
          },
        });

        expect(sections, hasLength(2));
        expect(
          ValueReaders.stringValue(sections.first['id']),
          'task_persistent_context',
        );
        expect(
          ValueReaders.stringList(sections.first['paths']),
          contains('styles/seed_autopilot_style.md'),
        );
        expect(
          ValueReaders.stringValue(sections.last['id']),
          'task_source_paths',
        );
        expect(ValueReaders.stringList(sections.last['paths']), <String>[
          'outline/总纲.md',
        ]);
      },
    );

    test('adds continuity-specific sections before generic task sources', () {
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
          ContinuationScope(
            id: 'world_a',
            displayName: '世界A',
            kind: ContinuationScopeKind.world,
            parentScopeId: 'global',
          ),
        ],
        scopeOverlays: <ContinuationScopeOverlay>[
          ContinuationScopeOverlay(
            id: 'world_a_overlay',
            scopeId: 'world_a',
            displayName: '世界A覆盖',
            priority: 10,
            metadata: <String, Object?>{
              'context_paths': <Object?>[
                'analysis/continuity/world_a_rules.md',
              ],
            },
          ),
        ],
        frames: <ContinuityFrame>[
          ContinuityFrame(
            id: 'mainline',
            displayName: '主线',
            scopeId: 'world_a',
            stateReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.characterStageStateRecord,
                assetId: 'hero_state',
                sourcePath: 'tracking/continuity/states/hero_state.md',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
            metadata: <String, Object?>{
              'tail_window_paths': <Object?>['summaries/tail_window.md'],
            },
          ),
        ],
        defaultFrameId: 'mainline',
      );

      final sections = service.build(const <String, Object?>{
        'source_paths': <Object?>[
          'analysis/continuity/bible.md',
          'outline/总纲.md',
        ],
        'metadata': <String, Object?>{
          'persistent_context_paths': <Object?>['styles/default.md'],
        },
      }, continuityBundle: bundle);

      expect(
        ValueReaders.stringValue(sections[0]['id']),
        'continuity_global_context',
      );
      expect(ValueReaders.stringList(sections[0]['paths']), <String>[
        'analysis/continuity/bible.md',
      ]);
      expect(
        ValueReaders.stringValue(sections[1]['id']),
        'continuity_scope_overlays',
      );
      expect(ValueReaders.stringList(sections[1]['paths']), <String>[
        'analysis/continuity/world_a_rules.md',
      ]);
      expect(
        ValueReaders.stringValue(sections[2]['id']),
        'continuity_runtime_state',
      );
      expect(ValueReaders.stringList(sections[2]['paths']), <String>[
        'tracking/continuity/states/hero_state.md',
      ]);
      expect(
        ValueReaders.stringValue(sections[3]['id']),
        'continuity_tail_window',
      );
      expect(ValueReaders.stringList(sections[3]['paths']), <String>[
        'summaries/tail_window.md',
      ]);
      expect(
        ValueReaders.stringValue(sections[4]['id']),
        'task_persistent_context',
      );
      expect(ValueReaders.stringList(sections[4]['paths']), <String>[
        'styles/default.md',
      ]);
      expect(ValueReaders.stringValue(sections[5]['id']), 'task_source_paths');
      expect(ValueReaders.stringList(sections[5]['paths']), <String>[
        'outline/总纲.md',
      ]);
    });
  });
}
