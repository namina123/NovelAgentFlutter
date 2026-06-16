import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/approval/approval_command.dart';
import 'package:novel_agent_cli/commands/shared/cli_command_context.dart';
import 'package:novel_agent_cli/commands/shared/cli_project_context_loader.dart';
import 'package:novel_agent_cli/commands/workflow/workflow_command.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowCommand productization', () {
    late _FakeSettingsRepository settingsRepository;
    late _FakeProjectRepository projectRepository;
    late _RecordingWorkflowRuntimeService workflowRuntimeService;
    late _RecordingReferenceExtractionRuntimeService
    referenceExtractionRuntimeService;
    late _RecordingTerminalPrinter printer;
    late WorkflowCommand command;

    setUp(() {
      settingsRepository = _FakeSettingsRepository();
      projectRepository = _FakeProjectRepository();
      workflowRuntimeService = _RecordingWorkflowRuntimeService();
      referenceExtractionRuntimeService =
          _RecordingReferenceExtractionRuntimeService();
      printer = _RecordingTerminalPrinter();
      command = WorkflowCommand(
        settingsRepository: settingsRepository,
        projectRepository: projectRepository,
        buildModeGuidancePlanInputUseCase:
            _UnsupportedBuildModeGuidancePlanInputUseCase(),
        loadModeGuidanceStateUseCase:
            _UnsupportedLoadModeGuidanceStateUseCase(),
        generateDraftUseCaseFactory: (_, __) => throw UnimplementedError(),
        llmGatewayFactory: (_, __) => _FakeLlmGateway(),
        workflowRuntimeService: workflowRuntimeService,
        referenceExtractionRuntimeService: referenceExtractionRuntimeService,
        approvalCommand: _buildApprovalCommand(
          settingsRepository,
          projectRepository,
          printer,
          _FakePendingResearchActionService(),
        ),
        printer: printer,
      );
    });

    test('start routes long-task launch through the user layer', () async {
      workflowRuntimeService.createResult = <String, Object?>{
        'ok': true,
        'long_task_run_path': 'tracking/long_task_runs/run_001.json',
        'changed_paths': <Object?>['tracking/long_task_runs/run_001.json'],
        'run_center_contract': <String, Object?>{
          'status_label': '已启动',
          'phase_label': '规划',
          'active_task_title': '第一阶段',
          'recommended_action_label': '继续推进',
          'stop_diagnosis': <String, Object?>{
            'present': false,
            'category': 'completed_naturally',
            'code': 'run_started',
            'label': '已启动',
            'summary': '运行已创建。',
          },
        },
      };

      final exitCode = await command.run(<String>[
        'start',
        '--mode',
        TaskRuntimeConstants.modeHumanOutlineAiDraft,
        '--outline',
        'outline/outline.md',
        '--seed',
        '第一阶段',
      ]);

      expect(exitCode, 0);
      expect(workflowRuntimeService.createCalls, hasLength(1));
      expect(
        workflowRuntimeService.createCalls.single['mode'],
        TaskRuntimeConstants.modeHumanOutlineAiDraft,
      );
      expect(printer.successes, contains('长任务队列已生成。'));
      expect(
        printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == '长任务现场摘要' && block.content.contains('状态：已启动'),
          ),
        ),
      );
    });

    test('start routes reference extraction through the user layer', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'workflow_command_start_extract_',
      );
      final sourceFile = File(
        '${tempDir.path}${Platform.pathSeparator}reference_source.txt',
      );
      await sourceFile.writeAsString('sample');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final exitCode = await command.run(<String>[
        'start',
        '--source',
        sourceFile.path,
        '--target-language',
        'zh-TW',
        '--strategy-profile',
        'reference_extraction.fact_focused',
      ]);

      expect(exitCode, 0);
      expect(referenceExtractionRuntimeService.lastRequest, isNotNull);
      expect(
        referenceExtractionRuntimeService.lastRequest!.sourceFilePath,
        sourceFile.absolute.path,
      );
      expect(printer.successes, contains('参考资产提取完成。'));
    });

    test('status prints queue and preflight summary', () async {
      workflowRuntimeService.workflowTasks = <JsonMap>[
        <String, Object?>{
          'status': 'queued',
          'task_type': 'workflow_task',
          'title': '第一章',
          'relative_path': 'tasks/ch01.json',
        },
      ];
      workflowRuntimeService.preflightResult = <String, Object?>{
        'can_run': false,
        'primary_blocker': 'waiting_user',
      };
      workflowRuntimeService.nextTaskResult = <String, Object?>{
        'title': '第一章',
        'relative_path': 'tasks/ch01.json',
      };
      workflowRuntimeService.longTaskRuns = <JsonMap>[
        <String, Object?>{
          'status': 'running',
          'title': '长任务一',
          'relative_path': 'tracking/long_task_runs/run_001.json',
        },
      ];

      final exitCode = await command.run(<String>['status']);

      expect(exitCode, 0);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            'workflow status',
            '任务总数：1\n可运行：否\n主阻塞：waiting_user\n下一任务：第一章\n最近运行：1',
          ),
        ),
      );
    });

    test('continue advances the next runnable task once', () async {
      workflowRuntimeService.runNextResult = <String, Object?>{
        'ok': true,
        'relative_path': 'tasks/ch01.json',
        'changed_paths': <Object?>['tasks/ch01.json'],
      };

      final exitCode = await command.run(<String>['continue']);

      expect(exitCode, 0);
      expect(workflowRuntimeService.runNextCalls, 1);
      expect(printer.successes, contains('下一任务已执行一轮。'));
    });

    test('inspect prints the shared chain view contract', () async {
      workflowRuntimeService.chainViewResult = <String, Object?>{
        'plans': <Object?>[
          <String, Object?>{'id': 'plan_1', 'title': '主线'},
        ],
        'next_task': <String, Object?>{
          'title': '第一章',
          'relative_path': 'tasks/ch01.json',
        },
      };

      final exitCode = await command.run(<String>['inspect']);

      expect(exitCode, 0);
      expect(
        printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'workflow inspect' &&
                block.content.contains('"next_task"'),
          ),
        ),
      );
    });

    test('logs prints recent continuous run records', () async {
      workflowRuntimeService.longTaskRuns = <JsonMap>[
        <String, Object?>{
          'status': 'running',
          'title': '长任务一',
          'relative_path': 'tracking/long_task_runs/run_001.json',
        },
        <String, Object?>{
          'status': 'paused',
          'title': '长任务二',
          'relative_path': 'tracking/long_task_runs/run_002.json',
        },
      ];

      final exitCode = await command.run(<String>['logs']);

      expect(exitCode, 0);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            'workflow logs',
            'running｜长任务一｜tracking/long_task_runs/run_001.json\n'
                'paused｜长任务二｜tracking/long_task_runs/run_002.json',
          ),
        ),
      );
    });

    test('debug help keeps the detailed operator surface accessible', () async {
      final exitCode = await command.run(<String>['debug', 'help']);

      expect(exitCode, 0);
      expect(
        printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'workflow debug help' &&
                block.content.contains('workflow debug draft') &&
                block.content.contains('workflow debug extract-reference'),
          ),
        ),
      );
    });
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings appSettings = const AppSettings(
    defaultProviderId: 'provider_1',
    defaultAgentId: '',
    defaultModelId: 'deepseek-v4-flash',
    defaultProjectPath: 'D:/test-project',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[
      ProviderEndpointSettings(
        id: 'provider_1',
        title: 'Test Provider',
        protocol: 'openai_compat',
        baseUrl: 'https://example.invalid/v1',
        apiKey: 'test-key',
        modelId: 'deepseek-v4-flash',
        description: 'for tests',
        isDefault: true,
      ),
    ],
  );

  @override
  Future<AppSettings> load() async => appSettings;

  @override
  Future<AppSettings> save(AppSettings settings) async => settings;
}

