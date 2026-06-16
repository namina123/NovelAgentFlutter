import 'dart:async';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/bootstrap/cli_bootstrap.dart';
import 'package:novel_agent_cli/commands/approval/approval_command.dart';
import 'package:novel_agent_cli/commands/session/session_command.dart';
import 'package:novel_agent_cli/commands/shared/cli_automation_input_service.dart';
import 'package:novel_agent_cli/commands/shared/cli_command_context.dart';
import 'package:novel_agent_cli/commands/shared/cli_mode_detection_service.dart';
import 'package:novel_agent_cli/commands/shared/cli_project_context_loader.dart';
import 'package:novel_agent_cli/commands/workflow/workflow_command.dart';
import 'package:novel_agent_cli/output/cli_json_output_writer.dart';
import 'package:novel_agent_cli/output/cli_output_settings.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('CLI smoke', () {
    test('root help stays on the production bootstrap path', () async {
      final stdoutLines = <String>[];
      final exitCode = await _captureStdout(
        () => CliBootstrap().run(const <String>['help']),
        stdoutLines,
      );

      expect(exitCode, 0);
      expect(stdoutLines.single, contains('== novel_agent help =='));
      expect(stdoutLines.single, contains('config show'));
      expect(stdoutLines.single, contains('doctor'));
    });

    test('workflow help stays on the production command path', () async {
      final bundle = _buildSmokeBundle();

      final exitCode = await bundle.workflowCommand.run(<String>['help']);

      expect(exitCode, 0);
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'workflow help' &&
                block.content.contains('workflow start') &&
                block.content.contains('workflow debug ...'),
          ),
        ),
      );
    });

    test(
      'session help and resume smoke stay on the shared session shell',
      () async {
        final bundle = _buildSmokeBundle();

        final helpExitCode = await bundle.sessionCommand.run(<String>[
          'help',
        ], defaultProjectPath: bundle.project.rootPath);
        final resumeExitCode = await bundle.sessionCommand.run(<String>[
          'resume',
        ], defaultProjectPath: bundle.project.rootPath);

        expect(helpExitCode, 0);
        expect(resumeExitCode, 0);
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session help' &&
                  block.content.contains('session start') &&
                  block.content.contains('session send'),
            ),
          ),
        );
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session resume' &&
                  block.content.contains('会话 ID：session_1'),
            ),
          ),
        );
      },
    );

    test(
      'approval help and approve/reject smoke stay on the shared approval path',
      () async {
        final bundle = _buildSmokeBundle();

        final helpExitCode = await bundle.approvalCommand.run(<String>['help']);
        final approveExitCode = await bundle.approvalCommand.run(<String>[
          'approve',
          '--request',
          'research_request_smoke_1',
          '--note',
          '允许继续研究',
        ]);
        final rejectExitCode = await bundle.approvalCommand.run(<String>[
          'reject',
          '--request',
          'research_request_smoke_1',
          '--note',
          '拒绝这次请求',
        ]);

        expect(helpExitCode, 0);
        expect(approveExitCode, 0);
        expect(rejectExitCode, 0);
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'approval help' &&
                  block.content.contains('approval approve') &&
                  block.content.contains('approval reject'),
            ),
          ),
        );
        expect(bundle.pendingResearchActionService.approveCalls, isNotEmpty);
        expect(bundle.pendingResearchActionService.rejectCalls, isNotEmpty);
      },
    );

    test(
      'workflow pause resume and extract-reference smoke use the production contracts',
      () async {
        final bundle = _buildSmokeBundle();
        final tempDir = await Directory.systemTemp.createTemp(
          'novel_agent_cli_smoke_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
        final sourceFile = File(
          '${tempDir.path}${Platform.pathSeparator}reference_source.txt',
        );
        await sourceFile.writeAsString('sample');
        bundle.workflowRuntimeService.pauseResult = <String, Object?>{
          'ok': true,
          'long_task_run_path': 'tracking/long_task_runs/run_pause.json',
        };
        bundle.workflowRuntimeService.resumeResult = <String, Object?>{
          'ok': true,
          'long_task_run_path': 'tracking/long_task_runs/run_resume.json',
          'run_center_contract': <String, Object?>{
            'status_label': '等待用户确认',
            'phase_label': '检查点确认',
            'active_task_title': '检查点：第 12 章',
            'recommended_action_label': '先处理检查点确认',
            'stop_diagnosis': <String, Object?>{
              'present': true,
              'category': 'waiting_user',
              'code': 'waiting_user_checkpoint',
              'label': '等待用户确认',
              'summary': '当前运行正在等待用户确认。',
            },
          },
        };

        final pauseExitCode = await bundle.workflowCommand.run(<String>[
          'pause',
        ]);
        final resumeExitCode = await bundle.workflowCommand.run(<String>[
          'resume',
        ]);
        final extractExitCode = await bundle.workflowCommand.run(<String>[
          'extract-reference',
          '--source',
          sourceFile.path,
          '--target-language',
          'zh-TW',
          '--strategy-profile',
          'reference_extraction.fact_focused',
        ]);

        expect(pauseExitCode, 0);
        expect(resumeExitCode, 0);
        expect(extractExitCode, 0);
        expect(bundle.workflowRuntimeService.pauseCalls, isNotEmpty);
        expect(bundle.workflowRuntimeService.resumeCalls, isNotEmpty);
        expect(bundle.referenceExtractionRuntimeService.lastRequest, isNotNull);
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == '参考提取摘要' &&
                  block.content.contains('reference_extraction.fact_focused'),
            ),
          ),
        );
      },
    );
  });
}

