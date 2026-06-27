import '../common/value_readers.dart';
import '../session/session_goal_prompt_builder_service.dart';
import '../session/session_record_constants.dart';
import 'conversation_command.dart';
import 'conversation_command_context.dart';
import 'conversation_command_registry.dart';
import 'conversation_command_result.dart';

/// `/help` —— 列出注册表里所有指令。
class HelpConversationCommand extends ConversationCommand {
  const HelpConversationCommand({required this.registry})
    : super(
        name: 'help',
        aliases: const <String>['?'],
        summary: '查看所有可用指令',
      );

  final ConversationCommandRegistry registry;

  @override
  Future<ConversationCommandResult> execute(ConversationCommandContext ctx) async {
    return ConversationCommandResult(
      kind: ConversationCommandOutcomeKind.handled,
      message: _helpText(),
    );
  }

  String _helpText() {
    final lines = <String>['可用指令：'];
    for (final command in registry.all()) {
      final usage = command.usage.isEmpty
          ? '/${command.name}${command.argHint.isEmpty ? '' : ' ${command.argHint}'}'
          : command.usage;
      lines.add('  $usage — ${command.summary}');
    }
    lines.add('指令以 / 开头；不以 / 开头的输入会作为普通消息发送给模型。');
    return lines.join('\n');
  }
}

/// `/goal` —— 双语义：无参=查看/列出写作模式；带参=匹配模式名则切模式，否则作为自由文本目标。
class GoalConversationCommand extends ConversationCommand {
  const GoalConversationCommand({
    SessionGoalPromptBuilderService? goalPromptBuilder,
  }) : _goalPromptBuilder =
           goalPromptBuilder ?? const SessionGoalPromptBuilderService(),
       super(
         name: 'goal',
         summary: '查看或设置本次会话目标（写作模式或自由目标）',
         usage: '/goal [模式名|目标文字]',
         argHint: '[模式|目标]',
       );

  final SessionGoalPromptBuilderService _goalPromptBuilder;

  static const List<String> _selectableModes = <String>[
    SessionRecordConstants.modeSmartOpening,
    SessionRecordConstants.modeChapterDraft,
    SessionRecordConstants.modeContinueWriting,
    SessionRecordConstants.modeSummarizeBook,
    SessionRecordConstants.modeImportArticle,
  ];

  /// 常见简称 → 模式常量，让 /goal 续写、/goal 单章 这类口语化输入也能命中。
  static const Map<String, String> _modeAliases = <String, String>{
    '开局': SessionRecordConstants.modeSmartOpening,
    '智能开局': SessionRecordConstants.modeSmartOpening,
    '单章': SessionRecordConstants.modeChapterDraft,
    '草稿': SessionRecordConstants.modeChapterDraft,
    '单章创作': SessionRecordConstants.modeChapterDraft,
    '续写': SessionRecordConstants.modeContinueWriting,
    '继续': SessionRecordConstants.modeContinueWriting,
    '继续创作': SessionRecordConstants.modeContinueWriting,
    '总结': SessionRecordConstants.modeSummarizeBook,
    '总结全书': SessionRecordConstants.modeSummarizeBook,
    '导入': SessionRecordConstants.modeImportArticle,
    '导入文章': SessionRecordConstants.modeImportArticle,
  };

  @override
  Future<ConversationCommandResult> execute(ConversationCommandContext ctx) async {
    final args = ctx.rawArgs.trim();
    final currentMode = ValueReaders.stringValue(ctx.sessionRecord['mode']);
    if (args.isEmpty) {
      return ConversationCommandResult(
        kind: ConversationCommandOutcomeKind.handled,
        message: _modeOverview(currentMode),
      );
    }
    final matchedMode = _matchMode(args);
    if (matchedMode != null) {
      final outcome = await ctx.backend.setMode(ctx.sessionRecord, matchedMode);
      return ConversationCommandResult(
        kind: ConversationCommandOutcomeKind.handled,
        message: '已切换到「${_goalPromptBuilder.label(matchedMode)}」模式。',
        updatedSessionRecord: outcome.updatedSessionRecord,
        persist: outcome.persist,
      );
    }
    final outcome = await ctx.backend.setGoalText(ctx.sessionRecord, args);
    return ConversationCommandResult(
      kind: ConversationCommandOutcomeKind.handled,
      message: '已记录本次会话目标：$args',
      updatedSessionRecord: outcome.updatedSessionRecord,
      persist: outcome.persist,
    );
  }

  String? _matchMode(String args) {
    // 中文注释: 先查常见简称（续写/单章/开局等），再匹配模式常量值与中文标签，任一命中即切模式。
    final alias = _modeAliases[args];
    if (alias != null) {
      return alias;
    }
    for (final mode in _selectableModes) {
      if (mode == args) {
        return mode;
      }
      if (_goalPromptBuilder.label(mode) == args) {
        return mode;
      }
    }
    return null;
  }

  String _modeOverview(String currentMode) {
    final lines = <String>[
      '当前模式：${_goalPromptBuilder.label(currentMode)}',
      '可选模式（/goal <模式> 切换）：',
    ];
    for (final mode in _selectableModes) {
      lines.add('  ${_goalPromptBuilder.label(mode)}（$mode）');
    }
    lines.add('或直接输入自由目标，例如：/goal 收束第三章伏笔');
    return lines.join('\n');
  }
}

