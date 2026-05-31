import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectContinuityBuildSpecRepository', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectContinuityBuildSpecRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-continuity-build-specs-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '连续性构建规格测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      repository = ProjectContinuityBuildSpecRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('persists index and build spec documents', () async {
      await repository.saveAll(project, const <ContinuityBuildSpec>[
        ContinuityBuildSpec(
          id: 'quick_bridge',
          displayName: '快速承接',
          tier: ContinuityBuildTier.quickBridge,
          focusScopeIds: <String>['global'],
          requestedOutputs: <ContinuityBuildOutputKind>[
            ContinuityBuildOutputKind.tailBridge,
            ContinuityBuildOutputKind.stateTables,
          ],
          preferredRuntimeHost: ContinuityBuildRuntimeHost.directExecution,
        ),
        ContinuityBuildSpec(
          id: 'standard_foundation',
          displayName: '标准基座',
          tier: ContinuityBuildTier.standardFoundation,
          focusScopeIds: <String>['global', 'world_a'],
          focusFrameId: 'mainline',
          requestedOutputs: <ContinuityBuildOutputKind>[
            ContinuityBuildOutputKind.globalBible,
            ContinuityBuildOutputKind.stageSummaries,
          ],
          preferredRuntimeHost:
              ContinuityBuildRuntimeHost.resumableWorkflowEngine,
          recommended: true,
        ),
      ]);

      final loaded = await repository.loadAll(project);

      expect(loaded, hasLength(2));
      expect(loaded.first.id, 'quick_bridge');
      expect(loaded.first.tier, ContinuityBuildTier.quickBridge);
      expect(loaded.last.focusFrameId, 'mainline');
      expect(loaded.last.requestedOutputs, <ContinuityBuildOutputKind>[
        ContinuityBuildOutputKind.globalBible,
        ContinuityBuildOutputKind.stageSummaries,
      ]);
      expect(
        loaded.last.preferredRuntimeHost,
        ContinuityBuildRuntimeHost.resumableWorkflowEngine,
      );
      expect(loaded.last.recommended, isTrue);

      final indexFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}tracking${Platform.pathSeparator}continuity${Platform.pathSeparator}build_specs${Platform.pathSeparator}index.json',
      );
      final specFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}tracking${Platform.pathSeparator}continuity${Platform.pathSeparator}build_specs${Platform.pathSeparator}standard_foundation.json',
      );
      expect(await indexFile.exists(), isTrue);
      expect(await specFile.exists(), isTrue);
    });
  });
}
