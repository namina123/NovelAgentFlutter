import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectContinuityBundle contracts', () {
    test(
      'can express canonical facts, scope overlays, and frame state refs',
      () {
        const protagonist = ContinuityAssetReference(
          assetKind: ContinuityAssetKind.characterProfile,
          assetId: 'hero',
          displayName: 'Hero',
        );
        const worldRules = ContinuityAssetReference(
          assetKind: ContinuityAssetKind.worldRuleSet,
          assetId: 'world-main',
          displayName: 'Main World Rules',
        );
        const latestState = ContinuityAssetReference(
          assetKind: ContinuityAssetKind.characterStageStateRecord,
          assetId: 'hero-state-arc-3',
          role: ContinuityAssetReferenceRole.runtimeState,
          displayName: 'Hero Arc 3 State',
        );
        const globalScope = ContinuationScope(
          id: 'global',
          displayName: 'Global',
          kind: ContinuationScopeKind.global,
        );
        const routeScope = ContinuationScope(
          id: 'route-a',
          displayName: 'Route A',
          kind: ContinuationScopeKind.route,
          parentScopeId: 'global',
          tags: <String>['branch'],
        );
        const routeOverlay = ContinuationScopeOverlay(
          id: 'route-a-overlay',
          scopeId: 'route-a',
          displayName: 'Route A Overlay',
          priority: 20,
          assetReferences: <ContinuityAssetReference>[
            ContinuityAssetReference(
              assetKind: ContinuityAssetKind.relationshipRecord,
              assetId: 'hero-rival-route-a',
              role: ContinuityAssetReferenceRole.scopeOverlay,
            ),
          ],
        );
        const mechanic = ContinuityMechanicProfile(
          id: 'death-return',
          displayName: 'Death Return',
          memoryMode: ContinuityMemoryMode.protagonistOnly,
          stateMode: ContinuityStateMode.partialCarryOver,
          causalMode: ContinuityCausalMode.replayAware,
          branchMode: ContinuityBranchMode.forkOnTransition,
        );
        const frame = ContinuityFrame(
          id: 'loop-2',
          displayName: 'Loop 2',
          scopeId: 'route-a',
          parentFrameId: 'loop-1',
          mechanicProfileId: 'death-return',
          relation: ContinuityFrameRelation.replay,
          stateReferences: <ContinuityAssetReference>[latestState],
        );

        const bundle = ProjectContinuityBundle(
          id: 'bundle-main',
          displayName: 'Main Continuity',
          coverage: ContinuityCoverage(
            sourceLabel: 'Imported Novel',
            sourcePaths: <String>['drafts/source.md'],
            chapterStart: 1,
            chapterEnd: 120,
            isPartial: true,
            inferredSections: <String>['route_a_history'],
          ),
          canonicalAssetReferences: <ContinuityAssetReference>[
            protagonist,
            worldRules,
          ],
          scopes: <ContinuationScope>[globalScope, routeScope],
          scopeOverlays: <ContinuationScopeOverlay>[routeOverlay],
          mechanicProfiles: <ContinuityMechanicProfile>[mechanic],
          frames: <ContinuityFrame>[frame],
          defaultMechanicProfileId: 'death-return',
          defaultFrameId: 'loop-2',
        );

        expect(bundle.canonicalAssetReferences, hasLength(2));
        expect(
          bundle.scopeOverlays.single.assetReferences.single.role,
          ContinuityAssetReferenceRole.scopeOverlay,
        );
        expect(
          bundle.frames.single.stateReferences.single.role,
          ContinuityAssetReferenceRole.runtimeState,
        );
        expect(bundle.scopes.last.parentScopeId, 'global');
        expect(
          bundle.mechanicProfiles.single.branchMode,
          ContinuityBranchMode.forkOnTransition,
        );
        expect(bundle.coverage.isPartial, isTrue);
      },
    );

    test(
      'provides conservative defaults for ordinary single-line projects',
      () {
        const bundle = ProjectContinuityBundle(
          id: 'ordinary',
          displayName: 'Ordinary Project',
        );
        const mechanic = ContinuityMechanicProfile(
          id: 'default',
          displayName: 'Default Continuity',
        );
        const frame = ContinuityFrame(
          id: 'mainline',
          displayName: 'Mainline',
          scopeId: 'global',
        );

        expect(bundle.coverage.chapterStart, 0);
        expect(bundle.canonicalAssetReferences, isEmpty);
        expect(mechanic.identityMode, ContinuityIdentityMode.stable);
        expect(mechanic.memoryMode, ContinuityMemoryMode.continuous);
        expect(mechanic.stateMode, ContinuityStateMode.accumulative);
        expect(mechanic.branchMode, ContinuityBranchMode.singleLine);
        expect(frame.relation, ContinuityFrameRelation.sameLine);
      },
    );
  });
}
