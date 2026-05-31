import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/workbench/application/controllers/workbench_workspace_controller.dart';
import 'package:novel_agent_app/features/workbench/application/models/open_document_state.dart';
import 'package:novel_agent_app/features/workbench/application/models/workbench_project_runtime_state.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('WorkbenchWorkspaceController snapshot', () {
    test(
      'restoreWorkbenchSnapshot restores selected conversation agent id',
      () async {
        final harness = _ControllerHarness(
          settings: _settingsWithSnapshot(
            projectRootPath: 'D:/Projects/novel_project',
            selectedConversationAgentId: 'reviewer',
            expandedDirectories: const <String>['docs'],
          ),
          workbench: WorkbenchViewData.initial(),
          projectState: WorkbenchProjectRuntimeState(
            resourceSnapshotEntries: const <JsonMap>[
              <String, Object?>{'relative_path': 'docs', 'is_dir': true},
            ],
          ),
        );

        await harness.controller.restoreWorkbenchSnapshot(
          _project('D:/Projects/novel_project'),
        );

        expect(harness.workbench.agentSelector.currentAgentId, 'reviewer');
        expect(harness.projectState.expandedResourceDirectories, <String>{
          'docs',
        });
      },
    );

    test(
      'restoreWorkbenchSnapshot ignores snapshot from another project',
      () async {
        final harness = _ControllerHarness(
          settings: _settingsWithSnapshot(
            projectRootPath: 'D:/Projects/project_a',
            selectedConversationAgentId: 'reviewer',
          ),
          workbench: WorkbenchViewData.initial().copyWith(
            agentSelector: const ConversationAgentSelectorViewData(
              currentAgentLabel: '作者智能体',
              currentAgentId: 'writer',
              currentAgentDescription: '正文创作',
              agentOptions: <SelectorOptionViewData>[],
              canSwitchAgent: false,
            ),
          ),
          projectState: const WorkbenchProjectRuntimeState(),
        );

        await harness.controller.restoreWorkbenchSnapshot(
          _project('D:/Projects/project_b'),
        );

        expect(harness.workbench.agentSelector.currentAgentId, 'writer');
        expect(harness.savedSettings, isEmpty);
      },
    );

    test('persisted snapshot includes selected conversation agent id', () {
      final harness = _ControllerHarness(
        settings: _baseSettings(),
        workbench: WorkbenchViewData.initial().copyWith(
          projectPath: 'D:/Projects/novel_project',
          activeDocumentPath: 'drafts/chapter_01.md',
          agentSelector: const ConversationAgentSelectorViewData(
            currentAgentLabel: '审阅智能体',
            currentAgentId: 'reviewer',
            currentAgentDescription: '质量审阅',
            agentOptions: <SelectorOptionViewData>[],
            canSwitchAgent: false,
          ),
        ),
        projectState: WorkbenchProjectRuntimeState(
          currentProject: _project('D:/Projects/novel_project'),
          openDocuments: const <OpenDocumentState>[
            OpenDocumentState(
              id: 'doc-1',
              title: 'Chapter 1',
              relativePath: 'drafts/chapter_01.md',
              content: 'body',
            ),
            OpenDocumentState(
              id: 'doc-2',
              title: 'Chapter 2',
              relativePath: 'drafts/chapter_02.md',
              content: 'body 2',
            ),
          ],
          activeOpenDocumentId: 'doc-1',
          expandedResourceDirectories: const <String>{'drafts'},
        ),
      );

      harness.controller.onDocumentSelected('doc-2');

      expect(harness.savedSettings, isNotEmpty);
      final snapshot = _mapValue(
        harness.savedSettings.last.extraSettings['workbench_state'],
      );
      expect(snapshot['project_root_path'], 'D:/Projects/novel_project');
      expect(snapshot['active_document_path'], 'drafts/chapter_02.md');
      expect(snapshot['selected_conversation_agent_id'], 'reviewer');
      expect(
        ValueReaders.stringList(snapshot['expanded_directories']),
        <String>['drafts'],
      );
    });
  });
}

class _ControllerHarness {
  _ControllerHarness({
    required AppSettings settings,
    required WorkbenchViewData workbench,
    required WorkbenchProjectRuntimeState projectState,
  }) : _settings = settings,
       _workbench = workbench,
       _projectState = projectState {
    controller = _createController(
      readSettings: () => _settings,
      saveSettingsSilently: (next) async {
        _savedSettings.add(next);
        _settings = next;
      },
      readWorkbench: () => _workbench,
      mutateWorkbench: (updater) {
        _workbench = updater(_workbench);
      },
      readProjectState: () => _projectState,
      writeProjectState: (next) {
        _projectState = next;
      },
    );
  }

