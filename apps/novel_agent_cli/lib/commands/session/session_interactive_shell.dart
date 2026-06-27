import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'cli_session_view_commands.dart';
import '../shared/cli_help_contract.dart';
import '../../output/terminal_printer.dart';

typedef SessionLineReader = String? Function();
typedef SessionPromptWriter = void Function(String);

class SessionInteractiveShell {
  SessionInteractiveShell({
    required ProjectSessionShellService sessionShellService,
    required TerminalPrinter printer,
    SessionGuideProfileService? guideProfileService,
    SessionLineReader? readLine,
    SessionPromptWriter? writePrompt,
    ConversationCommandRegistry? registry,
  }) : _sessionShellService = sessionShellService,
       _printer = printer,
       _guideProfileService =
           guideProfileService ?? const SessionGuideProfileService(),
       _readLine = readLine ?? _defaultReadLine,
       _writePrompt = writePrompt ?? _defaultWritePrompt,
       _registry = registry;

  final ProjectSessionShellService _sessionShellService;
  final TerminalPrinter _printer;
  final SessionGuideProfileService _guideProfileService;
  final SessionLineReader _readLine;
  final SessionPromptWriter _writePrompt;
  final ConversationCommandRegistry? _registry;

  late final ConversationCommandRegistry registry = _buildRegistry();

  ConversationCommandRegistry _buildRegistry() {
    // 中文注释: registry 允许测试注入；默认注册 core 内置指令 + CLI 专属的退出/视图指令。
    final built = _registry ?? ConversationCommandRegistry();
    if (_registry != null) {
      return built;
    }
    registerBuiltinConversationCommands(built);
    built.register(const ExitConversationCommand());
    built.register(
      ModelViewConversationCommand(guideProfileService: _guideProfileService),
    );
    built.register(
      GroupViewConversationCommand(guideProfileService: _guideProfileService),
    );
    built.register(
      ApprovalViewConversationCommand(guideProfileService: _guideProfileService),
    );
    return built;
  }

  Future<int> start(ProjectDescriptor project, {String sessionId = ''}) async {
    // 中文注释: 交互会话只负责把用户输入串成一轮轮 session send，不在这里重建新的运行语义。
    final resumed = await _sessionShellService.resumeSession(
      project,
      sessionId: sessionId,
    );
    if (!ValueReaders.boolValue(resumed['ok'], true)) {
      _printer.error(ValueReaders.stringValue(resumed['error'], '启动会话失败。'));
      return 1;
    }
    var currentSessionId = ValueReaders.stringValue(resumed['session_id']);
    var sessionRecord = ValueReaders.mapValue(resumed['session_record']);
    _printIntro(project, resumed);
    // 中文注释: dispatcher 的 contextFactory 闭包捕获上面的 currentSessionId / sessionRecord，
    // 循环里更新这两个变量后，下一轮 dispatch 能读到最新会话状态。
    final dispatcher = ConversationCommandDispatcher(
      registry: registry,
      contextFactory: (rawArgs) => ConversationCommandContext(
        project: project,
        sessionRecord: sessionRecord,
        rawArgs: rawArgs,
        backend: ProjectSessionShellCommandBackend(
          shellService: _sessionShellService,
          project: project,
          sessionId: currentSessionId,
        ),
      ),
    );
    while (true) {
      _writePrompt('session> ');
      final raw = _readLine();
      if (raw == null) {
        break;
      }
      final input = raw.trim();
      if (input.isEmpty) {
        continue;
      }
      final handled = await _handleSlashCommand(
        dispatcher,
        input,
        onRecordUpdated: (updatedRecord) {
          if (updatedRecord.isNotEmpty) {
            sessionRecord = updatedRecord;
          }
          final newId = ValueReaders.stringValue(updatedRecord['id']).trim();
          if (newId.isNotEmpty) {
            currentSessionId = newId;
          }
        },
      );
      if (handled == _SlashCommandOutcome.exit) {
        break;
      }
      if (handled == _SlashCommandOutcome.handled) {
        continue;
      }
      final sendResult = await _sessionShellService.sendSession(
        project,
        currentSessionId,
        input,
      );
      if (!ValueReaders.boolValue(sendResult['ok'], true)) {
        _printer.error(
          ValueReaders.stringValue(sendResult['error'], '发送会话失败。'),
        );
        continue;
      }
      sessionRecord = ValueReaders.mapValue(sendResult['session_record']);
      currentSessionId = ValueReaders.stringValue(
        sendResult['session_id'],
        currentSessionId,
      );
      _printSendResult(sendResult);
    }
    return 0;
  }

