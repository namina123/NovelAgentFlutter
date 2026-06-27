import '../common/json_types.dart';

/// 斜杠指令执行后的处置方式，宿主（CLI/GUI）据此决定如何渲染与是否继续。
enum ConversationCommandOutcomeKind {
  /// 指令已处理，结果应展示给用户；不应作为普通消息发送给模型。
  handled,

  /// 输入不是指令（或指令主动放行），应作为普通消息走正常发送链。
  passThrough,

  /// 指令请求结束当前交互会话（CLI 退出 REPL；GUI 通常不使用）。
  exit,

  /// 输入以 `/` 开头但指令未知或为空，已附带可用指令提示。
  unknown,
}

/// 单条斜杠指令的执行结果。
///
/// 命令本身只产出「展示文案 + 可选的新会话记录 + 可选的结构化负载」，
/// 是否写回会话状态、是否持久化由宿主依据 [persist] / [updatedSessionRecord] 决定，
/// 这样 CLI（裸 sessionRecord）与 GUI（ConversationSessionState）能各自写回自己的状态载体。
class ConversationCommandResult {
  const ConversationCommandResult({
    required this.kind,
    this.message = '',
    this.updatedSessionRecord,
    this.persist = false,
    this.payload,
  });

  final ConversationCommandOutcomeKind kind;

  /// 给用户看的纯文本结果（CLI 直接打印，GUI 作为系统消息插入对话流）。
  final String message;

  /// 指令产生的新会话记录（如切模式 / 压缩 / 清空后）。为 null 表示不改动会话状态。
  final JsonMap? updatedSessionRecord;

  /// 是否需要把 [updatedSessionRecord] 持久化到磁盘。
  final bool persist;

  /// 结构化负载（如压力快照、压缩决策），供宿主做更丰富的渲染或诊断。
  final JsonMap? payload;

  bool get shouldRender => message.trim().isNotEmpty;
}
