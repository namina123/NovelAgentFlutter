import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuityRuntimeResolverService', () {
    const service = ContinuityRuntimeResolverService();

    test('resolves ordinary single-line continuity conservatively', () {
      const bundle = ProjectContinuityBundle(
        id: 'ordinary',
        displayName: 'Ordinary',
        canonicalAssetReferences: <ContinuityAssetReference>[
          ContinuityAssetReference(
            assetKind: ContinuityAssetKind.characterProfile,
            assetId: 'hero',
          ),
        ],
        scopes: <ContinuationScope>[
          ContinuationScope(
            id: 'global',
            displayName: 'Global',
            kind: ContinuationScopeKind.global,
          ),
        ],
        frames: <ContinuityFrame>[
          ContinuityFrame(
            id: 'mainline',
            displayName: 'Mainline',
            scopeId: 'global',
            stateReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.characterStageStateRecord,
                assetId: 'hero-main',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
          ),
        ],
        defaultFrameId: 'mainline',
      );

      final result = service.resolve(bundle);

      expect(result.scopeChain.activeScope?.id, 'global');
      expect(result.scopeChain.scopeIds, <String>['global']);
      expect(result.activeFrame.frame?.id, 'mainline');
      expect(result.mechanicProfile.id, 'default_continuity');
      expect(result.overlayAssetReferences, isEmpty);
      expect(result.stateAssetReferences.map((item) => item.assetId), <String>[
        'hero-main',
      ]);
      expect(result.inheritsParentState, isFalse);
      expect(result.inheritsParentMemory, isFalse);
    });

    test('applies world overlays from parent-to-child scope chain', () {
      const bundle = ProjectContinuityBundle(
        id: 'worlds',
        displayName: 'Worlds',
        scopes: <ContinuationScope>[
          ContinuationScope(
            id: 'global',
            displayName: 'Global',
            kind: ContinuationScopeKind.global,
          ),
          ContinuationScope(
            id: 'world-a',
            displayName: 'World A',
            kind: ContinuationScopeKind.world,
            parentScopeId: 'global',
          ),
        ],
        scopeOverlays: <ContinuationScopeOverlay>[
          ContinuationScopeOverlay(
            id: 'global-overlay',
            scopeId: 'global',
            displayName: 'Global Overlay',
            priority: 5,
            assetReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.worldRuleSet,
                assetId: 'global-rules',
                role: ContinuityAssetReferenceRole.scopeOverlay,
              ),
            ],
          ),
          ContinuationScopeOverlay(
            id: 'world-a-overlay',
            scopeId: 'world-a',
            displayName: 'World A Overlay',
            priority: 10,
            assetReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.relationshipRecord,
                assetId: 'world-a-relationship',
                role: ContinuityAssetReferenceRole.scopeOverlay,
              ),
            ],
          ),
        ],
        frames: <ContinuityFrame>[
          ContinuityFrame(
            id: 'world-a-frame',
            displayName: 'World A Frame',
            scopeId: 'world-a',
          ),
        ],
        defaultFrameId: 'world-a-frame',
      );

      final result = service.resolve(bundle);

      expect(result.scopeChain.scopeIds, <String>['global', 'world-a']);
      expect(
        result.overlayAssetReferences.map((item) => item.assetId),
        <String>['global-rules', 'world-a-relationship'],
      );
    });

    test('inherits parent state for forked frames when mechanic allows it', () {
      const bundle = ProjectContinuityBundle(
        id: 'forks',
        displayName: 'Forks',
        scopes: <ContinuationScope>[
          ContinuationScope(
            id: 'global',
            displayName: 'Global',
            kind: ContinuationScopeKind.global,
          ),
        ],
        mechanicProfiles: <ContinuityMechanicProfile>[
          ContinuityMechanicProfile(
            id: 'fork-profile',
            displayName: 'Fork Profile',
            stateMode: ContinuityStateMode.accumulative,
            memoryMode: ContinuityMemoryMode.continuous,
            branchMode: ContinuityBranchMode.forkOnTransition,
          ),
        ],
        frames: <ContinuityFrame>[
          ContinuityFrame(
            id: 'base',
            displayName: 'Base',
            scopeId: 'global',
            stateReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.characterStageStateRecord,
                assetId: 'state-base',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
          ),
          ContinuityFrame(
            id: 'fork-1',
            displayName: 'Fork 1',
            scopeId: 'global',
            parentFrameId: 'base',
            mechanicProfileId: 'fork-profile',
            relation: ContinuityFrameRelation.fork,
            stateReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.characterStageStateRecord,
                assetId: 'state-fork',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
          ),
        ],
      );

      final result = service.resolve(bundle, frameId: 'fork-1');

      expect(result.activeFrame.frameChain.map((frame) => frame.id), <String>[
        'base',
        'fork-1',
      ]);
      expect(result.stateAssetReferences.map((item) => item.assetId), <String>[
        'state-base',
        'state-fork',
      ]);
      expect(result.inheritsParentState, isTrue);
      expect(result.inheritsParentMemory, isTrue);
      expect(result.branchesFromParent, isTrue);
    });

    test('drops parent state and memory for reset frames', () {
      const bundle = ProjectContinuityBundle(
        id: 'reset',
        displayName: 'Reset',
        scopes: <ContinuationScope>[
          ContinuationScope(
            id: 'global',
            displayName: 'Global',
            kind: ContinuationScopeKind.global,
          ),
        ],
        mechanicProfiles: <ContinuityMechanicProfile>[
          ContinuityMechanicProfile(
            id: 'reset-profile',
            displayName: 'Reset Profile',
            stateMode: ContinuityStateMode.accumulative,
            memoryMode: ContinuityMemoryMode.continuous,
            causalMode: ContinuityCausalMode.replayAware,
          ),
        ],
        frames: <ContinuityFrame>[
          ContinuityFrame(
            id: 'loop-1',
            displayName: 'Loop 1',
            scopeId: 'global',
            stateReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.characterStageStateRecord,
                assetId: 'state-loop-1',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
          ),
          ContinuityFrame(
            id: 'loop-2',
            displayName: 'Loop 2',
            scopeId: 'global',
            parentFrameId: 'loop-1',
            mechanicProfileId: 'reset-profile',
            relation: ContinuityFrameRelation.reset,
            stateReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.characterStageStateRecord,
                assetId: 'state-loop-2',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
          ),
        ],
      );

      final result = service.resolve(bundle, frameId: 'loop-2');

      expect(result.stateAssetReferences.map((item) => item.assetId), <String>[
        'state-loop-2',
      ]);
      expect(result.inheritsParentState, isFalse);
      expect(result.inheritsParentMemory, isFalse);
      expect(result.replayAware, isTrue);
    });
  });
}
