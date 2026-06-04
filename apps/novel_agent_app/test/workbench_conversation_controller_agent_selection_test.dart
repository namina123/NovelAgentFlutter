import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/workbench/application/controllers/workbench_conversation_controller.dart';
import 'package:novel_agent_app/features/workbench/application/controllers/workbench_workspace_controller.dart';
import 'package:novel_agent_app/features/workbench/application/models/open_document_state.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_member_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_primary_agent_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/models/workbench_conversation_runtime_state.dart';
import 'package:novel_agent_app/features/workbench/application/models/workbench_project_runtime_state.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_guide_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_opening_panel_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_streaming_state_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_user_visible_text_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_agent_group_binding_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_session_projection_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_primary_action_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('WorkbenchConversationController conversation agent selection', () {
    test(
      'uses the newly selected conversation agent for execution profile and request',
      () async {
        final harness = _ConversationControllerHarness();

        harness.controller.onConversationAgentSelected('reviewer');
        expect(harness.workbench.agentSelector.currentAgentId, 'reviewer');

        await harness.controller.onSendRequested('请帮我审一下这一段。');

        expect(harness.modelExecutionProfileService.lastAgentId, 'reviewer');
        expect(harness.generateDraftUseCase.lastAgentId, 'reviewer');
      },
    );

    test(
      'falls back to primary agent when selected agent is no longer valid',
      () async {
        final harness = _ConversationControllerHarness(
          initialWorkbench: WorkbenchViewData.initial().copyWith(
            agentSelector: const ConversationAgentSelectorViewData(
              currentAgentLabel: '过期智能体',
              currentAgentId: 'ghost',
              currentAgentDescription: '旧会话选择',
              agentOptions: <SelectorOptionViewData>[],
              canSwitchAgent: false,
            ),
          ),
        );

        await harness.controller.onSendRequested('继续推进正文。');

        expect(harness.modelExecutionProfileService.lastAgentId, 'writer');
        expect(harness.generateDraftUseCase.lastAgentId, 'writer');
      },
    );

    test('writes reasoning toggle back to shared model settings', () async {
      final harness = _ConversationControllerHarness();

      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(
            harness.settings.extraSettings['model_settings'],
          )['thinking_enabled'],
        ),
        isFalse,
      );

      harness.controller.onReasoningToggleChanged(true);

      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(
            harness.settings.extraSettings['model_settings'],
          )['thinking_enabled'],
        ),
        isTrue,
      );

      harness.controller.onReasoningToggleChanged(false);

      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(
            harness.settings.extraSettings['model_settings'],
          )['thinking_enabled'],
        ),
        isFalse,
      );
    });

    test(
      'injects bridged execution constraints into ordinary conversation generation',
      () async {
        final harness = _ConversationControllerHarness(
          draftExecutionConstraintRuntimeService:
              _FakeProjectDraftExecutionConstraintRuntimeService(
                response: const <String, Object?>{
                  'session_context_markdown':
                      '## Execution Constraints\n- 字数约束：目标约 2400 字',
                  'expression_constraint_profiles': <Object?>[
                    <String, Object?>{
                      'id': 'de_ai',
                      'display_name': '去 AI 风',
                      'summary': '降低模板化表达。',
                      'kind': 'natural_expression',
                      'rules': <Object?>['减少总结句。'],
                    },
                  ],
                  'project_expression_constraint_bindings': <Object?>[
                    <String, Object?>{
                      'id': 'binding_1',
                      'profile_id': 'de_ai',
                      'default_for_project': true,
                    },
                  ],
                },
              ),
        );

        await harness.controller.onSendRequested('继续写第一章。');

        expect(harness.generateDraftUseCase.lastSessionContext, contains('字数约束'));
        expect(harness.generateDraftUseCase.lastExpressionConstraintProfiles.length, 1);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              harness.generateDraftUseCase.lastExpressionConstraintProfiles.first,
            )['id'],
          ),
          'de_ai',
        );
        expect(
          harness.generateDraftUseCase.lastProjectExpressionConstraintBindings.length,
          1,
        );
      },
    );

    test(
      'injects activation report context and submit_chapter_delivery tool priority for ordinary chapter turns',
      () async {
        final runtimeService = _FakeProjectConversationDraftRuntimeService(
          preparation: const ProjectConversationDraftRuntimePreparation(
            runId: 'conversation_run_1',
            taskType: 'chapter',
            activationReportPath:
                'tracking/conversation_draft/conversation_run_1.activation_report.json',
            activationReport: <String, Object?>{
              'summary': 'selected profiles 1, claims 0, constraints 1, files 2.',
            },
            sessionContextMarkdown:
                '## Activation Report\n- summary: selected profiles 1, claims 0, constraints 1, files 2.',
            exposedToolIds: <String>[
              'submit_chapter_delivery',
              'read_project_file',
              'write_project_file',
            ],
          ),
        );
        final harness = _ConversationControllerHarness(
          conversationDraftRuntimeService: runtimeService,
        );

        await harness.controller.onSendRequested('继续写第一章。');

        expect(
          harness.generateDraftUseCase.lastSessionContext,
          contains('## Activation Report'),
        );
        expect(
          harness.generateDraftUseCase.lastExposedToolIds.first,
          'submit_chapter_delivery',
        );
        expect(runtimeService.prepareCallCount, 1);
        expect(runtimeService.finalizeCallCount, 1);
      },
    );

    test(
      'prefers saved chapter status when ordinary generation salvages after tool error',
      () async {
        final runtimeService = _FakeProjectConversationDraftRuntimeService(
          preparation: const ProjectConversationDraftRuntimePreparation(
            runId: 'conversation_run_2',
            taskType: 'chapter',
            activationReportPath:
                'tracking/conversation_draft/conversation_run_2.activation_report.json',
            activationReport: <String, Object?>{
              'summary': 'selected profiles 1, claims 0, constraints 1, files 2.',
            },
            sessionContextMarkdown: '## Activation Report',
            exposedToolIds: <String>[
              'submit_chapter_delivery',
              'write_project_file',
            ],
          ),
          finalization: const ProjectConversationDraftRuntimeArtifacts(
            outputPath: 'chapters/第01章.md',
          ),
        );
        final harness = _ConversationControllerHarness(
          conversationDraftRuntimeService: runtimeService,
          generateDraftUseCase: _RecordingGenerateDraftUseCase(
            scriptedResult: DraftGenerationResult(
              project: _project(),
              projectInfo: <String, Object?>{
                'id': _project().id,
                'title': _project().name,
                'path': _project().rootPath,
                'project_type': _project().projectType,
              },
              userPrompt: '继续写第一章。',
              prompt: '继续写第一章。',
              modelId: 'selected-model',
              draftMarkdown: '# 第01章\n\n测试输出',
              contextPack: const <String, Object?>{},
              selectedPaths: const <String>[],
              executedTools: const <Object?>[],
              writtenPaths: const <String>[],
              changedPaths: const <String>[],
              transcriptMessages: const <JsonMap>[],
              waitingForUserChoice: false,
              reasoningContent: '',
              stoppedByToolError: true,
              toolErrorSummary: 'submit_chapter_delivery：领域工具参数不合法。',
            ),
          ),
        );

        await harness.controller.onSendRequested('继续写第一章。');

        expect(
          harness.workbench.generationStatus,
          '内容生成完成，并已保存到 chapters/第01章.md，但部分工具失败：submit_chapter_delivery：领域工具参数不合法。',
        );
      },
    );
  });
}

