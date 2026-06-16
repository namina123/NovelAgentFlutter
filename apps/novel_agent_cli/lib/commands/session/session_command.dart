import 'dart:convert';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../shared/cli_arguments.dart';
import '../shared/cli_command_context.dart';
import '../shared/cli_exit_codes.dart';
import '../shared/cli_help_contract.dart';
import '../shared/cli_automation_input_service.dart';
import '../shared/cli_mode_detection_service.dart';
import '../shared/cli_project_context_loader.dart';
import 'session_interactive_shell.dart';
import '../../output/terminal_printer.dart';

class SessionCommand {
  SessionCommand({
    required ProjectSessionShellService sessionShellService,
    required CliProjectContextLoader projectContextLoader,
    required TerminalPrinter printer,
    CliAutomationInputService? automationInputService,
    SessionInteractiveShell? interactiveShell,
  }) : _sessionShellService = sessionShellService,
       _projectContextLoader = projectContextLoader,
       _automationInputService =
           automationInputService ?? const CliAutomationInputService(),
       _interactiveShell =
           interactiveShell ??
           SessionInteractiveShell(
             sessionShellService: sessionShellService,
             printer: printer,
           ),
       _printer = printer;

  final ProjectSessionShellService _sessionShellService;
  final CliProjectContextLoader _projectContextLoader;
  final CliAutomationInputService _automationInputService;
  final SessionInteractiveShell _interactiveShell;
  final TerminalPrinter _printer;

  Future<int> run(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    // 中文注释: session 命令现在只做壳层分发，所有会话事实都交给共享 shell service 处理。
    final action = args.isEmpty ? 'help' : args.first;
    final rest = args.isEmpty
        ? const <String>[]
        : args.skip(1).toList(growable: false);
    switch (action) {
      case 'list':
        return _runList(rest, defaultProjectPath: defaultProjectPath);
      case 'load':
      case 'show':
        return _runLoad(
          rest,
          action: action,
          defaultProjectPath: defaultProjectPath,
        );
      case 'resume':
        return _runResume(rest, defaultProjectPath: defaultProjectPath);
      case 'start':
        return _runStart(rest, defaultProjectPath: defaultProjectPath);
      case 'send':
        return _runSend(rest, defaultProjectPath: defaultProjectPath);
      case 'stats':
        return _runStats(rest, defaultProjectPath: defaultProjectPath);
      case 'compact':
        return _runCompact(rest, defaultProjectPath: defaultProjectPath);
      case 'stop':
        return _runStop(rest, defaultProjectPath: defaultProjectPath);
      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        return 0;
      default:
        _printer.error('未知 session 子命令: $action');
        _printHelp();
        return CliExitCodes.invalidInput;
    }
  }