Future<int> _captureStdout(
  Future<int> Function() body,
  List<String> stdoutLines,
) async {
  final exitCode = await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) {
        stdoutLines.add(line);
      },
    ),
  );
  return exitCode;
}

_SmokeBundle _buildSmokeBundle() {
  final settingsRepository = _SmokeSettingsRepository();
  final projectRepository = _SmokeProjectRepository();
  final printer = _RecordingTerminalPrinter();
  final pendingResearchActionService = _SmokePendingResearchActionService();
  final approvalCommand = ApprovalCommand(
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
  final workflowRuntimeService = _SmokeWorkflowRuntimeService();
  final referenceExtractionRuntimeService =
      _SmokeReferenceExtractionRuntimeService();
  final workflowCommand = WorkflowCommand(
    settingsRepository: settingsRepository,
    projectRepository: projectRepository,
    buildModeGuidancePlanInputUseCase:
        _UnsupportedBuildModeGuidancePlanInputUseCase(),
    loadModeGuidanceStateUseCase: _UnsupportedLoadModeGuidanceStateUseCase(),
    generateDraftUseCaseFactory: (_, __) => throw UnimplementedError(),
    llmGatewayFactory: (_, __) => _FakeLlmGateway(),
    workflowRuntimeService: workflowRuntimeService,
    referenceExtractionRuntimeService: referenceExtractionRuntimeService,
    approvalCommand: approvalCommand,
    printer: printer,
    automationInputService: CliAutomationInputService(
      modeDetectionService: const CliModeDetectionService(
        stdinHasTerminal: _alwaysTrue,
        stdoutHasTerminal: _alwaysTrue,
      ),
      stdinHasTerminal: _alwaysTrue,
      stdinReader: () async => '',
    ),
  );
  final sessionCommand = SessionCommand(
    sessionShellService: _SmokeSessionShellService(),
    projectContextLoader: CliProjectContextLoader(
      commandContext: CliCommandContext(
        settings: settingsRepository.appSettings,
        defaultProjectPath: settingsRepository.appSettings.defaultProjectPath,
      ),
      projectRepository: projectRepository,
      printer: printer,
    ),
    automationInputService: CliAutomationInputService(
      modeDetectionService: const CliModeDetectionService(
        stdinHasTerminal: _alwaysTrue,
        stdoutHasTerminal: _alwaysTrue,
      ),
      stdinHasTerminal: _alwaysTrue,
      stdinReader: () async => '',
    ),
    printer: printer,
  );
  return _SmokeBundle(
    approvalCommand: approvalCommand,
    pendingResearchActionService: pendingResearchActionService,
    printer: printer,
    project: projectRepository.project,
    referenceExtractionRuntimeService: referenceExtractionRuntimeService,
    sessionCommand: sessionCommand,
    workflowCommand: workflowCommand,
    workflowRuntimeService: workflowRuntimeService,
  );
}

class _SmokeBundle {
  const _SmokeBundle({
    required this.approvalCommand,
    required this.pendingResearchActionService,
    required this.printer,
    required this.project,
    required this.referenceExtractionRuntimeService,
    required this.sessionCommand,
    required this.workflowCommand,
    required this.workflowRuntimeService,
  });

  final ApprovalCommand approvalCommand;
  final _SmokePendingResearchActionService pendingResearchActionService;
  final _RecordingTerminalPrinter printer;
  final ProjectDescriptor project;
  final _SmokeReferenceExtractionRuntimeService
  referenceExtractionRuntimeService;
  final SessionCommand sessionCommand;
  final WorkflowCommand workflowCommand;
  final _SmokeWorkflowRuntimeService workflowRuntimeService;
}

class _SmokeSettingsRepository implements SettingsRepository {
  AppSettings appSettings = const AppSettings(
    defaultProviderId: 'provider_1',
    defaultAgentId: '',
    defaultModelId: 'deepseek-v4-flash',
    defaultProjectPath: 'D:/smoke-project',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[
      ProviderEndpointSettings(
        id: 'provider_1',
        title: 'Smoke Provider',
        protocol: 'openai_compat',
        baseUrl: 'https://example.invalid/v1',
        apiKey: 'smoke-key',
        modelId: 'deepseek-v4-flash',
        description: 'smoke',
        isDefault: true,
      ),
    ],
  );

  @override
  Future<AppSettings> load() async => appSettings;

  @override
  Future<AppSettings> save(AppSettings settings) async => settings;
}

class _SmokeProjectRepository implements ProjectRepository {
  _SmokeProjectRepository()
    : project = ProjectDescriptor(
        id: 'project_smoke',
        name: 'Smoke Project',
        rootPath: 'D:/smoke-project',
      );

  final ProjectDescriptor project;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async => project;
}

class _SmokeSessionShellService extends ProjectSessionShellService {
  _SmokeSessionShellService()
    : super(
        sessionWorkspaceService: ProjectSessionWorkspaceService(
          hostPort: ProjectWorkspaceToolHostAdapter(
            workspacePort: LocalProjectWorkspacePort(),
            fileMutationAdapter: LocalProjectFileMutationAdapter(),
          ),
        ),
      );

  @override
  Future<JsonMap> resumeSession(
    ProjectDescriptor project, {
    String now = '',
    String sessionId = '',
  }) async {
    return <String, Object?>{
      'ok': true,
      'session_id': 'session_1',
      'resume_source': 'active_session',
      'public_status': '创作已启动',
      'public_summary': '已恢复到可继续输入的状态。',
      'context_markdown': '第一轮正文',
      'session_record': <String, Object?>{
        'workflow_stage': 'running',
        'title': '会话一',
      },
    };
  }
}

class _SmokePendingResearchActionService
    implements ProjectPendingResearchActionService {
  final List<Map<String, String>> approveCalls = <Map<String, String>>[];
  final List<Map<String, String>> rejectCalls = <Map<String, String>>[];

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
  }) async {
    approveCalls.add(<String, String>{
      'request_id': requestId,
      'actor_id': actorId,
      'note': note,
    });
    return <String, Object?>{
      'ok': true,
      'request_id': requestId,
      'request_state': 'pending_gateway_execution',
      'action_status': 'updated',
      'changed_paths': <Object?>[],
    };
  }

  @override
  Future<JsonMap> reject(
    ProjectDescriptor project, {
    required String requestId,
    String actorId = 'pending_research_action_service',
    String note = '',
  }) async {
    rejectCalls.add(<String, String>{
      'request_id': requestId,
      'actor_id': actorId,
      'note': note,
    });
    return <String, Object?>{
      'ok': true,
      'request_id': requestId,
      'request_state': 'rejected',
      'action_status': 'updated',
      'changed_paths': <Object?>[],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SmokeWorkflowRuntimeService implements ProjectWorkflowRuntimeService {
  final List<String> pauseCalls = <String>[];
  final List<String> resumeCalls = <String>[];
  JsonMap pauseResult = const <String, Object?>{'ok': true};
  JsonMap resumeResult = const <String, Object?>{'ok': true};

  @override
  Future<JsonMap> pauseLongTaskRun(
    ProjectDescriptor project,
    String runPath, {
    String note = '',
  }) async {
    pauseCalls.add(runPath);
    return pauseResult;
  }

  @override
  Future<JsonMap> resumeLongTaskRun(
    ProjectDescriptor project,
    AppSettings settings,
    String runPath, {
    JsonMap agent = const <String, Object?>{},
    JsonMap options = const <String, Object?>{},
  }) async {
    resumeCalls.add(runPath);
    return resumeResult;
  }

  @override
  Future<JsonMap> buildCheckpointReviewActionPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) async {
    return const <String, Object?>{'ok': false};
  }

  @override
  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 20,
  }) async {
    return <JsonMap>[
      <String, Object?>{
        'relative_path': 'tracking/long_task_runs/run_001.json',
      },
    ];
  }

  @override
  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) async => const <String, Object?>{'ok': true};

  @override
  Future<JsonMap> runNextWorkflowTaskOnce(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap agent = const <String, Object?>{},
  }) async => const <String, Object?>{'ok': true};

  @override
  Future<List<JsonMap>> listWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async => const <JsonMap>[];

  @override
  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async => const <String, Object?>{'can_run': true};

  @override
  Future<JsonMap> nextWorkflowTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async => const <String, Object?>{};

  @override
  Future<JsonMap> workflowChainView(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async => const <String, Object?>{};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SmokeReferenceExtractionRuntimeService
    extends ProjectReferenceExtractionRuntimeService {
  _SmokeReferenceExtractionRuntimeService()
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
      runId: 'run_smoke_extract_1',
      packageId: 'pkg_smoke',
      packageVersionId: 'v1',
      sourceFilePath: request.sourceFilePath,
      sourceDecodeMode: 'utf8',
      groupResolutionKind: 'single_agent_fallback',
      selectedGroupId: 'reference_extraction_group',
      strategyProfileId: request.strategyProfileId,
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

class _RecordingTerminalPrinter extends TerminalPrinter {
  _RecordingTerminalPrinter()
    : super(
        settings: const CliOutputSettings(),
        jsonWriter: CliJsonOutputWriter(),
      );

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

bool _alwaysTrue() => true;

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
