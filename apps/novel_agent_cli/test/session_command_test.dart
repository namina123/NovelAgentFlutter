import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/session/session_command.dart';
import 'package:novel_agent_cli/commands/session/session_interactive_shell.dart';
import 'package:novel_agent_cli/commands/shared/cli_automation_input_service.dart';
import 'package:novel_agent_cli/commands/shared/cli_exit_codes.dart';
import 'package:novel_agent_cli/commands/shared/cli_mode_detection_service.dart';
import 'package:novel_agent_cli/commands/shared/cli_command_context.dart';
import 'package:novel_agent_cli/commands/shared/cli_project_context_loader.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SessionCommand', () {
    test('help prints the formal non-interactive session commands', () async {
      final bundle = await _buildCommand();

      final exitCode = await bundle.command.run(<String>[
        'help',
      ], defaultProjectPath: bundle.project.rootPath);

      expect(exitCode, 0);
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'session help' &&
                block.content.contains('session list [--project 路径]') &&
                block.content.contains('session show --id session_1') &&
                block.content.contains('session resume [--id session_1]') &&
                block.content.contains('session start [--id session_1]') &&
                block.content.contains('session send --id session_1'),
          ),
        ),
      );
    });

    test(
      'list renders current sessions through the shared shell service',
      () async {
        final bundle = await _buildCommand();

        final exitCode = await bundle.command.run(<String>[
          'list',
        ], defaultProjectPath: bundle.project.rootPath);

        expect(exitCode, 0);
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session list' &&
                  block.content.contains('session_1') &&
                  block.content.contains('会话一'),
            ),
          ),
        );
      },
    );

    test(
      'resume reopens the current session and prints the shared prompt context',
      () async {
        final bundle = await _buildCommand();

        final exitCode = await bundle.command.run(<String>[
          'resume',
        ], defaultProjectPath: bundle.project.rootPath);

        expect(exitCode, 0);
        expect(bundle.printer.successes, contains('创作已启动'));
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session resume' &&
                  block.content.contains('恢复来源：active_session') &&
                  block.content.contains('会话 ID：session_1') &&
                  block.content.contains('第一轮正文'),
            ),
          ),
        );
      },
    );

    test(
      'start enters the interactive shell and reuses the shared send chain',
      () async {
        final lines = <String>[
          '/help',
          '/model',
          '/group',
          '/approval',
          '/stats',
          '/compact',
          '继续推进剧情。',
          '/exit',
        ];
        final bundle = await _buildCommand(
          interactiveShellBuilder: (shellService, printer) =>
              SessionInteractiveShell(
                sessionShellService: shellService,
                printer: printer,
                readLine: () => lines.isEmpty ? null : lines.removeAt(0),
                writePrompt: (_) {},
              ),
        );

        final exitCode = await bundle.command.run(<String>[
          'start',
        ], defaultProjectPath: bundle.project.rootPath);

        expect(exitCode, 0);
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session start' &&
                  block.content.contains('项目类型：novel') &&
                  block.content.contains('会话 ID：session_1'),
            ),
          ),
        );
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session interactive help' &&
                  block.content.contains('/help') &&
                  block.content.contains('/exit'),
            ),
          ),
        );
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session command' &&
                  block.content.contains('当前模式'),
            ),
          ),
        );
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session command' &&
                  block.content.contains('项目类型：novel'),
            ),
          ),
        );
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session command' &&
                  block.content.contains('approval list/show/approve/reject'),
            ),
          ),
        );
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session command' &&
                  block.content.contains('压力'),
            ),
          ),
        );
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session command' &&
                  block.content.contains('会话上下文已压缩'),
            ),
          ),
        );
        expect(
          bundle.printer.blocks,
          contains(
            predicate<_PrintedBlock>(
              (block) =>
                  block.title == 'session send' &&
                  block.content.contains('继续推进剧情。'),
            ),
          ),
        );
      },
    );

    test('send reads piped input when message flag is omitted', () async {
      final bundle = await _buildCommand(
        automationInputService: CliAutomationInputService(
          modeDetectionService: const CliModeDetectionService(
            stdinHasTerminal: _alwaysFalse,
            stdoutHasTerminal: _alwaysTrue,
          ),
          stdinHasTerminal: _alwaysFalse,
          stdinReader: () async => '  继续推进剧情。  \n',
        ),
      );

      final exitCode = await bundle.command.run(<String>[
        'send',
        '--id',
        'session_1',
      ], defaultProjectPath: bundle.project.rootPath);

      expect(exitCode, 0);
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'session send' &&
                block.content.contains('用户输入：继续推进剧情。'),
          ),
        ),
      );
    });

    test('start fails fast when the shell has no terminal', () async {
      final bundle = await _buildCommand(
        automationInputService: CliAutomationInputService(
          modeDetectionService: const CliModeDetectionService(
            stdinHasTerminal: _alwaysFalse,
            stdoutHasTerminal: _alwaysFalse,
          ),
          stdinHasTerminal: _alwaysFalse,
          stdinReader: () async => '',
        ),
      );

      final exitCode = await bundle.command.run(<String>[
        'start',
      ], defaultProjectPath: bundle.project.rootPath);

      expect(exitCode, CliExitCodes.unavailable);
      expect(
        bundle.printer.errors,
        contains('session start 需要交互终端；请改用 session send 或 session resume。'),
      );
    });
  });
}