class _FakeProjectRepository implements ProjectRepository {
  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    return ProjectDescriptor(id: 'project_1', name: '测试项目', rootPath: rootPath);
  }
}

class _FakePendingResearchActionService
    implements ProjectPendingResearchActionService {
  @override
  Future<List<JsonMap>> list(ProjectDescriptor project) async =>
      const <JsonMap>[];

  @override
  Future<JsonMap> load(
    ProjectDescriptor project, {
    required String requestId,
  }) async => const <String, Object?>{};

  @override
  Future<JsonMap> approve(
    ProjectDescriptor project, {
    required String requestId,
    String actorId = 'pending_research_action_service',
    String note = '',
  }) async => const <String, Object?>{'ok': true};

  @override
  Future<JsonMap> reject(
    ProjectDescriptor project, {
    required String requestId,
    String actorId = 'pending_research_action_service',
    String note = '',
  }) async => const <String, Object?>{'ok': true};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTerminalPrinter extends TerminalPrinter {
  final List<String> infos = <String>[];
  final List<String> successes = <String>[];
  final List<String> errors = <String>[];
  final List<_PrintedBlock> blocks = <_PrintedBlock>[];

  @override
  void info(String message) {
    infos.add(message);
  }

  @override
  void success(String message) {
    successes.add(message);
  }

  @override
  void error(String message) {
    errors.add(message);
  }

  @override
  void block(String title, String content) {
    blocks.add(_PrintedBlock(title, content));
  }
}

class _PrintedBlock {
  const _PrintedBlock(this.title, this.content);

  final String title;
  final String content;

  @override
  bool operator ==(Object other) {
    return other is _PrintedBlock &&
        other.title == title &&
        other.content == content;
  }

  @override
  int get hashCode => Object.hash(title, content);
}

class _RecordingWorkflowRuntimeService
    implements ProjectWorkflowRuntimeService {
  List<JsonMap> workflowTasks = const <JsonMap>[];
  JsonMap preflightResult = const <String, Object?>{'can_run': true};
  JsonMap nextTaskResult = const <String, Object?>{};
  JsonMap chainViewResult = const <String, Object?>{};
  List<JsonMap> longTaskRuns = const <JsonMap>[];
  JsonMap createResult = const <String, Object?>{'ok': true};
  JsonMap runNextResult = const <String, Object?>{'ok': true};
  final List<Map<String, Object?>> createCalls = <Map<String, Object?>>[];
  int runNextCalls = 0;

  @override
  Future<List<JsonMap>> listWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async => workflowTasks;

  @override
  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async => preflightResult;

  @override
  Future<JsonMap> nextWorkflowTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async => nextTaskResult;

  @override
  Future<JsonMap> workflowChainView(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async => chainViewResult;

  @override
  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 10,
  }) async => longTaskRuns;

  @override
  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) async {
    createCalls.add(<String, Object?>{
      'project': project.rootPath,
      'mode': mode,
      'options': ValueReaders.deepCopyMap(options),
    });
    return createResult;
  }

  @override
  Future<JsonMap> runNextWorkflowTaskOnce(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    runNextCalls += 1;
    return runNextResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingReferenceExtractionRuntimeService
    extends ProjectReferenceExtractionRuntimeService {
  _RecordingReferenceExtractionRuntimeService()
    : super(
        workspacePort: LocalProjectWorkspacePort(),
        loadAvailableAgents: (_) async => const <JsonMap>[],
        loadAvailableGroups: (_) async => const <JsonMap>[],
        groupBindingRepository: ProjectAgentGroupBindingRepository(
          workspacePort: LocalProjectWorkspacePort(),
        ),
        proposalGeneratorFactory:
            ({required LlmGateway llmGateway, required String modelId}) =>
                throw UnimplementedError(),
      );

  ProjectReferenceExtractionRequest? lastRequest;

  @override
  Future<ProjectReferenceExtractionResult> execute({
    required ProjectDescriptor project,
    required LlmGateway llmGateway,
    required String modelId,
    required ProjectReferenceExtractionRequest request,
  }) async {
    lastRequest = request;
    return ProjectReferenceExtractionResult(
      runId: 'run_cli_extract_1',
      packageId: 'pkg_cli',
      packageVersionId: 'v1',
      sourceFilePath: request.sourceFilePath,
      sourceDecodeMode: 'utf8',
      groupResolutionKind: 'single_agent_fallback',
      selectedGroupId: 'reference_extraction_group',
      strategyProfileId: 'reference_extraction.standard',
      executionConcurrencyMode: ReferenceExtractionConcurrencyModes.single,
      proposalCount: 5,
      acceptedProposalCount: 2,
      finalizedEntryCount: 7,
      runStatus: ReferenceExtractionRunStatuses.completedPublishable,
      publishedSnapshotAvailable: true,
      attachToProjectRequested: request.attachToProject,
      projectMountedEntriesRequested: request.projectMountedEntries,
      projectMountStatus: request.projectMountedEntries
          ? ProjectReferenceMountStatuses.applied
          : request.attachToProject
          ? ProjectReferenceMountStatuses.attachedOnly
          : ProjectReferenceMountStatuses.notRequested,
      generatedProjectionPaths: const <String>[],
    );
  }
}

ApprovalCommand _buildApprovalCommand(
  _FakeSettingsRepository settingsRepository,
  _FakeProjectRepository projectRepository,
  _RecordingTerminalPrinter printer,
  ProjectPendingResearchActionService pendingResearchActionService,
) {
  // 中文注释: workflow 产品层测试只需要一个可记录的 approval shell，不在这里引入额外审批逻辑。
  return ApprovalCommand(
    pendingResearchActionService: pendingResearchActionService,
    projectContextLoader: CliProjectContextLoader(
      commandContext: CliCommandContext(
        settings: settingsRepository.appSettings,
        defaultProjectPath: settingsRepository.appSettings.defaultProjectPath,
      ),
      projectRepository: projectRepository,
      printer: printer,
    ),
    printer: printer,
  );
}

class _FakeLlmGateway implements LlmGateway {
  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) {
    throw UnimplementedError();
  }
}

class _UnsupportedBuildModeGuidancePlanInputUseCase
    implements BuildModeGuidancePlanInputUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnsupportedLoadModeGuidanceStateUseCase
    implements LoadModeGuidanceStateUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
