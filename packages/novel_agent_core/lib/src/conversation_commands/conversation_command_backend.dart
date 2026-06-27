import '../common/json_types.dart';

/// 单个指令后端动作的产出。
///
/// 后端实现负责真正改写会话记录并决定是否持久化；命令层只消费这个结果。
class ConversationCommandBackendOutcome {
  const ConversationCommandBackendOutcome({
    required this.updatedSessionRecord,
    this.persist = false,
    this.detail,
    this.exitSession = false,
  });

  /// 动作执行后的会话记录（即使没有实质改动，也应返回归一化后的记录）。
  final JsonMap updatedSessionRecord;

  /// 是否需要把更新后的记录落盘。
  final bool persist;

  /// 结构化细节（如压力快照、压缩决策），供命令组装展示文案或负载。
  final JsonMap? detail;

  /// 是否请求结束当前交互会话。
  final bool exitSession;
}

/// 指令后端能力 port。
///
/// core 的内置指令只依赖这个抽象接口，真正的会话读写由：
/// - adapters 的 `ProjectSessionShellCommandBackend`（CLI，包装 ProjectSessionShellService）
/// - app 的 `GuiConversationCommandBackend`（GUI，包装 ConversationSessionState 服务）
/// 各自实现。两端共用同一套 core 指令定义。
abstract class ConversationCommandBackend {
  /// 压缩当前会话上下文。
  Future<ConversationCommandBackendOutcome> compact(JsonMap sessionRecord);

  /// 只读读取上下文压力与会话统计，不改写会话。
  Future<ConversationCommandBackendOutcome> stats(JsonMap sessionRecord);

  /// 切换写作模式（sessionGoalModeId）。
  Future<ConversationCommandBackendOutcome> setMode(
    JsonMap sessionRecord,
    String mode,
  );

  /// 设置自由文本会话目标（conversation_goal）。
  Future<ConversationCommandBackendOutcome> setGoalText(
    JsonMap sessionRecord,
    String text,
  );

  /// 清空当前会话上下文（开始新会话 / 重置工作上下文）。
  Future<ConversationCommandBackendOutcome> clearContext(JsonMap sessionRecord);

  /// 结束当前交互会话。
  Future<ConversationCommandBackendOutcome> exitSession(JsonMap sessionRecord);
}
