import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskContinuityContextProjectionService', () {
    final service = LongTaskContinuityContextProjectionService(
      pathPolicyService: LongTaskPathPolicyService(),
    );

    test('projects canonical, overlay, state, and tail-window paths', () {
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
            assetReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.relationshipRecord,
                assetId: 'relationship_a',
                sourcePath: 'analysis/continuity/world_a_relationships.md',
                role: ContinuityAssetReferenceRole.scopeOverlay,
              ),
            ],
            metadata: <String, Object?>{
              'context_paths': <Object?>[
                'analysis/continuity/world_a_rules.md',
              ],
            },
          ),
        ],
        mechanicProfiles: <ContinuityMechanicProfile>[
          ContinuityMechanicProfile(id: 'default_profile', displayName: '默认机制'),
        ],
        frames: <ContinuityFrame>[
          ContinuityFrame(
            id: 'mainline',
            displayName: '主线',
            scopeId: 'world_a',
            mechanicProfileId: 'default_profile',
            stateReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.characterStageStateRecord,
                assetId: 'hero_state',
                sourcePath: 'tracking/continuity/states/hero_state.md',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
            metadata: <String, Object?>{
              'context_paths': <Object?>['analysis/continuity/state_digest.md'],
              'tail_window_paths': <Object?>['summaries/tail_window.md'],
            },
          ),
        ],
        defaultMechanicProfileId: 'default_profile',
        defaultFrameId: 'mainline',
        metadata: <String, Object?>{
          'context_paths': <Object?>['analysis/continuity/global_manifest.md'],
          'tail_window_paths': <Object?>['summaries/global_tail.md'],
        },
      );

      final projection = service.project(bundle);

      expect(projection.scopeIds, <String>['global', 'world_a']);
      expect(projection.frameId, 'mainline');
      expect(projection.canonicalPaths, <String>[
        'analysis/continuity/global_manifest.md',
        'analysis/continuity/bible.md',
      ]);
      expect(projection.overlayPaths, <String>[
        'analysis/continuity/world_a_rules.md',
        'analysis/continuity/world_a_relationships.md',
      ]);
      expect(projection.statePaths, <String>[
        'analysis/continuity/state_digest.md',
        'tracking/continuity/states/hero_state.md',
      ]);
      expect(projection.tailWindowPaths, <String>[
        'summaries/global_tail.md',
        'summaries/tail_window.md',
      ]);
    });
  });
}
