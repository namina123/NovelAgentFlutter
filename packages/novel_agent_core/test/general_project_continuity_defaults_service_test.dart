import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('GeneralProjectContinuityDefaultsService', () {
    const service = GeneralProjectContinuityDefaultsService();

    test('builds conservative single-line defaults for ordinary projects', () {
      const project = ProjectDescriptor(
        id: 'novel_1',
        name: '普通小说',
        rootPath: 'D:/tmp/novel_1',
        projectType: 'novel',
      );

      final bundle = service.buildBundle(project);

      expect(bundle.id, 'novel_1_continuity');
      expect(bundle.scopes.map((item) => item.id), <String>['global']);
      expect(bundle.defaultFrameId, 'mainline');
      expect(bundle.frames.single.scopeId, 'global');
      expect(
        bundle.mechanicProfiles.single.identityMode,
        ContinuityIdentityMode.stable,
      );
      expect(
        bundle.mechanicProfiles.single.branchMode,
        ContinuityBranchMode.singleLine,
      );
      expect(
        bundle.mechanicProfiles.single.causalMode,
        ContinuityCausalMode.linear,
      );
      expect(bundle.metadata['general_project_seed'], isTrue);
    });

    test('derives multi-world and replay-aware defaults from light input', () {
      const project = ProjectDescriptor(
        id: 'novel_2',
        name: '特殊机制小说',
        rootPath: 'D:/tmp/novel_2',
        projectType: 'novel',
      );
      const input = ProjectContinuityInputProfile(
        displayName: '多世界回档',
        usesMultipleWorlds: true,
        usesBranchingRoutes: true,
        usesReplayResets: true,
        requiresScopedIdentityOverlays: true,
        worldLabels: <String>['现世', '副本A'],
      );

      final bundle = service.buildBundle(project, input: input);

      expect(bundle.scopes.map((item) => item.id), <String>[
        'global',
        'world_现世',
        'world_副本a',
      ]);
      expect(bundle.frames.single.scopeId, 'world_现世');
      expect(bundle.mechanicProfiles.single.displayName, '多世界回档');
      expect(
        bundle.mechanicProfiles.single.identityMode,
        ContinuityIdentityMode.scopeOverlay,
      );
      expect(
        bundle.mechanicProfiles.single.memoryMode,
        ContinuityMemoryMode.protagonistOnly,
      );
      expect(
        bundle.mechanicProfiles.single.stateMode,
        ContinuityStateMode.partialCarryOver,
      );
      expect(
        bundle.mechanicProfiles.single.causalMode,
        ContinuityCausalMode.replayAware,
      );
      expect(
        bundle.mechanicProfiles.single.branchMode,
        ContinuityBranchMode.forkOnTransition,
      );
    });
  });
}