  Future<int> _runList(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final context = await _loadProjectContext(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (context == null) {
      return 2;
    }
    final result = await _sessionShellService.listSessions(
      context.project,
      limit: _intOption(args, '--limit', 20),
    );
    return _printSessionList(result);
  }

  Future<int> _runLoad(
    List<String> args, {
    required String action,
    required String defaultProjectPath,
  }) async {
    final context = await _loadProjectContext(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (context == null) {
      return 2;
    }
    final sessionId = _sessionId(args);
    if (sessionId == null) {
      return 2;
    }
    final result = await _sessionShellService.loadSession(
      context.project,
      sessionId,
    );
    return _printSessionDetail(result, title: 'session $action');
  }

  Future<int> _runSend(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final context = await _loadProjectContext(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (context == null) {
      return 2;
    }
    final sessionId = _sessionId(args);
    if (sessionId == null) {
      return 2;
    }
    final message = await _message(args);
    if (message == null) {
      return 2;
    }
    final result = await _sessionShellService.sendSession(
      context.project,
      sessionId,
      message,
    );
    return _printSessionSend(result);
  }

  Future<int> _runResume(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final context = await _loadProjectContext(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (context == null) {
      return 2;
    }
    final result = await _sessionShellService.resumeSession(
      context.project,
      sessionId: _optionalSessionId(args) ?? '',
    );
    return _printSessionResume(result);
  }

  Future<int> _runStart(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final mode = _automationInputService.resolveMode(args);
    if (!_automationInputService.hasInteractiveTerminal ||
        mode != CliExecutionMode.interactive) {
      _printer.error('session start 需要交互终端；请改用 session send 或 session resume。');
      return CliExitCodes.unavailable;
    }
    final context = await _loadProjectContext(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (context == null) {
      return 2;
    }
    return _interactiveShell.start(
      context.project,
      sessionId: _optionalSessionId(args) ?? '',
    );
  }

  Future<int> _runStats(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final context = await _loadProjectContext(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (context == null) {
      return 2;
    }
    final sessionId = _sessionId(args);
    if (sessionId == null) {
      return 2;
    }
    final result = await _sessionShellService.statsSession(
      context.project,
      sessionId,
    );
    return _printSessionStats(result);
  }

  Future<int> _runCompact(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final context = await _loadProjectContext(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (context == null) {
      return 2;
    }
    final sessionId = _sessionId(args);
    if (sessionId == null) {
      return 2;
    }
    final result = await _sessionShellService.compactSession(
      context.project,
      sessionId,
    );
    return _printSessionCompact(result);
  }

  Future<int> _runStop(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final context = await _loadProjectContext(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (context == null) {
      return 2;
    }
    final sessionId = _sessionId(args);
    if (sessionId == null) {
      return 2;
    }
    final result = await _sessionShellService.stopSession(
      context.project,
      sessionId,
    );
    return _printSessionDetail(result, title: 'session stop');
  }

  Future<CliProjectContext?> _loadProjectContext(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    // 中文注释: session 命令复用 shared project loader，避免自己再读 settings 和 project repository。
    return _projectContextLoader.load(
      args,
      defaultProjectPath: defaultProjectPath,
    );
  }

  String? _sessionId(List<String> args) {
    // 中文注释: session 标识统一走 --id / --session，避免命令层自行发明一套新参数名。
    final id = _optionValue(args, '--id') ?? _optionValue(args, '--session');
    if ((id ?? '').trim().isEmpty) {
      _printer.error('请通过 --id 或 --session 指定会话。');
      return null;
    }
    return id!.trim();
  }

  String? _optionalSessionId(List<String> args) {
    // 中文注释: resume 允许不显式指定会话，必要时复用当前活跃会话或最新会话。
    final id = _optionValue(args, '--id') ?? _optionValue(args, '--session');
    final cleaned = (id ?? '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<String?> _message(List<String> args) async {
    // 中文注释: send 命令需要明确的用户输入内容，避免把空消息写回正式会话记录。
    final message = await _automationInputService.resolveTextInput(
      args,
      optionNames: const <String>['--message', '--content'],
    );
    if ((message ?? '').trim().isEmpty) {
      _printer.error('请通过 --message 指定本轮输入内容，或通过管道传入内容。');
      return null;
    }
    return message!.trim();
  }

  int _intOption(List<String> args, String name, int fallback) {
    // 中文注释: 简单数值参数只做最薄的一层解析，保持 session 命令不依赖额外 parser。
    final value = _optionValue(args, name);
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    return int.tryParse(value.trim()) ?? fallback;
  }

  String? _optionValue(List<String> args, String name) {
    // 中文注释: session 命令只读取固定几个 flag，避免再长成一套私有参数 parser。
    return CliArguments(args).value(name);
  }

  int _printSessionList(JsonMap result) {
    // 中文注释: 列表输出保持紧凑可扫读，方便 CLI 在终端和脚本里都能快速浏览。
    if (!ValueReaders.boolValue(result['ok'], true)) {
      _printer.error(ValueReaders.stringValue(result['error'], '读取会话列表失败。'));
      return 1;
    }
    final sessions = ValueReaders.objectList(
      result['sessions'],
    ).map(ValueReaders.mapValue).toList(growable: false);
    if (sessions.isEmpty) {
      _printer.info('当前没有会话记录。');
      return 0;
    }
    final lines = <String>[];
    for (final session in sessions) {
      final marker =
          ValueReaders.stringValue(session['id']) ==
              ValueReaders.stringValue(result['current_session_id'])
          ? '*'
          : '-';
      lines.add(
        '$marker ${ValueReaders.stringValue(session['id'])} | ${ValueReaders.stringValue(session['title'], '未命名会话')} | ${ValueReaders.stringValue(session['public_status'], '准备中')} | ${ValueReaders.stringValue(session['public_summary'])}',
      );
    }
    _printer.block('session list', lines.join('\n'));
    return 0;
  }

  int _printSessionDetail(JsonMap result, {required String title}) {
    // 中文注释: 详情输出复用同一份会话 payload，避免 load/stop 两条命令各自拼不同展示模板。
    if (!ValueReaders.boolValue(result['ok'], true)) {
      _printer.error(ValueReaders.stringValue(result['error'], '读取会话失败。'));
      return 1;
    }
    _printer.success(
      ValueReaders.stringValue(result['public_status'], '会话已更新。'),
    );
    _printer.info(ValueReaders.stringValue(result['public_summary']));
    _printer.block(
      title,
      _prettyJson(ValueReaders.mapValue(result['session_record'])),
    );
    return 0;
  }

  int _printSessionSend(JsonMap result) {
    // 中文注释: send 输出强调送入模型前的正式合同，而不是把 shell 自己包装成第二个生成器。
    if (!ValueReaders.boolValue(result['ok'], true)) {
      _printer.error(ValueReaders.stringValue(result['error'], '发送会话失败。'));
      return 1;
    }
    _printer.success(
      ValueReaders.stringValue(result['public_status'], '会话已更新。'),
    );
    _printer.info(ValueReaders.stringValue(result['public_summary']));
    _printer.block(
      'session send',
      [
        '用户输入：${ValueReaders.stringValue(result["user_message"])}',
        '上下文预览：',
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            result['session_prompt_context'],
          )['context_markdown'],
        ),
      ].join('\n'),
    );
    return 0;
  }

  int _printSessionStats(JsonMap result) {
    // 中文注释: stats 输出以压力快照为主，方便用户判断是否需要 compact 或 stop。
    if (!ValueReaders.boolValue(result['ok'], true)) {
      _printer.error(ValueReaders.stringValue(result['error'], '读取会话统计失败。'));
      return 1;
    }
    _printer.info(ValueReaders.stringValue(result['public_summary']));
    _printer.block(
      'session stats',
      _prettyJson(ValueReaders.mapValue(result['pressure_snapshot'])),
    );
    return 0;
  }

  int _printSessionResume(JsonMap result) {
    // 中文注释: resume 输出要同时给出恢复后的会话事实和可继续输入的上下文预览。
    if (!ValueReaders.boolValue(result['ok'], true)) {
      _printer.error(ValueReaders.stringValue(result['error'], '恢复会话失败。'));
      return 1;
    }
    final sessionRecord = ValueReaders.mapValue(result['session_record']);
    _printer.success(
      ValueReaders.stringValue(result['public_status'], '会话已恢复。'),
    );
    _printer.info(ValueReaders.stringValue(result['public_summary']));
    _printer.block(
      'session resume',
      [
        '恢复来源：${ValueReaders.stringValue(result["resume_source"], 'active_session')}',
        '会话 ID：${ValueReaders.stringValue(result["session_id"])}',
        '当前阶段：${ValueReaders.stringValue(sessionRecord["workflow_stage"])}',
        '上下文预览：',
        ValueReaders.stringValue(result['context_markdown']),
      ].join('\n'),
    );
    return 0;
  }

  int _printSessionCompact(JsonMap result) {
    // 中文注释: compact 输出只报告正式压缩决策和压缩后状态，不扩散成另一套临时摘要系统。
    if (!ValueReaders.boolValue(result['ok'], true)) {
      _printer.error(ValueReaders.stringValue(result['error'], '压缩会话失败。'));
      return 1;
    }
    _printer.success('会话压缩已完成。');
    _printer.block(
      'session compact',
      _prettyJson(ValueReaders.mapValue(result['compaction_decision'])),
    );
    return 0;
  }

  String _prettyJson(JsonMap value) {
    // 中文注释: 会话详情的结构化输出统一用缩进 JSON，便于脚本和人工排查共用。
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  void _printHelp() {
    // 中文注释: session 帮助只展示已经正式接通的非交互子命令。
    CliHelpContract.printHelpBlock(_printer, 'session help', [
      'session list [--project 路径] [--limit 20]',
      'session load --id session_1 [--project 路径]',
      'session show --id session_1 [--project 路径]',
      'session resume [--id session_1] [--project 路径]',
      'session start [--id session_1] [--project 路径]',
      'session send --id session_1 --message "继续" [--project 路径]',
      'session stats --id session_1 [--project 路径]',
      'session compact --id session_1 [--project 路径]',
      'session stop --id session_1 [--project 路径]',
    ]);
  }
}