class _ConversationControllerHarness {
  _ConversationControllerHarness({
    WorkbenchViewData? initialWorkbench,
    ProjectConversationDraftRuntimeService? conversationDraftRuntimeService,
    ProjectDraftExecutionConstraintRuntimeService?
    draftExecutionConstraintRuntimeService,
    _RecordingGenerateDraftUseCase? generateDraftUseCase,
  })
    : _settings = _buildSettings(),
      _workbench = initialWorkbench ?? WorkbenchViewData.initial(),
      _projectState = WorkbenchProjectRuntimeState(
        currentProject: _project(),
        currentRuntimeProfile: const ProjectRuntimeProfile(
          projectType: 'novel',
          runtimeBaselineId: '',
          runtimeMode: '',
          initialRunOptions: <String, Object?>{},
        ),
        openDocuments: const <OpenDocumentState>[],
      ),
      _runtimeState = WorkbenchConversationRuntimeState(
        openingProjection: _projection(),
      ),
      generateDraftUseCase =
          generateDraftUseCase ?? _RecordingGenerateDraftUseCase(),
      modelExecutionProfileService = _RecordingModelExecutionProfileService() {
    final workspacePort = _NoopProjectWorkspacePort();
    final toolHostPort = _NoopProjectToolHostPort();
    workspaceController = WorkbenchWorkspaceController(
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
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      longTaskSupervisor: _NoopLongTaskSupervisor(),
      reviewReportService: _NoopProjectReviewReportService(),
      projectRuntimeProfileRepository: _NoopProjectRuntimeProfileRepository(),
      readProjectState: () => _projectState,
      writeProjectState: (next) {
        _projectState = next;
      },
      resetConversationRuntimeState: () {},
      readWorkbench: () => _workbench,
      mutateWorkbench: (updater) {
        _workbench = updater(_workbench);
      },
      applyConversationState: (base) => base,
      readSettings: () => _settings,
      saveSettingsSilently: (next) async {
        _settings = next;
      },
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

    final projectionService = _StaticOpeningSessionProjectionService(
      projection: _projection(),
    );
    final modeGuidanceStatePort = _MemoryModeGuidanceStatePort();
    final workflowRuntimeService = ProjectWorkflowRuntimeService(
      taskRepository: ProjectTaskRepository(workspacePort: workspacePort),
      promptTemplateService: ProjectPromptTemplateService(
        workspacePort: workspacePort,
      ),
      generateDraftUseCaseFactory: (_, _) => this.generateDraftUseCase,
    );
    controller = WorkbenchConversationController(
      saveDraftUseCase: SaveDraftUseCase(projectWorkspacePort: workspacePort),
      generateDraftUseCaseFactory: (_, _) => this.generateDraftUseCase,
      modelExecutionProfileService: modelExecutionProfileService,
      conversationSessionStateService: ConversationSessionStateService(),
      conversationStreamingStateService: ConversationStreamingStateService(
        sessionStateService: ConversationSessionStateService(),
      ),
      conversationGuideViewDataService: ConversationGuideViewDataService(),
      conversationOpeningPanelViewDataService:
          ConversationOpeningPanelViewDataService(),
      openingSessionProjectionService: projectionService,
      projectOpeningAgentGroupBindingService:
          ProjectOpeningAgentGroupBindingService(
            loadSelections: (_) async => const <ProjectAgentGroupSelection>[],
            saveSelections: (_, _) async {},
          ),
      conversationUserVisibleTextService: ConversationUserVisibleTextService(),
      workbenchPrimaryActionService: WorkbenchPrimaryActionService(),
      conversationDraftRuntimeService: conversationDraftRuntimeService,
      draftExecutionConstraintRuntimeService:
          draftExecutionConstraintRuntimeService,
      userOptionPromptBuilderService: UserOptionPromptBuilderService(),
      loadModeGuidanceStateUseCase: LoadModeGuidanceStateUseCase(
        statePort: modeGuidanceStatePort,
      ),
      answerModeGuidanceStageUseCase: AnswerModeGuidanceStageUseCase(
        statePort: modeGuidanceStatePort,
      ),
      buildModeGuidancePlanInputUseCase: BuildModeGuidancePlanInputUseCase(
        statePort: modeGuidanceStatePort,
      ),
      modeGuidanceTransitionService: ModeGuidanceTransitionService(),
      workflowRuntimeService: workflowRuntimeService,
      workspaceController: workspaceController,
      readRuntimeState: () => _runtimeState,
      writeRuntimeState: (next) {
        _runtimeState = next;
      },
      readWorkbench: () => _workbench,
      mutateWorkbench: (updater) {
        _workbench = updater(_workbench);
      },
      readSettings: () => _settings,
      persistSettings:
          (
            nextSettings, {
            required successMessage,
            String? selectedProviderId,
          }) async {
            _settings = nextSettings;
          },
      saveSettingsSilently: (nextSettings) async {
        _settings = nextSettings;
      },
      refreshSettingsViewData: () {},
      readThemeId: () => 'light',
      notifyShell: () {},
      showSettings: () async {},
      contextStrategySettingsOf: (_) => const <String, Object?>{},
      selectedModelProvider: (settings) => settings.providers.first,
      announce: (_) {},
    );
    _workbench = controller.applyConversationState(_workbench);
  }

  AppSettings _settings;
  WorkbenchViewData _workbench;
  WorkbenchProjectRuntimeState _projectState;
  WorkbenchConversationRuntimeState _runtimeState;

  final _RecordingGenerateDraftUseCase generateDraftUseCase;
  final _RecordingModelExecutionProfileService modelExecutionProfileService;

  late final WorkbenchWorkspaceController workspaceController;
  late final WorkbenchConversationController controller;

  WorkbenchViewData get workbench => _workbench;

  AppSettings get settings => _settings;
}

class _RecordingModelExecutionProfileService
    extends ModelExecutionProfileService {
  String lastAgentId = '';

  @override
  JsonMap resolve({
    required AppSettings settings,
    ProviderEndpointSettings? provider,
    String overrideModelId = '',
    JsonMap agent = const <String, Object?>{},
    ProjectAgentBinding? projectAgentBinding,
    ProjectAgentModelOverride? projectAgentModelOverride,
  }) {
    lastAgentId = ValueReaders.stringValue(agent['id']);
    return <String, Object?>{
      'provider_id': provider?.id ?? '',
      'resolved_model_id': 'selected-model',
      'runtime_profile': <String, Object?>{'model': 'selected-model'},
      'request_options': <String, Object?>{'agent_id': lastAgentId},
      'model_settings': const <String, Object?>{},
    };
  }
}

class _RecordingGenerateDraftUseCase extends GenerateDraftUseCase {
  _RecordingGenerateDraftUseCase({
    DraftGenerationResult? scriptedResult,
  }) : _scriptedResult = scriptedResult,
       super(
         projectWorkspacePort: _NoopProjectWorkspacePort(),
         llmGateway: _NoopLlmGateway(),
         toolExecutionPort: _NoopToolExecutionPort(),
         contextAssemblerService: ContextAssemblerService(
           budgetService: ContextBudgetService(),
           staticSectionService: ContextStaticSectionService(
             projectPromptContract: ProjectPromptContract(),
           ),
           projectFileSectionService: ContextProjectFileSectionService(),
         ),
         projectPromptContract: ProjectPromptContract(),
       );

