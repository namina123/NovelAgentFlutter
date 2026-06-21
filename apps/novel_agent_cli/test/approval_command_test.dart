import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/approval/approval_command.dart';
import 'package:novel_agent_cli/commands/shared/cli_automation_input_service.dart';
import 'package:novel_agent_cli/commands/shared/cli_mode_detection_service.dart';
import 'package:novel_agent_cli/commands/shared/cli_command_context.dart';
import 'package:novel_agent_cli/commands/shared/cli_project_context_loader.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ApprovalCommand', () {
    late _FakeSettingsRepository settingsRepository;
    late _FakeProjectRepository projectRepository;
    late _FakePendingResearchActionService pendingResearchActionService;
    late _RecordingTerminalPrinter printer;
    late ApprovalCommand command;

    setUp(() {
      settingsRepository = _FakeSettingsRepository();
      projectRepository = _FakeProjectRepository();
      pendingResearchActionService = _FakePendingResearchActionService();
      printer = _RecordingTerminalPrinter();
      command = ApprovalCommand(
        pendingResearchActionService: pendingResearchActionService,
        projectContextLoader: CliProjectContextLoader(
          commandContext: CliCommandContext(
            settings: settingsRepository.appSettings,
            defaultProjectPath:
                settingsRepository.appSettings.defaultProjectPath,
          ),
          projectRepository: projectRepository,
          printer: printer,
        ),
        printer: printer,
      );
    });

    test('list prints human-readable approval lines', () async {
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

      final exitCode = await command.run(<String>['list']);

      expect(exitCode, 0);
      expect(pendingResearchActionService.listCalled, isTrue);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            '待处理审批',
            'research_request_1｜等待确认｜北境钟楼来历｜需要联网确认\n'
                'research_request_2｜待处理｜港口潮汐资料',
          ),
        ),
      );
    });

    test('show prints a detailed approval record', () async {
      pendingResearchActionService.loadResult = <String, Object?>{
        'request_id': 'research_request_9',
        'request_state': 'needs_user_info',
        'relative_path':
            '.novel_agent/information/research_requests/research_request_9.json',
        'research_request': <String, Object?>{'query': '北海航线资料'},
        'permission_decision': <String, Object?>{'reason': '请先补充年代范围'},
        'metadata': <String, Object?>{
          'latest_pending_research_action': <String, Object?>{
            'command': 'mark_needs_user_info',
          },
        },
      };

      final exitCode = await command.run(<String>[
        'show',
        '--request',
        'research_request_9',
      ]);

      expect(exitCode, 0);
      expect(pendingResearchActionService.loadCalled, isTrue);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            '审批详情',
            '审批类型：资料研究\n'
                '请求 ID：research_request_9\n'
                '状态：待补充信息（needs_user_info）\n'
                '请求：北海航线资料\n'
                '原因：请先补充年代范围\n'
                '最近动作：mark_needs_user_info\n'
                '记录路径：.novel_agent/information/research_requests/research_request_9.json',
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
      expect(printer.successes, contains('审批请求已确认。'));
      expect(printer.infos, contains('请求: research_request_approve_1'));
      expect(printer.infos, contains('状态: 待处理'));
    });

    test('approve reads piped note when note flag is omitted', () async {
      pendingResearchActionService.approveResult = <String, Object?>{
        'ok': true,
        'request_id': 'research_request_pipe_1',
        'request_state': 'pending_gateway_execution',
        'action_status': 'updated',
        'changed_paths': <Object?>[],
      };
      final pipePrinter = _RecordingTerminalPrinter();
      final pipeCommand = ApprovalCommand(
        pendingResearchActionService: pendingResearchActionService,
        projectContextLoader: CliProjectContextLoader(
          commandContext: CliCommandContext(
            settings: settingsRepository.appSettings,
            defaultProjectPath:
                settingsRepository.appSettings.defaultProjectPath,
          ),
          projectRepository: projectRepository,
          printer: pipePrinter,
        ),
        automationInputService: CliAutomationInputService(
          modeDetectionService: const CliModeDetectionService(
            stdinHasTerminal: _alwaysFalse,
            stdoutHasTerminal: _alwaysTrue,
          ),
          stdinHasTerminal: _alwaysFalse,
          stdinReader: () async => '  允许继续研究  \n',
        ),
        printer: pipePrinter,
      );

      final exitCode = await pipeCommand.run(<String>[
        'approve',
        '--request',
        'research_request_pipe_1',
      ]);

      expect(exitCode, 0);
      expect(pendingResearchActionService.approveCalls, hasLength(1));
      expect(
        pendingResearchActionService.approveCalls.single['note'],
        '允许继续研究',
      );
    });

    test('reject requires request id before calling action service', () async {
      final exitCode = await command.run(<String>['reject']);

      expect(exitCode, 2);
      expect(pendingResearchActionService.rejectCalls, isEmpty);
      expect(printer.errors, contains('请通过 --request 或 --id 指定审批请求。'));
    });

    test('policy show prints approval boundary summary', () async {
      final exitCode = await command.run(<String>['policy', 'show']);

      expect(exitCode, 0);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            'approval policy',
            '正式主入口：approval list/show/approve/reject\n'
                '研究审批的数据来源：项目待办研究动作服务\n'
                '工具权限审批真相：保留在 adapters/runtime 的审批记录服务中，后续可再接独立命令族。\n'
                'workflow pending-research：仅作为兼容薄转发入口。',
          ),
        ),
      );
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
  JsonMap loadResult = const <String, Object?>{};
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
  bool loadCalled = false;
  final List<Map<String, String>> approveCalls = <Map<String, String>>[];
  final List<Map<String, String>> rejectCalls = <Map<String, String>>[];

  @override
  Future<JsonMap> load(
    ProjectDescriptor project, {
    required String requestId,
  }) async {
    loadCalled = true;
    return loadResult;
  }

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

bool _alwaysFalse() => false;

bool _alwaysTrue() => true;
