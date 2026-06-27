import 'package:novel_agent_core/novel_agent_core.dart';

/// CLI 专属的只读"视图"指令（/model /group /approval），由 session 交互 shell 注册。
///
/// 它们只把当前会话状态投影成文本，不调后端副作用；输出沿用旧 REPL 的措辞，
/// 避免老用户升级后丢失这些查看入口。

SessionGuideProfile _resolveGuideProfile(
  SessionGuideProfileService service,
  ConversationCommandContext ctx,
) {
  // 中文注释: 视图命令复用与旧 REPL 同一份引导 profile 解析，保证迁移后输出措辞一致。
  return service.resolve(
    projectType: ctx.project.projectType,
    needsGoalSelection: ValueReaders.boolValue(
      ctx.sessionRecord['needs_goal_selection'],
      false,
    ),
    isRunning:
        ValueReaders.stringValue(ctx.sessionRecord['workflow_stage']) !=
        'stopped',
  );
}

/// `/model` —— 查看当前会话模式与引导文案。
class ModelViewConversationCommand extends ConversationCommand {
  const ModelViewConversationCommand({
    required SessionGuideProfileService guideProfileService,
  }) : _guideProfileService = guideProfileService,
       super(name: 'model', summary: '查看当前会话模式与引导');

  final SessionGuideProfileService _guideProfileService;

  @override
  Future<ConversationCommandResult> execute(ConversationCommandContext ctx) async {
    final profile = _resolveGuideProfile(_guideProfileService, ctx);
    return ConversationCommandResult(
      kind: ConversationCommandOutcomeKind.handled,
      message: <String>[
        'session model',
        '当前模式：${ValueReaders.stringValue(ctx.sessionRecord['mode'])}',
        '会话标题：${ValueReaders.stringValue(ctx.sessionRecord['title'], '未命名会话')}',
        'composerHint：${profile.composerHint}',
      ].join('\n'),
    );
  }
}

/// `/group` —— 查看当前项目类型与引导说明。
class GroupViewConversationCommand extends ConversationCommand {
  const GroupViewConversationCommand({
    required SessionGuideProfileService guideProfileService,
  }) : _guideProfileService = guideProfileService,
       super(name: 'group', summary: '查看当前项目类型与引导');

  final SessionGuideProfileService _guideProfileService;

  @override
  Future<ConversationCommandResult> execute(ConversationCommandContext ctx) async {
    final profile = _resolveGuideProfile(_guideProfileService, ctx);
    return ConversationCommandResult(
      kind: ConversationCommandOutcomeKind.handled,
      message: <String>[
        'session group',
        '项目类型：${ctx.project.projectType}',
        '引导标题：${profile.title}',
        '引导说明：${profile.description}',
      ].join('\n'),
    );
  }
}

/// `/approval` —— 查看审批入口提示。
class ApprovalViewConversationCommand extends ConversationCommand {
  const ApprovalViewConversationCommand({
    required SessionGuideProfileService guideProfileService,
  }) : _guideProfileService = guideProfileService,
       super(name: 'approval', summary: '查看会话审批入口');

  final SessionGuideProfileService _guideProfileService;

  @override
  Future<ConversationCommandResult> execute(ConversationCommandContext ctx) async {
    final profile = _resolveGuideProfile(_guideProfileService, ctx);
    return ConversationCommandResult(
      kind: ConversationCommandOutcomeKind.handled,
      message: <String>[
        'session approval',
        '当前会话的审批入口请使用 approval list/show/approve/reject。',
        '会话状态：${ValueReaders.stringValue(ctx.sessionRecord['public_status'], '准备中')}',
        '状态提示：${profile.statusHint.isEmpty ? '暂无补充提示。' : profile.statusHint}',
      ].join('\n'),
    );
  }
}