  final DraftGenerationResult? _scriptedResult;

  String lastAgentId = '';
  String lastSessionContext = '';
  List<String> lastExposedToolIds = const <String>[];
  List<Object?> lastExpressionConstraintProfiles = const <Object?>[];
  List<Object?> lastProjectExpressionConstraintBindings = const <Object?>[];

  @override
  Future<DraftGenerationResult> execute({
    required ProjectDescriptor project,
    required String userPrompt,
    required String modelId,
    String title = '',
    String intent = 'draft',
    JsonMap agent = const <String, Object?>{},
    String sessionContext = '',
    JsonMap requestOptions = const <String, Object?>{},
    JsonMap contextSettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
    JsonMap skillRoutingContext = const <String, Object?>{},
    List<String> exposedToolIds = const <String>[],
    List<Object?> memorySections = const <Object?>[],
    List<Object?> expressionConstraintProfiles = const <Object?>[],
    List<Object?> projectExpressionConstraintBindings = const <Object?>[],
    List<Object?> projectFileSectionPlan = const <Object?>[],
    JsonMap projectFileContents = const <String, Object?>{},
    String activeDocumentPath = '',
    String activeDocumentBody = '',
    DraftGenerationCancellationToken? cancellationToken,
    void Function(DraftGenerationProgress progress)? onProgress,
  }) async {
    lastAgentId = ValueReaders.stringValue(agent['id']);
    lastSessionContext = sessionContext;
    lastExposedToolIds = List<String>.from(exposedToolIds, growable: false);
    lastExpressionConstraintProfiles = List<Object?>.from(
      expressionConstraintProfiles,
      growable: false,
    );
    lastProjectExpressionConstraintBindings = List<Object?>.from(
      projectExpressionConstraintBindings,
      growable: false,
    );
    return _scriptedResult ??
        DraftGenerationResult(
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
      draftMarkdown: '测试输出',
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
  }
}

class _FakeProjectConversationDraftRuntimeService
    extends ProjectConversationDraftRuntimeService {
  _FakeProjectConversationDraftRuntimeService({
    required this.preparation,
    this.finalization = const ProjectConversationDraftRuntimeArtifacts(),
  }) : super(
         workspacePort: _NoopProjectWorkspacePort(),
         hostPort: _NoopProjectToolHostPort(),
       );

  final ProjectConversationDraftRuntimePreparation preparation;
  final ProjectConversationDraftRuntimeArtifacts finalization;
  int prepareCallCount = 0;
  int finalizeCallCount = 0;

  @override
  Future<ProjectConversationDraftRuntimePreparation> prepareDraftRun(
    ProjectDescriptor project, {
    required String taskType,
    List<String> pinnedRelativePaths = const <String>[],
  }) async {
    prepareCallCount += 1;
    return preparation;
  }

  @override
  Future<ProjectConversationDraftRuntimeArtifacts> finalizeDraftRun({
    required ProjectDescriptor project,
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required String title,
    String fallbackSavedPath = '',
  }) async {
    finalizeCallCount += 1;
    return finalization;
  }
}

class _FakeProjectDraftExecutionConstraintRuntimeService
    extends ProjectDraftExecutionConstraintRuntimeService {
  _FakeProjectDraftExecutionConstraintRuntimeService({required this.response})
    : super(
        expressionConstraintProfileRepository: ExpressionConstraintProfileRepository(
          workspacePort: _NoopProjectWorkspacePort(),
        ),
        projectExpressionConstraintBindingRepository:
            ProjectExpressionConstraintBindingRepository(
              workspacePort: _NoopProjectWorkspacePort(),
            ),
        constraintBindingRepository: LocalConstraintBindingRepository(
          workspacePort: _NoopProjectWorkspacePort(),
        ),
      );

  final JsonMap response;

  @override
  Future<JsonMap> resolve(
    ProjectDescriptor project, {
    required String appliesTo,
    String agentId = '',
    String modeId = '',
    String stageId = '',
    JsonMap legacyChapterLengthOptions = const <String, Object?>{},
  }) async {
    return ValueReaders.deepCopyMap(response);
  }
}

class _StaticOpeningSessionProjectionService
    extends ProjectOpeningSessionProjectionService {
  _StaticOpeningSessionProjectionService({required this.projection})
    : super(
        loadAgentPackages: (_) async => const <JsonMap>[],
        loadAgentGroups: (_) async => const <JsonMap>[],
        loadProjectAgentGroupSelections: (_) async =>
            const <ProjectAgentGroupSelection>[],
      );

  final OpeningSessionProjection projection;

  @override
  Future<OpeningSessionProjection> build({
    required ProjectDescriptor project,
    required ProjectRuntimeProfile? runtimeProfile,
    required ModeGuidanceState? modeGuidanceState,
    String sessionGoalModeId = '',
    String freeTextIntent = '',
    List<ProjectAgentBinding> agentBindings = const <ProjectAgentBinding>[],
  }) async {
    return projection;
  }
}

class _MemoryModeGuidanceStatePort implements ModeGuidanceStatePort {
  @override
  Future<ModeGuidanceState?> load(
    ProjectDescriptor project, {
    required String modeId,
  }) async => null;