  void _printIntro(ProjectDescriptor project, JsonMap resumed) {
    // 中文注释: 进入 REPL 先交代当前会话状态和操作边界，避免用户误以为 slash command 会改写业务真相。
    final sessionRecord = ValueReaders.mapValue(resumed['session_record']);
    final guideProfile = _buildGuideProfile(project, sessionRecord);
    _printer.success(
      ValueReaders.stringValue(resumed['public_status'], '会话已就绪。'),
    );
    _printer.info(ValueReaders.stringValue(resumed['public_summary']));
    _printer.block(
      'session start',
      [
        '项目类型：${project.projectType}',
        '会话 ID：${ValueReaders.stringValue(resumed['session_id'])}',
        '当前模式：${ValueReaders.stringValue(sessionRecord['mode'])}',
        '会话标题：${ValueReaders.stringValue(sessionRecord['title'], '未命名会话')}',
        '引导：${guideProfile.title}',
        guideProfile.description,
        guideProfile.composerHint,
        if (guideProfile.statusHint.trim().isNotEmpty) guideProfile.statusHint,
      ].where((line) => line.trim().isNotEmpty).join('\n'),
    );
    _printHelp(guideProfile);
  }

  Future<_SlashCommandOutcome> _handleSlashCommand(
    ConversationCommandDispatcher dispatcher,
    String input, {
    required void Function(JsonMap updatedRecord) onRecordUpdated,
  }) async {
    // 中文注释: slash command 统一走 core dispatcher，壳层只负责把结果渲染成终端输出并回写会话状态。
    final result = await dispatcher.dispatch(input);
    switch (result.kind) {
      case ConversationCommandOutcomeKind.exit:
        if (result.shouldRender) {
          _printer.info(result.message);
        }
        return _SlashCommandOutcome.exit;
      case ConversationCommandOutcomeKind.passThrough:
        return _SlashCommandOutcome.passThrough;
      case ConversationCommandOutcomeKind.handled:
      case ConversationCommandOutcomeKind.unknown:
        if (result.shouldRender) {
          _printer.block('session command', result.message);
        }
        if (result.updatedSessionRecord != null) {
          onRecordUpdated(result.updatedSessionRecord!);
        }
        if (result.payload != null && result.payload!.isNotEmpty) {
          _printer.block('session command payload', _prettyJson(result.payload!));
        }
        return _SlashCommandOutcome.handled;
    }
  }

  void _printHelp(SessionGuideProfile guideProfile) {
    // 中文注释: 帮助只展示 registry 里真正注册的指令，外加当前会话的引导动作，避免把未来能力伪装成现在可用。
    final lines = <String>[];
    for (final command in registry.all()) {
      final tail = command.argHint.isEmpty ? '' : ' ${command.argHint}';
      lines.add('/${command.name}$tail — ${command.summary}');
    }
    if (guideProfile.primaryActions.isNotEmpty) {
      lines.add('');
      for (final action in guideProfile.primaryActions) {
        lines.add('${action.title} - ${action.description}');
      }
    }
    CliHelpContract.printHelpBlock(_printer, 'session interactive help', lines);
  }

  void _printSendResult(JsonMap result) {
    // 中文注释: REPL 的普通输入仍然走正式 session send 合同，并把可继续输入的上下文回显给用户。
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
  }

  SessionGuideProfile _buildGuideProfile(
    ProjectDescriptor project,
    JsonMap sessionRecord,
  ) {
    // 中文注释: 引导 profile 只依赖 project type 和当前 session 的 goal 需求，不引入新的会话决策逻辑。
    return _guideProfileService.resolve(
      projectType: project.projectType,
      needsGoalSelection: ValueReaders.boolValue(
        sessionRecord['needs_goal_selection'],
        false,
      ),
      isRunning:
          ValueReaders.stringValue(sessionRecord['workflow_stage']) !=
          'stopped',
    );
  }

  String _prettyJson(JsonMap value) {
    // 中文注释: 交互会话的结构化输出沿用同一份 JSON 缩进格式，便于和非交互模式对齐。
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  static String? _defaultReadLine() => stdin.readLineSync();

  static void _defaultWritePrompt(String value) {
    stdout.write(value);
  }
}

enum _SlashCommandOutcome { passThrough, handled, exit }
