import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

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
  }) : _sessionShellService = sessionShellService,
       _printer = printer,
       _guideProfileService =
           guideProfileService ?? const SessionGuideProfileService(),
       _readLine = readLine ?? _defaultReadLine,
       _writePrompt = writePrompt ?? _defaultWritePrompt;

  final ProjectSessionShellService _sessionShellService;
  final TerminalPrinter _printer;
  final SessionGuideProfileService _guideProfileService;
  final SessionLineReader _readLine;
  final SessionPromptWriter _writePrompt;

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
        project,
        input,
        currentSessionId: currentSessionId,
        sessionRecord: sessionRecord,
        updateSessionRecord: (updatedRecord, updatedSessionId) {
          sessionRecord = updatedRecord;
          if (updatedSessionId.trim().isNotEmpty) {
            currentSessionId = updatedSessionId.trim();
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
    ProjectDescriptor project,
    String input, {
    required String currentSessionId,
    required JsonMap sessionRecord,
    required void Function(JsonMap updatedRecord, String updatedSessionId)
    updateSessionRecord,
  }) async {
    // 中文注释: slash commands 只负责壳层动作与状态投影，不承载新的审批或调度规则。
    if (!input.startsWith('/')) {
      return _SlashCommandOutcome.passThrough;
    }
    final command = input.substring(1).trim();
    if (command.isEmpty) {
      _printer.error(
        '请输入 /help、/model、/group、/approval、/compact、/stats 或 /exit。',
      );
      return _SlashCommandOutcome.handled;
    }
    switch (command.split(RegExp(r'\s+')).first) {
      case 'help':
        _printHelp(_buildGuideProfile(project, sessionRecord));
        return _SlashCommandOutcome.handled;
      case 'model':
        _printModelState(project, sessionRecord);
        return _SlashCommandOutcome.handled;
      case 'group':
        _printGroupState(project, sessionRecord);
        return _SlashCommandOutcome.handled;
      case 'approval':
        _printApprovalState(project, sessionRecord);
        return _SlashCommandOutcome.handled;
      case 'compact':
        final compactResult = await _sessionShellService.compactSession(
          project,
          currentSessionId,
        );
        if (!ValueReaders.boolValue(compactResult['ok'], true)) {
          _printer.error(
            ValueReaders.stringValue(compactResult['error'], '压缩会话失败。'),
          );
          return _SlashCommandOutcome.handled;
        }
        updateSessionRecord(
          ValueReaders.mapValue(compactResult['session_record']),
          ValueReaders.stringValue(
            compactResult['session_id'],
            currentSessionId,
          ),
        );
        _printCompactResult(compactResult);
        return _SlashCommandOutcome.handled;
      case 'stats':
        final statsResult = await _sessionShellService.statsSession(
          project,
          currentSessionId,
        );
        if (!ValueReaders.boolValue(statsResult['ok'], true)) {
          _printer.error(
            ValueReaders.stringValue(statsResult['error'], '读取会话统计失败。'),
          );
          return _SlashCommandOutcome.handled;
        }
        _printStatsResult(statsResult);
        return _SlashCommandOutcome.handled;
      case 'exit':
        _printer.info('结束交互会话。');
        return _SlashCommandOutcome.exit;
      default:
        _printer.error('未知 slash command: /$command');
        _printHelp(_buildGuideProfile(project, sessionRecord));
        return _SlashCommandOutcome.handled;
    }
  }

  void _printHelp(SessionGuideProfile guideProfile) {
    // 中文注释: 帮助只展示当前 REPL 真正接通的控制面，避免把未来 session 能力伪装成现在可用。
    CliHelpContract.printHelpBlock(
      _printer,
      'session interactive help',
      [
        '/help',
        '/model',
        '/group',
        '/approval',
        '/compact',
        '/stats',
        '/exit',
        if (guideProfile.primaryActions.isNotEmpty) '',
        for (final action in guideProfile.primaryActions)
          '${action.title} - ${action.description}',
      ].where((line) => line.trim().isNotEmpty).toList(growable: false),
    );
  }

  void _printModelState(ProjectDescriptor project, JsonMap sessionRecord) {
    // 中文注释: model slash command 先投影当前会话模式与引导文案，暂不在 REPL 里偷偷改 provider。
    final guideProfile = _buildGuideProfile(project, sessionRecord);
    _printer.block(
      'session model',
      [
        '当前模式：${ValueReaders.stringValue(sessionRecord['mode'])}',
        '会话标题：${ValueReaders.stringValue(sessionRecord['title'], '未命名会话')}',
        'composerHint：${guideProfile.composerHint}',
      ].join('\n'),
    );
  }

  void _printGroupState(ProjectDescriptor project, JsonMap sessionRecord) {
    // 中文注释: group slash command 只展示当前项目类型和相关引导，不把智能体组切换做成第二套业务主链。
    final guideProfile = _buildGuideProfile(project, sessionRecord);
    _printer.block(
      'session group',
      [
        '项目类型：${project.projectType}',
        '引导标题：${guideProfile.title}',
        '引导说明：${guideProfile.description}',
      ].join('\n'),
    );
  }

  void _printApprovalState(ProjectDescriptor project, JsonMap sessionRecord) {
    // 中文注释: approval slash command 先作为壳层信息入口，正式审批真相仍在后续 approval session 接通。
    final guideProfile = _buildGuideProfile(project, sessionRecord);
    _printer.block(
      'session approval',
      [
        '当前会话的审批入口请使用 approval list/show/approve/reject。',
        '会话状态：${ValueReaders.stringValue(sessionRecord['public_status'], '准备中')}',
        '状态提示：${guideProfile.statusHint.isEmpty ? '暂无补充提示。' : guideProfile.statusHint}',
      ].join('\n'),
    );
  }

  void _printCompactResult(JsonMap result) {
    // 中文注释: compact 的 REPL 输出沿用共享压缩合同，不额外生成一套本地摘要。
    _printer.success('会话压缩已完成。');
    _printer.block(
      'session compact',
      _prettyJson(ValueReaders.mapValue(result['compaction_decision'])),
    );
  }

  void _printStatsResult(JsonMap result) {
    // 中文注释: stats 的 REPL 输出与非交互命令保持同一份压力快照合同。
    _printer.info(ValueReaders.stringValue(result['public_summary']));
    _printer.block(
      'session stats',
      _prettyJson(ValueReaders.mapValue(result['pressure_snapshot'])),
    );
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