/// `/stats` —— 读取上下文压力与会话统计（只读，不改会话）。
class StatsConversationCommand extends ConversationCommand {
  const StatsConversationCommand()
    : super(name: 'stats', summary: '查看上下文压力与会话统计');

  @override
  Future<ConversationCommandResult> execute(ConversationCommandContext ctx) async {
    final outcome = await ctx.backend.stats(ctx.sessionRecord);
    final detail = outcome.detail ?? const <String, Object?>{};
    final summary = ValueReaders.stringValue(detail['public_summary']);
    return ConversationCommandResult(
      kind: ConversationCommandOutcomeKind.handled,
      message: summary.isEmpty ? '已读取会话统计。' : summary,
      payload: detail.isEmpty ? null : detail,
    );
  }
}

/// `/compact` —— 压缩当前会话上下文。
class CompactConversationCommand extends ConversationCommand {
  const CompactConversationCommand()
    : super(name: 'compact', summary: '压缩当前会话上下文');

  @override
  Future<ConversationCommandResult> execute(ConversationCommandContext ctx) async {
    final outcome = await ctx.backend.compact(ctx.sessionRecord);
    final detail = outcome.detail ?? const <String, Object?>{};
    final decision = ValueReaders.mapValue(detail['compaction_decision']);
    return ConversationCommandResult(
      kind: ConversationCommandOutcomeKind.handled,
      message: '会话上下文已压缩。',
      updatedSessionRecord: outcome.updatedSessionRecord,
      persist: outcome.persist,
      payload: decision.isEmpty ? null : decision,
    );
  }
}

/// `/clear` —— 清空当前会话上下文（开始新会话）。
class ClearConversationCommand extends ConversationCommand {
  const ClearConversationCommand()
    : super(name: 'clear', summary: '清空当前会话上下文（开始新会话）');

  @override
  Future<ConversationCommandResult> execute(ConversationCommandContext ctx) async {
    final outcome = await ctx.backend.clearContext(ctx.sessionRecord);
    return ConversationCommandResult(
      kind: ConversationCommandOutcomeKind.handled,
      message: '已清空当前会话上下文。',
      updatedSessionRecord: outcome.updatedSessionRecord,
      persist: outcome.persist,
    );
  }
}

/// `/exit` —— 结束当前交互会话（CLI 退出 REPL）。
///
/// 作为 core 提供的命令类，但**不**进入 [registerBuiltinConversationCommands]，
/// 让宿主按需注册：CLI 注册（退出 REPL），GUI 第一期不暴露。
class ExitConversationCommand extends ConversationCommand {
  const ExitConversationCommand()
    : super(
        name: 'exit',
        aliases: const <String>['quit'],
        summary: '结束当前交互会话',
      );

  @override
  Future<ConversationCommandResult> execute(ConversationCommandContext ctx) async {
    final outcome = await ctx.backend.exitSession(ctx.sessionRecord);
    return ConversationCommandResult(
      kind: ConversationCommandOutcomeKind.exit,
      message: '结束交互会话。',
      updatedSessionRecord: outcome.updatedSessionRecord,
    );
  }
}

/// 把内置指令注册到 [registry]。
///
/// `help` 需要引用 registry 自身，故最后注册。宿主可在调用前后追加自定义指令。
void registerBuiltinConversationCommands(
  ConversationCommandRegistry registry, {
  SessionGoalPromptBuilderService? goalPromptBuilder,
}) {
  registry
    ..register(const StatsConversationCommand())
    ..register(const CompactConversationCommand())
    ..register(const ClearConversationCommand())
    ..register(GoalConversationCommand(goalPromptBuilder: goalPromptBuilder))
    ..register(HelpConversationCommand(registry: registry));
}

/// 斜杠指令补全项（供 GUI 输入框自动补全浮层使用）。
class ConversationCommandSuggestion {
  const ConversationCommandSuggestion({
    required this.name,
    required this.summary,
    this.argHint = '',
  });

  final String name;
  final String summary;
  final String argHint;
}

/// 内置指令的补全清单（与 [registerBuiltinConversationCommands] 注册的命令一致）。
///
/// GUI 输入框浮层用它做静态补全。命令名/简介与内置命令保持一致；
/// 若将来引入动态命令，宿主可改为从 registry 投影后传入浮层。
List<ConversationCommandSuggestion> builtinConversationCommandSuggestions() {
  return const <ConversationCommandSuggestion>[
    ConversationCommandSuggestion(name: 'help', summary: '查看所有可用指令'),
    ConversationCommandSuggestion(
      name: 'goal',
      summary: '查看或设置本次会话目标（写作模式或自由目标）',
      argHint: '[模式|目标]',
    ),
    ConversationCommandSuggestion(name: 'compact', summary: '压缩当前会话上下文'),
    ConversationCommandSuggestion(name: 'stats', summary: '查看上下文压力与会话统计'),
    ConversationCommandSuggestion(name: 'clear', summary: '清空当前会话上下文'),
  ];
}
