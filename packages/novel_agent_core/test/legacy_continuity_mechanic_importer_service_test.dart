import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LegacyContinuityMechanicImporterService', () {
    const service = LegacyContinuityMechanicImporterService();

    test('maps legacy continuity mechanic bundle into deprecated profile and legacy.special_mechanic claims', () {
      final bundle = ProjectContinuityBundle(
        id: 'continuity_bundle_1',
        displayName: '多世界回档',
        coverage: const ContinuityCoverage(
          sourceLabel: 'legacy setup',
          sourcePaths: <String>['outline/continuity.md'],
          chapterStart: 1,
          chapterEnd: 8,
          inferredSections: <String>['world_rules'],
        ),
        scopeOverlays: const <ContinuationScopeOverlay>[
          ContinuationScopeOverlay(
            id: 'overlay-1',
            scopeId: 'global',
            displayName: '身份覆盖',
            priority: 10,
          ),
        ],
        mechanicProfiles: const <ContinuityMechanicProfile>[
          ContinuityMechanicProfile(
            id: 'loop_profile',
            displayName: '回档机制',
            identityMode: ContinuityIdentityMode.scopeOverlay,
            memoryMode: ContinuityMemoryMode.protagonistOnly,
            stateMode: ContinuityStateMode.partialCarryOver,
            causalMode: ContinuityCausalMode.replayAware,
            branchMode: ContinuityBranchMode.parallelVisible,
            visibilityMode: ContinuityVisibilityMode.metaOnly,
            notes: 'legacy imported mechanic',
          ),
        ],
        frames: const <ContinuityFrame>[
          ContinuityFrame(
            id: 'frame-1',
            displayName: '主线一周目',
            scopeId: 'global',
            mechanicProfileId: 'loop_profile',
            relation: ContinuityFrameRelation.replay,
          ),
        ],
        defaultMechanicProfileId: 'loop_profile',
        defaultFrameId: 'frame-1',
      );
      const inputProfile = ProjectContinuityInputProfile(
        displayName: '旧输入画像',
        usesMultipleWorlds: true,
        usesReplayResets: true,
        worldLabels: <String>['主世界', '镜像世界'],
      );

      final package = service.buildPackage(
        project: const ProjectDescriptor(
          id: 'project_1',
          name: '测试项目',
          rootPath: 'D:/projects/test',
        ),
        bundle: bundle,
        inputProfile: inputProfile,
      );

      expect(
        package.profile.profileNamespace,
        'legacy.special_mechanic.profile',
      );
      expect(
        package.profile.lifecycleStatus,
        NarrativeProfileLifecycleStatus.deprecated,
      );
      expect(package.profile.profileLabel, contains('Legacy continuity bridge'));
      expect(
        ValueReaders.stringList(
          package.profile.profileExtensions['compatibility_aliases'],
        ),
        contains('legacy.special_mechanic'),
      );
      expect(
        ValueReaders.mapValue(
          package.profile.profileExtensions['legacy_special_mechanic_bundle'],
        )['default_mechanic_profile_id'],
        'loop_profile',
      );
      expect(
        ValueReaders.mapValue(
          package.profile.profileExtensions['legacy_special_mechanic_input_profile'],
        )['uses_replay_resets'],
        isTrue,
      );
      expect(
        package.claims.map((claim) => claim.claimNamespace),
        containsAll(<String>[
          'legacy.special_mechanic.bundle',
          'legacy.special_mechanic.coverage',
          'legacy.special_mechanic.input_profile',
          'legacy.special_mechanic.mechanic_profile',
          'legacy.special_mechanic.frame',
          'legacy.special_mechanic.scope_overlay',
        ]),
      );
      expect(
        package.claims
            .where((claim) => claim.claimNamespace == 'legacy.special_mechanic.mechanic_profile')
            .single
            .claimPayload['causal_mode'],
        'replayAware',
      );
      expect(
        ValueReaders.stringValue(
          package.profile.profileExtensions['pressure_probe_note'],
        ),
        contains('Historical special-mechanic labels remain readable'),
      );
    });
  });
}
