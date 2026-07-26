import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/routing/app_destination.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_viewmodel_harness_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'book deconstruction navigation is guarded and retained by composite projects',
    () async {
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: _noOpGenerateDraftUseCase(),
      );
      addTearDown(harness.controller.dispose);

      await harness.createProject(title: 'Navigation Capability Regression');

      expect(_hasBookDeconstructionNavigation(harness), isFalse);

      await harness.controller.onAppShellDestinationRequested(
        AppDestination.agentEcosystem,
      );
      expect(
        harness.controller.viewModel.destination,
        AppDestination.agentEcosystem,
      );

      await harness.controller.onAppShellDestinationRequested(
        AppDestination.bookDeconstruction,
      );
      expect(
        harness.controller.viewModel.destination,
        AppDestination.workbench,
      );

      final projectPath = harness.workbench.projectPath;
      final project = await harness.bundle.projectRepository.openByPath(
        projectPath,
      );
      expect(project, isNotNull);
      await harness.bundle.projectWorkspacePort.writeTextFile(
        projectPath,
        ProjectManifestCodecService.manifestRelativePath,
        ProjectManifestCodecService().encode(
          ProjectManifest(
            title: project!.name,
            projectType: project.projectType,
            storageStrategy: project.storageStrategy,
            projectBranchId: project.projectBranchId,
            runtimeBaselineId: project.runtimeBaselineId,
            additionalTraitIds: const <String>[
              BookDeconstructionConstants.projectTypeId,
            ],
          ),
        ),
      );

      harness.controller.onProjectEntryOpened(projectPath);
      await harness.waitUntil(
        () => _hasBookDeconstructionNavigation(harness),
        description: 'composite project deconstruction navigation',
      );

      await harness.controller.onAppShellDestinationRequested(
        AppDestination.bookDeconstruction,
      );
      expect(
        harness.controller.viewModel.destination,
        AppDestination.bookDeconstruction,
      );
    },
  );
}

bool _hasBookDeconstructionNavigation(HfvvAppShellHarness harness) {
  return harness.controller
      .navigationSections()
      .expand((section) => section.items)
      .any((item) => item.destination == AppDestination.bookDeconstruction);
}

ScriptedGenerateDraftUseCase _noOpGenerateDraftUseCase() {
  return ScriptedGenerateDraftUseCase(
    resultBuilder:
        ({
          required ProjectDescriptor project,
          required String userPrompt,
          required String modelId,
        }) => DraftGenerationResult(
          project: project,
          projectInfo: const <String, Object?>{},
          userPrompt: userPrompt,
          prompt: userPrompt,
          modelId: modelId,
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>[],
          executedTools: const <Object?>[],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        ),
  );
}
