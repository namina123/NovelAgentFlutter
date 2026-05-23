import 'session_record_constants.dart';

class SessionModeService {
  String cleanMode(String mode) {
    // 中文注释: 会话模式入口统一在这里清洗，避免空模式值把后续阶段判断拖进异常分支。
    final value = mode.trim();
    return value.isEmpty ? SessionRecordConstants.modeUnselected : value;
  }

  int clampThreshold(int value) {
    // 中文注释: 压缩阈值属于会话记录的核心保护参数，统一在这里做边界裁剪。
    var result = value <= 0
        ? SessionRecordConstants.defaultThresholdChars
        : value;
    if (result < SessionRecordConstants.minThresholdChars) {
      return SessionRecordConstants.minThresholdChars;
    }
    if (result > SessionRecordConstants.maxThresholdChars) {
      return SessionRecordConstants.maxThresholdChars;
    }
    return result;
  }

  String defaultTitle(String mode) {
    // 中文注释: 默认标题由模式决定，避免 GUI 和 CLI 各自维护一套同义标题表。
    switch (mode) {
      case SessionRecordConstants.modeSmartOpening:
        return '智能开局';
      case SessionRecordConstants.modeSummarizeBook:
        return '总结全书';
      case SessionRecordConstants.modeChapterDraft:
        return '单章创作';
      case SessionRecordConstants.modeImportArticle:
        return '导入已有文章';
      case SessionRecordConstants.modeContinueWriting:
        return '继续创作';
      case SessionRecordConstants.modeUnselected:
      default:
        return '新会话';
    }
  }

  String initialStage(String mode) {
    // 中文注释: 初始阶段用于会话刚创建时的 UI 和上下文状态，必须和模式保持一致。
    switch (mode) {
      case SessionRecordConstants.modeUnselected:
        return 'pending_goal';
      case SessionRecordConstants.modeSummarizeBook:
        return 'summary';
      case SessionRecordConstants.modeImportArticle:
        return 'ingest';
      case SessionRecordConstants.modeChapterDraft:
      case SessionRecordConstants.modeContinueWriting:
        return 'draft';
      default:
        return 'opening';
    }
  }

  String publicStatus(String mode, String stage, bool isCreative) {
    // 中文注释: 公开状态文本只反映用户可理解的进度，不把底层工作流细节直接暴露出去。
    if (mode == SessionRecordConstants.modeUnselected ||
        stage == 'pending_goal') {
      return '选择会话目标';
    }
    if (mode == SessionRecordConstants.modeSummarizeBook) {
      return '准备汇总与压缩';
    }
    if (mode == SessionRecordConstants.modeImportArticle) {
      return '准备导入与建库';
    }
    if (isCreative) {
      return '创作已启动';
    }
    if (stage == 'outline') {
      return '正在收敛大纲';
    }
    if (stage == 'draft') {
      return '准备正文';
    }
    return '正在开局探索';
  }

  String clip(String value, int maxChars) {
    // 中文注释: 会话摘要裁剪统一在这里处理，避免压缩记录在各处出现不同的截断格式。
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars)}...';
  }
}
