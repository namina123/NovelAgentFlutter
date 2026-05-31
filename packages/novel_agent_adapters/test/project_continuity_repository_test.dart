import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectContinuityRepository', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectContinuityRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-project-continuity-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '连续性测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      repository = ProjectContinuityRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('persists bundle summary and related scope/frame documents', () async {
      const bundle = ProjectContinuityBundle(
        id: 'continuity_main',
        displayName: '主连续性包',
        coverage: ContinuityCoverage(
          sourceLabel: '拆书导入',
          sourcePaths: <String>['imports/source_book.md'],
          chapterStart: 1,
          chapterEnd: 300,
          isPartial: true,
        ),
        canonicalAssetReferences: <ContinuityAssetReference>[
          ContinuityAssetReference(
            assetKind: ContinuityAssetKind.characterProfile,
            assetId: 'hero',
            displayName: '主角',
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
                assetKind: ContinuityAssetKind.worldRuleSet,
                assetId: 'world_rule_a',
                role: ContinuityAssetReferenceRole.scopeOverlay,
              ),
            ],
          ),
        ],
        mechanicProfiles: <ContinuityMechanicProfile>[
          ContinuityMechanicProfile(
            id: 'default_profile',
            displayName: '默认机制',
            branchMode: ContinuityBranchMode.singleLine,
          ),
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
                assetId: 'hero_state_1',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
          ),
        ],
        defaultMechanicProfileId: 'default_profile',
        defaultFrameId: 'mainline',
      );

      await repository.save(project, bundle);
      final loaded = await repository.load(project);

      expect(loaded, isNotNull);
      expect(loaded!.id, 'continuity_main');
      expect(loaded.coverage.chapterEnd, 300);
      expect(loaded.scopes.map((item) => item.id), <String>[
        'global',
        'world_a',
      ]);
      expect(loaded.scopeOverlays.single.scopeId, 'world_a');
      expect(loaded.frames.single.id, 'mainline');
      expect(loaded.defaultFrameId, 'mainline');

      final bundleFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}tracking${Platform.pathSeparator}continuity${Platform.pathSeparator}bundle.json',
      );
      final scopeFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}tracking${Platform.pathSeparator}continuity${Platform.pathSeparator}scopes${Platform.pathSeparator}world_a.json',
      );
      final frameFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}tracking${Platform.pathSeparator}continuity${Platform.pathSeparator}frames${Platform.pathSeparator}mainline.json',
      );
      expect(await bundleFile.exists(), isTrue);
      expect(await scopeFile.exists(), isTrue);
      expect(await frameFile.exists(), isTrue);
    });
  });
}
