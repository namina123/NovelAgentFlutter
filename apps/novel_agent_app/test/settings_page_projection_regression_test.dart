import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_viewmodel_harness_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'settings projection keeps developer and host-root details out of the default user path',
    () async {
      // 中文注释: 这里用真实的 app shell 装配去验证设置页投影，避免只测静态常量而漏掉控制器回流。
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: ScriptedGenerateDraftUseCase(
          resultBuilder:
              ({
                required ProjectDescriptor project,
                required String userPrompt,
                required String modelId,
              }) {
                return DraftGenerationResult(
                  project: project,
                  projectInfo: <String, Object?>{
                    'id': project.id,
                    'title': project.name,
                    'path': project.rootPath,
                    'project_type': project.projectType,
                  },
                  userPrompt: userPrompt,
                  prompt: userPrompt,
                  modelId: modelId,
                  draftMarkdown: 'settings projection regression placeholder',
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
                );
              },
        ),
      );

      final settings = harness.controller.settingsPageListenable.value;
      final tabIds = settings.tabs.map((tab) => tab.id).toList();

      expect(settings.activeTabId, 'interfaces');
      expect(
        tabIds,
        const <String>[
          'interfaces',
          'models',
          'permissions',
          'tooling',
          'network',
          'context',
          'theme',
        ],
      );
      expect(tabIds, isNot(contains('dev')));

      final forbiddenFragments = <String>[
        '开发',
        '当前版本',
        '宿主',
        'ProjectWorkspacePort',
        'ToolExecutionService',
        'ProjectToolDispatcher',
        'settingsRootPath',
        'settingsSearchRoots',
        'defaultProjectsRootPath',
      ];
      for (final section in settings.tabSections.values.expand((value) => value)) {
        for (final fragment in forbiddenFragments) {
          expect(section.title, isNot(contains(fragment)));
          expect(section.description, isNot(contains(fragment)));
        }
        for (final item in section.items) {
          for (final fragment in forbiddenFragments) {
            expect(item.label, isNot(contains(fragment)));
            expect(item.value, isNot(contains(fragment)));
          }
        }
      }
    },
  );
}
