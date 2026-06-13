import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/workflow/workflow_command.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowCommand extract-reference', () {
    late _FakeSettingsRepository settingsRepository;
    late _FakeProjectRepository projectRepository;
    late _RecordingReferenceExtractionRuntimeService
    referenceExtractionRuntimeService;
    late _RecordingTerminalPrinter printer;
    late WorkflowCommand command;

    setUp(() {
      settingsRepository = _FakeSettingsRepository();
      settingsRepository.appSettings = const AppSettings(
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
      projectRepository = _FakeProjectRepository();
      referenceExtractionRuntimeService =
          _RecordingReferenceExtractionRuntimeService();
      printer = _RecordingTerminalPrinter();
      command = WorkflowCommand(
        settingsRepository: settingsRepository,
        projectRepository: projectRepository,
        saveDraftUseCase: _UnsupportedSaveDraftUseCase(),
        buildModeGuidancePlanInputUseCase:
            _UnsupportedBuildModeGuidancePlanInputUseCase(),
        loadModeGuidanceStateUseCase:
            _UnsupportedLoadModeGuidanceStateUseCase(),
        generateDraftUseCaseFactory: (_, __) => throw UnimplementedError(),
        llmGatewayFactory: (_, __) => _FakeLlmGateway(),
        workflowRuntimeService: _UnsupportedWorkflowRuntimeService(),
        referenceExtractionRuntimeService: referenceExtractionRuntimeService,
        pendingResearchActionService: _FakePendingResearchActionService(),
        printer: printer,
      );
    });

    test(
      'builds request through shared extraction builder and prints summary',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'workflow_command_extract_reference_test_',
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
          'extract-reference',
          '--source',
          sourceFile.path,
          '--target-language',
          'zh-TW',
          '--max-chapters',
          '8',
          '--max-entities',
          '4',
          '--no-project-mount',
          '--strategy-profile',
          'reference_extraction.fact_focused',
        ]);

        expect(exitCode, 0);
        expect(referenceExtractionRuntimeService.lastProject?.id, 'project_1');
        expect(
          referenceExtractionRuntimeService.lastModelId,
          'deepseek-v4-flash',
        );
        expect(
          referenceExtractionRuntimeService.lastRequest?.sourceFilePath,
          sourceFile.absolute.path,
        );
        expect(
          referenceExtractionRuntimeService.lastRequest?.displayName,
          '参考资料提取：reference_source.txt',
        );
        expect(
          referenceExtractionRuntimeService.lastRequest?.sourceLanguage,
          '',
        );
        expect(
          referenceExtractionRuntimeService.lastRequest?.strategyProfileId,
          'reference_extraction.fact_focused',
        );
        expect(
          referenceExtractionRuntimeService.lastRequest?.targetLanguage,
          'zh-TW',
        );
        expect(
          referenceExtractionRuntimeService.lastRequest?.maxChapterEntries,
          8,
        );
        expect(
          referenceExtractionRuntimeService.lastRequest?.maxEntityEntries,
          4,
        );
        expect(
          referenceExtractionRuntimeService.lastRequest?.projectMountedEntries,
          isFalse,
        );
        expect(
          referenceExtractionRuntimeService.lastRequest?.availableContextChars,
          131072,
        );
        expect(printer.successes, contains('参考资产提取完成。'));
        expect(printer.infos, contains('模型: deepseek-v4-flash'));
        expect(
          printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == '参考提取摘要' &&
                  block.content.contains('控制面：已完成') &&
                  block.content.contains(
                    '停止原因：publishable 结果已完成（completed_publishable）',
                  ) &&
                  block.content.contains(
                    '策略：标准提取 (reference_extraction.standard)',
                  ) &&
                  block.content.contains('挂载：仅登记 attachment，未生成项目投影'),
            ),
          ),
        );
      },
    );

    test('lists extraction strategies without touching runtime', () async {
      final exitCode = await command.run(<String>[
        'extract-reference',
        '--list-strategies',
      ]);

      expect(exitCode, 0);
      expect(referenceExtractionRuntimeService.lastRequest, isNull);
      expect(
        printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == '参考提取策略' &&
                block.content.contains('标准提取｜reference_extraction.standard') &&
                block.content.contains(
                  '长上下文整书｜reference_extraction.bulk_long_context',
                ) &&
                block.content.contains(
                  '事实优先｜reference_extraction.fact_focused',
                ) &&
                block.content.contains('探索扩展｜reference_extraction.exploratory'),
          ),
        ),
      );
    });
  });

  group('WorkflowCommand long-task minimal controls', () {
    late _FakeSettingsRepository settingsRepository;
    late _FakeProjectRepository projectRepository;
    late _RecordingWorkflowRuntimeService workflowRuntimeService;
    late _RecordingTerminalPrinter printer;
    late WorkflowCommand command;

    setUp(() {
      settingsRepository = _FakeSettingsRepository();
      projectRepository = _FakeProjectRepository();
      workflowRuntimeService = _RecordingWorkflowRuntimeService();
      printer = _RecordingTerminalPrinter();
      command = WorkflowCommand(
        settingsRepository: settingsRepository,
        projectRepository: projectRepository,
        saveDraftUseCase: _UnsupportedSaveDraftUseCase(),
        buildModeGuidancePlanInputUseCase:
            _UnsupportedBuildModeGuidancePlanInputUseCase(),
        loadModeGuidanceStateUseCase:
            _UnsupportedLoadModeGuidanceStateUseCase(),
        generateDraftUseCaseFactory: (_, __) => throw UnimplementedError(),
        llmGatewayFactory: (_, __) => _FakeLlmGateway(),
        workflowRuntimeService: workflowRuntimeService,
        referenceExtractionRuntimeService:
            _unsupportedReferenceExtractionRuntimeService(),
        pendingResearchActionService: _FakePendingResearchActionService(),
        printer: printer,
      );
    });

    test('pause falls back to latest long-task run record', () async {
      workflowRuntimeService.longTaskRuns = <JsonMap>[
        <String, Object?>{
          'relative_path': 'tracking/long_task_runs/run_pause.json',
        },
      ];
      workflowRuntimeService.pauseResult = <String, Object?>{
        'ok': true,
        'long_task_run_path': 'tracking/long_task_runs/run_pause.json',
      };

      final exitCode = await command.run(<String>['pause']);

      expect(exitCode, 0);
      expect(workflowRuntimeService.pauseCalls, <String>[
        'tracking/long_task_runs/run_pause.json',
      ]);
      expect(printer.successes, contains('长任务运行已暂停。'));
      expect(
        printer.infos,
        contains('项目路径: tracking/long_task_runs/run_pause.json'),
      );
    });

    test(
      'resume uses shared runtime entry and prints run center summary',
      () async {
        settingsRepository.appSettings = AppSettings(
          defaultProviderId: 'provider_1',
          defaultAgentId: '',
          defaultModelId: 'gpt-test',
          defaultProjectPath: 'D:/test-project',
          autoSaveDrafts: false,
          providers: const <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'provider_1',
              title: 'Test Provider',
              protocol: 'openai_compat',
              baseUrl: 'https://example.invalid/v1',
              apiKey: 'test-key',
              modelId: 'gpt-test',
              description: 'for tests',
              isDefault: true,
            ),
          ],
        );
        workflowRuntimeService.longTaskRuns = <JsonMap>[
          <String, Object?>{
            'relative_path': 'tracking/long_task_runs/run_resume.json',
          },
        ];
        workflowRuntimeService.resumeResult = <String, Object?>{
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

        final exitCode = await command.run(<String>['resume']);

        expect(exitCode, 0);
        expect(
          workflowRuntimeService.resumeCalls.single['run_path'],
          'tracking/long_task_runs/run_resume.json',
        );
        expect(printer.successes, contains('长任务运行已恢复推进。'));
        expect(
          printer.blocks,
          contains(
            _PrintedBlock(
              '长任务现场摘要',
              '状态：等待用户确认\n阶段：检查点确认\n当前任务：检查点：第 12 章\n停止原因：等待用户确认（waiting_user_checkpoint）\n下一步：先处理检查点确认',
            ),
          ),
        );
      },
    );

    test('checkpoint-actions prints shared action package', () async {
      workflowRuntimeService.checkpointActionPackage = <String, Object?>{
        'ok': true,
        'checkpoint_review_path': 'tracking/checkpoint_reviews/ch01.json',
        'severity_label': '高风险',
        'action_summary': '建议动作：生成后续审稿、继续主链',
        'recommended_action_id': 'create_followup_review_tasks',
        'actions': <Object?>[
          <String, Object?>{
            'id': 'create_followup_review_tasks',
            'label': '生成后续审稿',
            'enabled': true,
            'host_command': 'apply_checkpoint_review_action',
          },
        ],
      };

      final exitCode = await command.run(<String>[
        'checkpoint-actions',
        '--review',
        'tracking/checkpoint_reviews/ch01.json',
      ]);

      expect(exitCode, 0);
      expect(workflowRuntimeService.checkpointActionRequests, <String>[
        'tracking/checkpoint_reviews/ch01.json',
      ]);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            'checkpoint 动作包',
            '{\n  "ok": true,\n  "checkpoint_review_path": "tracking/checkpoint_reviews/ch01.json",\n  "severity_label": "高风险",\n  "action_summary": "建议动作：生成后续审稿、继续主链",\n  "recommended_action_id": "create_followup_review_tasks",\n  "actions": [\n    {\n      "id": "create_followup_review_tasks",\n      "label": "生成后续审稿",\n      "enabled": true,\n      "host_command": "apply_checkpoint_review_action"\n    }\n  ]\n}',
          ),
        ),
      );
    });
  });

  group('WorkflowCommand pending-research', () {
    late _FakeSettingsRepository settingsRepository;
    late _FakeProjectRepository projectRepository;
    late _FakePendingResearchActionService pendingResearchActionService;
    late _RecordingTerminalPrinter printer;
    late WorkflowCommand command;

    setUp(() {
      settingsRepository = _FakeSettingsRepository();
      projectRepository = _FakeProjectRepository();
      pendingResearchActionService = _FakePendingResearchActionService();
      printer = _RecordingTerminalPrinter();
      command = WorkflowCommand(
        settingsRepository: settingsRepository,
        projectRepository: projectRepository,
        saveDraftUseCase: _UnsupportedSaveDraftUseCase(),
        buildModeGuidancePlanInputUseCase:
            _UnsupportedBuildModeGuidancePlanInputUseCase(),
        loadModeGuidanceStateUseCase:
            _UnsupportedLoadModeGuidanceStateUseCase(),
        generateDraftUseCaseFactory: (_, __) => throw UnimplementedError(),
        llmGatewayFactory: (_, __) => _FakeLlmGateway(),
        workflowRuntimeService: _UnsupportedWorkflowRuntimeService(),
        referenceExtractionRuntimeService:
            _unsupportedReferenceExtractionRuntimeService(),
        pendingResearchActionService: pendingResearchActionService,
        printer: printer,
      );
    });

    test('list prints human-readable pending research lines', () async {
      pendingResearchActionService.listResult = <JsonMap>[
        <String, Object?>{
          'request_id': 'research_request_1',
          'request_state': 'awaiting_user_confirmation',
          'research_request': <String, Object?>{'query': '北境钟楼来历'},
          'permission_decision': <String, Object?>{'reason': '需要联网确认'},
        },
        <String, Object?>{
          'request_id': 'research_request_2',
          'request_state': 'pending_gateway_execution',
          'research_request': <String, Object?>{'query': '港口潮汐资料'},
        },
      ];

      final exitCode = await command.run(<String>['pending-research', 'list']);

      expect(exitCode, 0);
      expect(pendingResearchActionService.listCalled, isTrue);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            '待处理资料研究',
            'research_request_1｜等待确认｜北境钟楼来历｜需要联网确认\n'
                'research_request_2｜待处理｜港口潮汐资料',
          ),
        ),
      );
    });

    test('approve forwards request id and note to action service', () async {
      pendingResearchActionService.approveResult = <String, Object?>{
        'ok': true,
        'request_id': 'research_request_approve_1',
        'request_state': 'pending_gateway_execution',
        'action_status': 'updated',
        'changed_paths': <Object?>[
          '.novel_agent/information/research_requests/research_request_approve_1.json',
        ],
      };

      final exitCode = await command.run(<String>[
        'pending-research',
        'approve',
        '--request',
        'research_request_approve_1',
        '--note',
        '允许继续研究',
      ]);

      expect(exitCode, 0);
      expect(pendingResearchActionService.approveCalls, hasLength(1));
      expect(pendingResearchActionService.approveCalls.single, <String, String>{
        'request_id': 'research_request_approve_1',
        'actor_id': 'novel_agent_cli',
        'note': '允许继续研究',
      });
      expect(printer.successes, contains('资料研究请求已确认。'));
      expect(printer.infos, contains('请求: research_request_approve_1'));
      expect(printer.infos, contains('状态: 待处理'));
    });

    test('reject requires request id before calling action service', () async {
      final exitCode = await command.run(<String>[
        'pending-research',
        'reject',
      ]);

      expect(exitCode, 2);
      expect(pendingResearchActionService.rejectCalls, isEmpty);
      expect(printer.errors, contains('请通过 --request 或 --id 指定资料请求。'));
    });
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings appSettings = const AppSettings(
    defaultProviderId: '',
    defaultAgentId: '',
    defaultModelId: '',
    defaultProjectPath: 'D:/test-project',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[],
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
  List<JsonMap> listResult = const <JsonMap>[];
  JsonMap approveResult = const <String, Object?>{
    'ok': true,
    'request_id': '',
    'request_state': '',
    'action_status': 'updated',
    'changed_paths': <Object?>[],
  };
  JsonMap rejectResult = const <String, Object?>{
    'ok': true,
    'request_id': '',
    'request_state': '',
    'action_status': 'updated',
    'changed_paths': <Object?>[],
  };
  bool listCalled = false;
  final List<Map<String, String>> approveCalls = <Map<String, String>>[];
  final List<Map<String, String>> rejectCalls = <Map<String, String>>[];

  @override
  Future<List<JsonMap>> list(ProjectDescriptor project) async {
    listCalled = true;
    return listResult;
  }

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
    return approveResult;
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
    return rejectResult;
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

  ProjectDescriptor? lastProject;
  String lastModelId = '';
  ProjectReferenceExtractionRequest? lastRequest;

  @override
  Future<ProjectReferenceExtractionResult> execute({
    required ProjectDescriptor project,
    required LlmGateway llmGateway,
    required String modelId,
    required ProjectReferenceExtractionRequest request,
  }) async {
    lastProject = project;
    lastModelId = modelId;
    lastRequest = request;
    final mountedEntriesRequested = request.projectMountedEntries;
    return ProjectReferenceExtractionResult(
      runId: 'run_cli_extract_1',
      packageId: 'pkg_cli',
      packageVersionId: 'v1',
      sourceFilePath: 'D:/source/book.txt',
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
      projectMountedEntriesRequested: mountedEntriesRequested,
      projectMountStatus: mountedEntriesRequested
          ? ProjectReferenceMountStatuses.applied
          : request.attachToProject
          ? ProjectReferenceMountStatuses.attachedOnly
          : ProjectReferenceMountStatuses.notRequested,
      generatedProjectionPaths: mountedEntriesRequested
          ? <String>['knowledge/项目知识摘要.md']
          : const <String>[],
    );
  }
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

ProjectReferenceExtractionRuntimeService
_unsupportedReferenceExtractionRuntimeService() {
  final workspacePort = LocalProjectWorkspacePort();
  return ProjectReferenceExtractionRuntimeService(
    workspacePort: workspacePort,
    loadAvailableAgents: (_) async => const <JsonMap>[],
    loadAvailableGroups: (_) async => const <JsonMap>[],
    groupBindingRepository: ProjectAgentGroupBindingRepository(
      workspacePort: workspacePort,
    ),
    proposalGeneratorFactory:
        ({required LlmGateway llmGateway, required String modelId}) =>
            throw UnimplementedError(),
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

class _UnsupportedSaveDraftUseCase implements SaveDraftUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

class _UnsupportedWorkflowRuntimeService
    implements ProjectWorkflowRuntimeService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingWorkflowRuntimeService
    implements ProjectWorkflowRuntimeService {
  List<JsonMap> longTaskRuns = const <JsonMap>[];
  JsonMap pauseResult = const <String, Object?>{'ok': true};
  JsonMap resumeResult = const <String, Object?>{'ok': true};
  JsonMap checkpointActionPackage = const <String, Object?>{'ok': false};
  final List<String> pauseCalls = <String>[];
  final List<Map<String, String>> resumeCalls = <Map<String, String>>[];
  final List<String> checkpointActionRequests = <String>[];

  @override
  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 20,
  }) async => longTaskRuns;

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
    resumeCalls.add(<String, String>{
      'project_root': project.rootPath,
      'run_path': runPath,
    });
    return resumeResult;
  }

  @override
  Future<JsonMap> buildCheckpointReviewActionPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) async {
    checkpointActionRequests.add(checkpointReviewPath);
    return checkpointActionPackage;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