Future<
  ({
    SessionCommand command,
    _RecordingTerminalPrinter printer,
    ProjectDescriptor project,
  })
>
_buildCommand({
  SessionInteractiveShell Function(
    ProjectSessionShellService shellService,
    _RecordingTerminalPrinter printer,
  )?
  interactiveShellBuilder,
  CliAutomationInputService? automationInputService,
}) async {
  final workspacePort = LocalProjectWorkspacePort();
  final hostPort = ProjectWorkspaceToolHostAdapter(
    workspacePort: workspacePort,
    fileMutationAdapter: LocalProjectFileMutationAdapter(),
  );
  final sessionWorkspaceService = ProjectSessionWorkspaceService(
    hostPort: hostPort,
  );
  final shellService = ProjectSessionShellService(
    sessionWorkspaceService: sessionWorkspaceService,
  );
  final tempDirectory = Directory.systemTemp.createTempSync(
    'novel_agent_cli_session_command_',
  );
  final project = ProjectDescriptor(
    id: 'project_1',
    name: '测试项目',
    rootPath: tempDirectory.path,
    projectType: 'novel',
  );
  await sessionWorkspaceService.saveSessions(
    project,
    sessionRecords: const <JsonMap>[
      <String, Object?>{
        'id': 'session_1',
        'title': '会话一',
        'mode': SessionRecordConstants.modeContinueWriting,
        'workflow_stage': 'stopped',
        'public_status': '已停止',
        'needs_goal_selection': false,
        'is_creative': true,
        'working_context_messages': <Object?>[
          <String, Object?>{'role': 'user', 'content': '第一轮正文'},
        ],
        'created_at': '2026-06-14T00:00:00.000Z',
        'updated_at': '2026-06-14T00:00:01.000Z',
      },
    ],
    activeSessionId: 'session_1',
  );
  final printer = _RecordingTerminalPrinter();
  final interactiveShell = interactiveShellBuilder?.call(shellService, printer);
  final command = SessionCommand(
    sessionShellService: shellService,
    projectContextLoader: CliProjectContextLoader(
      commandContext: CliCommandContext(
        settings: const AppSettings(
          defaultProviderId: '',
          defaultAgentId: '',
          defaultModelId: '',
          defaultProjectPath: '',
          autoSaveDrafts: false,
          providers: <ProviderEndpointSettings>[],
        ),
        defaultProjectPath: tempDirectory.path,
      ),
      projectRepository: _FakeProjectRepository(project),
      printer: printer,
    ),
    automationInputService:
        automationInputService ??
        CliAutomationInputService(
          modeDetectionService: const CliModeDetectionService(
            stdinHasTerminal: _alwaysTrue,
            stdoutHasTerminal: _alwaysTrue,
          ),
          stdinHasTerminal: _alwaysTrue,
          stdinReader: () async => '',
        ),
    interactiveShell: interactiveShell,
    printer: printer,
  );
  return (command: command, printer: printer, project: project);
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this.project);

  final ProjectDescriptor project;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async => project;
}

bool _alwaysFalse() => false;

bool _alwaysTrue() => true;

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