  AppSettings _settings;
  WorkbenchViewData _workbench;
  WorkbenchProjectRuntimeState _projectState;
  final List<AppSettings> _savedSettings = <AppSettings>[];

  late final WorkbenchWorkspaceController controller;

  WorkbenchViewData get workbench => _workbench;
  WorkbenchProjectRuntimeState get projectState => _projectState;
  List<AppSettings> get savedSettings =>
      List<AppSettings>.unmodifiable(_savedSettings);
}

WorkbenchWorkspaceController _createController({
  required AppSettings? Function() readSettings,
  required Future<void> Function(AppSettings nextSettings) saveSettingsSilently,
  required WorkbenchViewData Function() readWorkbench,
  required void Function(WorkbenchViewData Function(WorkbenchViewData current))
  mutateWorkbench,
  required WorkbenchProjectRuntimeState Function() readProjectState,
  required void Function(WorkbenchProjectRuntimeState state) writeProjectState,
}) {
  final workspacePort = _NoopProjectWorkspacePort();
  final toolHostPort = _NoopProjectToolHostPort();
  return WorkbenchWorkspaceController(
    loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
      projectRepository: _NoopProjectRepository(),
      projectWorkspacePort: workspacePort,
    ),
    readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
    saveDraftUseCase: SaveDraftUseCase(projectWorkspacePort: workspacePort),
    createProjectEntryUseCase: CreateProjectEntryUseCase(
      projectToolHostPort: toolHostPort,
    ),
    importProjectFilesUseCase: ImportProjectFilesUseCase(
      projectToolHostPort: toolHostPort,
    ),
    updateProjectManifestUseCase: UpdateProjectManifestUseCase(
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
    ),
    projectToolHostPort: toolHostPort,
    writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
      projectWorkspacePort: workspacePort,
    ),
    longTaskSupervisor: _NoopLongTaskSupervisor(),
    reviewReportService: _NoopProjectReviewReportService(),
    projectRuntimeProfileRepository: _NoopProjectRuntimeProfileRepository(),
    readProjectState: readProjectState,
    writeProjectState: writeProjectState,
    resetConversationRuntimeState: () {},
    readWorkbench: readWorkbench,
    mutateWorkbench: mutateWorkbench,
    applyConversationState: (base) => base,
    readSettings: readSettings,
    saveSettingsSilently: saveSettingsSilently,
    refreshSettingsViewData: () {},
    refreshAgentEcosystem: () async {},
    refreshActiveDestinationAfterProjectLoad: () async {},
    modelOptionsBuilder: (_) => const <SelectorOptionViewData>[],
    readProjectAgentGroupWorkspaceViewData: () => null,
    selectProjectAgentGroup: (_) async => null,
    showSettings: () async {},
    showAgentEcosystem: () async {},
    showLongTaskStation: () async {},
    showInspirationWorkbench: () async {},
    showPromptTemplates: () async {},
    showProjectAssets: () async {},
    showCurrentAgentSkillLoadout: (_) async {},
    showCurrentAgentExpressionConstraints: (_) async {},
    announce: (_) {},
  );
}

ProjectDescriptor _project(String rootPath) {
  return ProjectDescriptor(
    id: rootPath,
    name: '测试项目',
    rootPath: rootPath,
    projectType: 'novel',
  );
}

AppSettings _baseSettings() {
  return const AppSettings(
    defaultProviderId: 'provider',
    defaultAgentId: 'default_generalist',
    defaultModelId: 'model',
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[],
  );
}

AppSettings _settingsWithSnapshot({
  required String projectRootPath,
  required String selectedConversationAgentId,
  List<String> expandedDirectories = const <String>[],
}) {
  return _baseSettings().copyWith(
    extraSettings: <String, Object?>{
      'workbench_state': <String, Object?>{
        'project_root_path': projectRootPath,
        'active_document_path': '',
        'expanded_directories': expandedDirectories,
        'selected_conversation_agent_id': selectedConversationAgentId,
      },
    },
  );
}

JsonMap _mapValue(Object? value) {
  if (value is Map<String, Object?>) {
    return ValueReaders.deepCopyMap(value);
  }
  if (value is Map) {
    final result = <String, Object?>{};
    value.forEach((key, item) {
      result[key.toString()] = item;
    });
    return result;
  }
  return const <String, Object?>{};
}

class _NoopProjectRepository implements ProjectRepository {
  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async => null;
}

class _NoopProjectWorkspacePort implements ProjectWorkspacePort {
  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _NoopProjectToolHostPort implements ProjectToolHostPort {
  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {}

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async => false;

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {}

  @override
  Future<String?> readExternalTextFile(String absolutePath) async => null;

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {}

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _NoopLongTaskSupervisor implements LongTaskSupervisor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopProjectReviewReportService implements ProjectReviewReportService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopProjectRuntimeProfileRepository
    implements ProjectRuntimeProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
