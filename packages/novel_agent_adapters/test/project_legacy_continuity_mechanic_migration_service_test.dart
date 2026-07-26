import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLegacyContinuityMechanicMigrationService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late ProjectLegacyContinuityMechanicMigrationService service;
    late LocalNarrativeProfileRepository profileRepository;
    late LocalNarrativeClaimRepository claimRepository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-legacy-continuity-migration-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'legacy_project',
        name: 'Legacy Continuity Project',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      final continuityRepository = ProjectContinuityRepository(
        workspacePort: workspacePort,
      );
      final inputRepository = ProjectContinuityInputRepository(
        workspacePort: workspacePort,
      );
      await continuityRepository.save(
        project,
        const ProjectContinuityBundle(
          id: 'legacy_bundle',
          displayName: '旧机制连续性',
          coverage: ContinuityCoverage(
            sourceLabel: 'legacy bundle',
            sourcePaths: <String>['outline/legacy_rules.md'],
            chapterStart: 1,
            chapterEnd: 12,
          ),
          mechanicProfiles: <ContinuityMechanicProfile>[
            ContinuityMechanicProfile(
              id: 'legacy_loop',
              displayName: '旧回档机制',
              identityMode: ContinuityIdentityMode.scopeOverlay,
              memoryMode: ContinuityMemoryMode.protagonistOnly,
              stateMode: ContinuityStateMode.partialCarryOver,
              causalMode: ContinuityCausalMode.replayAware,
              branchMode: ContinuityBranchMode.parallelVisible,
              visibilityMode: ContinuityVisibilityMode.metaOnly,
            ),
          ],
          frames: <ContinuityFrame>[
            ContinuityFrame(
              id: 'mainline',
              displayName: '主线',
              scopeId: 'global',
              mechanicProfileId: 'legacy_loop',
              relation: ContinuityFrameRelation.replay,
            ),
          ],
          defaultMechanicProfileId: 'legacy_loop',
          defaultFrameId: 'mainline',
        ),
      );
      await inputRepository.save(
        project,
        const ProjectContinuityInputProfile(
          displayName: '旧 continuity 输入',
          usesMultipleWorlds: true,
          usesReplayResets: true,
          worldLabels: <String>['主世界'],
        ),
      );
      profileRepository = LocalNarrativeProfileRepository(
        workspacePort: workspacePort,
      );
      claimRepository = LocalNarrativeClaimRepository(
        workspacePort: workspacePort,
      );
      service = ProjectLegacyContinuityMechanicMigrationService(
        workspacePort: workspacePort,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'migrates legacy continuity files into hidden narrative profile and claims',
      () async {
        final result = await service.migrate(project);

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.stringValue(result['action']), 'migrated');
        expect(
          ValueReaders.stringValue(result['legacy_namespace_root']),
          'legacy.special_mechanic',
        );
        expect(
          ValueReaders.stringList(result['compatibility_aliases']),
          contains('legacy.special_mechanic'),
        );

        final profile = await profileRepository.readProfile(
          project,
          profileId: 'legacy_special_mechanic_profile',
        );
        final claims = await claimRepository.listClaims(project);

        expect(profile, isNotNull);
        expect(profile!.profileNamespace, 'legacy.special_mechanic.profile');
        expect(
          profile.lifecycleStatus,
          NarrativeProfileLifecycleStatus.deprecated,
        );
        expect(profile.profileLabel, contains('Legacy continuity bridge'));
        expect(
          ValueReaders.mapValue(
            profile.profileExtensions['legacy_special_mechanic_input_profile'],
          )['uses_replay_resets'],
          isTrue,
        );
        expect(
          ValueReaders.stringList(
            profile.profileExtensions['compatibility_aliases'],
          ),
          contains('legacy.special_mechanic'),
        );
        expect(
          claims.map((claim) => claim.claimNamespace),
          containsAll(<String>[
            'legacy.special_mechanic.bundle',
            'legacy.special_mechanic.coverage',
            'legacy.special_mechanic.input_profile',
            'legacy.special_mechanic.mechanic_profile',
            'legacy.special_mechanic.frame',
          ]),
        );

        final projectionFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}continuity${Platform.pathSeparator}叙事状态规则.md',
        );
        expect(await projectionFile.exists(), isTrue);
        expect(
          await projectionFile.readAsString(),
          contains('legacy.special_mechanic.profile'),
        );
        expect(
          ValueReaders.stringValue(result['pressure_probe_note']),
          contains('Historical special-mechanic labels remain readable'),
        );
      },
    );

    test(
      'second migration run stays idempotent when legacy source did not change',
      () async {
        await service.migrate(project);

        final second = await service.migrate(project);

        expect(ValueReaders.boolValue(second['ok']), isTrue);
        expect(ValueReaders.stringValue(second['action']), 'up_to_date');
        expect(ValueReaders.stringList(second['changed_paths']), isEmpty);
        expect(await claimRepository.listClaims(project), isNotEmpty);
      },
    );
  });
}