  @override
  Future<void> save(ProjectDescriptor project, ModeGuidanceState state) async {}
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

class _NoopLlmGateway implements LlmGateway {
  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async => const <String, Object?>{'ok': true};

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    return requestChat(
      request: ChatRequest.fromLegacy(
        messages: messages,
        modelId: modelId,
        tools: tools,
        options: options,
        attachments: attachments,
      ),
      cancellationToken: cancellationToken,
      onStreamUpdate: onStreamUpdate,
    );
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async => 'noop';
}

class _NoopToolExecutionPort implements ToolExecutionPort {
  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async => const <String, Object?>{'ok': true};
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

ProjectDescriptor _project() {
  return const ProjectDescriptor(
    id: 'project',
    name: '测试项目',
    rootPath: 'D:/Projects/test_project',
    projectType: 'novel',
  );
}

AppSettings _buildSettings() {
  return const AppSettings(
    defaultProviderId: 'provider',
    defaultAgentId: 'writer',
    defaultModelId: 'selected-model',
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[
      ProviderEndpointSettings(
        id: 'provider',
        title: 'Test Provider',
        protocol: 'openai_compatible',
        baseUrl: 'https://example.test',
        apiKey: 'key',
        modelId: 'selected-model',
        description: 'test provider',
        isDefault: true,
      ),
    ],
    extraSettings: <String, Object?>{
      'model_settings': <String, Object?>{
        'provider_id': 'provider',
        'model_id': 'selected-model',
        'thinking_enabled': false,
      },
    },
  );
}

OpeningSessionProjection _projection() {
  return OpeningSessionProjection(
    projectTypeId: 'novel',
    currentGroupId: 'starter_novel_writer_room',
    currentGroupDisplayName: '正文协作组',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_novel_writer_room',
        displayName: '正文协作组',
        description: '用于正文推进',
        isSupported: true,
        isDegraded: false,
        isCurrent: true,
        isStarterGroup: true,
      ),
    ],
    orchestration: OpeningOrchestrationResult(
      state: OpeningSessionState(
        projectTypeId: 'novel',
        status: OpeningSessionState.statusReadyForInteractiveSession,
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_novel_writer_room',
          availableAgentGroupIds: <String>['starter_novel_writer_room'],
          sessionGoalModeId: SessionRecordConstants.modeContinueWriting,
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-05-29T00:00:00.000',
        updatedAt: '2026-05-29T00:00:00.000',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: false,
        canStartInteractiveSession: true,
        missingRequirements: <OpeningMissingRequirement>[],
      ),
      suggestedActions: const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.start_interactive_session',
          commandId: 'opening.start_interactive_session',
          title: '开始会话',
          description: '直接开始。',
        ),
      ],
    ),
    availableAgentSummaries: const <OpeningAgentMemberSummary>[
      OpeningAgentMemberSummary(
        agentId: 'writer',
        displayName: '正文智能体',
        role: '负责正文创作',
        isPrimary: true,
        thinkingSupported: true,
        description: '负责完成正文初稿。',
      ),
      OpeningAgentMemberSummary(
        agentId: 'reviewer',
        displayName: '审阅智能体',
        role: '负责审阅与修订建议',
        isPrimary: false,
        thinkingSupported: true,
        description: '负责找出问题并提出修订意见。',
      ),
    ],
    currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
      agentId: 'writer',
      displayName: '正文智能体',
      role: '负责正文创作',
      thinkingSupported: true,
    ),
  );
}
