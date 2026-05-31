import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectGeneralContinuitySetupService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectGeneralContinuitySetupService service;
    late ProjectContinuityRepository continuityRepository;
    late ProjectContinuityInputRepository inputRepository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-general-continuity-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '一般项目',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
      final workspacePort = LocalProjectWorkspacePort();
      continuityRepository = ProjectContinuityRepository(
        workspacePort: workspacePort,
      );
      inputRepository = ProjectContinuityInputRepository(
        workspacePort: workspacePort,
      );
      service = ProjectGeneralContinuitySetupService(
        continuityRepository: continuityRepository,
        inputRepository: inputRepository,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'ensureInitialized seeds conservative bundle when project has none',
      () async {
        final bundle = await service.ensureInitialized(project);
        final loadedInput = await inputRepository.load(project);
        final loadedBundle = await continuityRepository.load(project);

        expect(bundle.defaultFrameId, 'mainline');
        expect(bundle.scopes.map((item) => item.id), <String>['global']);
        expect(loadedInput, isNull);
        expect(loadedBundle?.id, bundle.id);
      },
    );

    test('applyInput saves light profile and rewrites derived bundle', () async {
      const input = ProjectContinuityInputProfile(
        displayName: '多世界路线',
        usesMultipleWorlds: true,
        usesBranchingRoutes: true,
        worldLabels: <String>['主世界', '支线世界'],
      );

      final bundle = await service.applyInput(project, input);
      final loadedInput = await inputRepository.load(project);
      final loadedBundle = await continuityRepository.load(project);

      expect(loadedInput, isNotNull);
      expect(loadedInput!.usesMultipleWorlds, isTrue);
      expect(loadedInput.worldLabels, <String>['主世界', '支线世界']);
      expect(
        bundle.mechanicProfiles.single.branchMode,
        ContinuityBranchMode.forkOnTransition,
      );
      expect(loadedBundle?.scopes.map((item) => item.id), <String>[
        'global',
        'world_主世界',
        'world_支线世界',
      ]);
      expect(loadedBundle?.frames.single.scopeId, 'world_主世界');

      final inputFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}settings${Platform.pathSeparator}project_continuity_input.json',
      );
      expect(await inputFile.exists(), isTrue);
    });
  });
}
