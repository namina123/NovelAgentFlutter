import '../common/json_types.dart';
import '../common/value_readers.dart';

class ToolEventPresenterService {
  String textForEvent(JsonMap event, {String fallbackText = ''}) {
    // 中文注释: 工具事件展示文案只负责把执行事实翻译成用户可读句子，不承接任何业务副作用。
    final phase = ValueReaders.stringValue(
      event['phase'],
      ValueReaders.stringValue(event['status']),
    ).trim();
    final ok = ValueReaders.boolValue(event['ok'], true);
    final notExecuted = ValueReaders.boolValue(event['not_executed']);
    var text = _cleanText(fallbackText);
    if (_isUnhelpfulText(text)) {
      text = _toolActionText(event, phase, ok);
    }
    if (notExecuted) {
      return _recoverableText(event, text);
    }
    if (phase == 'started' && text.startsWith('准备')) {
      text = text.substring(2).trim();
    }
    if (text.startsWith('智能体')) {
      return text;
    }
    if (!ok || phase == 'failed') {
      final reason = _errorReason(event);
      if (text.contains('失败')) {
        return '智能体$text';
      }
      return '智能体执行失败：$text${reason.isEmpty ? '' : '｜$reason'}';
    }
    if (phase == 'started') {
      return '智能体正在$text';
    }
    if (phase == 'streaming' || phase == 'progress') {
      return text.startsWith('正在') ? '智能体$text' : '智能体正在$text';
    }
    if (phase == 'finished') {
      return text.startsWith('已') ? '智能体$text' : '智能体已完成：$text';
    }
    return '智能体$text';
  }

  String textForExecutedTool(JsonMap executedTool) {
    // 中文注释: 已执行工具摘要统一从执行记录投影，供 GUI/CLI 历史回放复用。
    return textForEvent(<String, Object?>{
      'phase': ValueReaders.boolValue(executedTool['ok'], true)
          ? 'finished'
          : 'failed',
      'ok': ValueReaders.boolValue(executedTool['ok'], true),
      'not_executed': ValueReaders.boolValue(executedTool['not_executed']),
      'name': ValueReaders.stringValue(executedTool['name']),
      'arguments': ValueReaders.mapValue(executedTool['arguments']),
      'result': ValueReaders.mapValue(executedTool['result']),
    });
  }

  String _cleanText(String text) {
    // 中文注释: 展示文本统一做轻量清洗，避免换行和控制字符把会话列表撑乱。
    return text.trim().replaceAll('\r', ' ').replaceAll('\n', ' ');
  }

  bool _isUnhelpfulText(String text) {
    // 中文注释: 无意义占位文本统一在这里过滤，避免 UI 直接把调试符号显示给用户。
    if (text.isEmpty) {
      return true;
    }
    if (const <String>{
      '✓',
      '×',
      '•',
      '.',
      '-',
      'ok',
      'failed',
    }.contains(text)) {
      return true;
    }
    return text.contains('_') && !text.contains(' ');
  }

  String _toolActionText(JsonMap event, String phase, bool ok) {
    // 中文注释: 文案骨架按工具名、阶段和成功状态组合，保持同一工具在不同宿主上一致。
    final name = ValueReaders.stringValue(
      event['name'],
      ValueReaders.stringValue(event['tool_name']),
    ).trim();
    final arguments = ValueReaders.mapValue(event['arguments']);
    final result = ValueReaders.mapValue(event['result']);
    final target = _targetText(name, arguments, result);
    if (!ok || phase == 'failed') {
      return '${_verbFinished(name)}失败${target.isEmpty ? '' : '：$target'}';
    }
    if (phase == 'finished') {
      return '${_verbFinished(name)}${target.isEmpty ? '' : '：$target'}';
    }
    if (phase == 'streaming' || phase == 'progress') {
      return '正在组织${_toolLabel(name)}${target.isEmpty ? '' : '：$target'}';
    }
    return '${_verbStarted(name)}${target.isEmpty ? '' : '：$target'}';
  }

  String _verbStarted(String name) {
    // 中文注释: 开始态动词统一映射，避免同一工具在不同列表中出现多套叫法。
    switch (name) {
      case 'list_project_files':
        return '检查项目目录';
      case 'read_project_file':
        return '读取文件';
      case 'write_project_file':
        return '写入文件';
      case 'edit_project_file':
        return '修改文件';
      case 'create_project_entry':
        return '创建项目条目';
      case 'move_project_file':
        return '移动文件';
      case 'rename_project_file':
        return '重命名文件';
      case 'manipulate_project_file_lines':
        return '处理文件片段';
      case 'get_project_file_info':
        return '查看文件信息';
      case 'search_project_files':
        return '搜索项目文件';
      case 'delete_project_file':
        return '删除文件';
      case 'present_user_options':
        return '整理选项';
      case 'set_agent_tasks':
        return '整理执行计划';
      case 'load_agent_skill':
        return '读取技能说明';
      case 'call_sub_agent':
        return '委派子智能体';
      case 'run_continuity_check':
        return '保存检查报告';
      case 'create_backup':
        return '创建备份';
      case 'restore_backup':
        return '恢复备份';
      default:
        return '执行${_toolLabel(name)}';
    }
  }

  String _verbFinished(String name) {
    // 中文注释: 完成态动词集中维护，方便后续补更多工具时统一口径。
    switch (name) {
      case 'list_project_files':
        return '已检查项目目录';
      case 'read_project_file':
        return '已读取文件';
      case 'write_project_file':
        return '已写入文件';
      case 'edit_project_file':
        return '已修改文件';
      case 'create_project_entry':
        return '已创建项目条目';
      case 'move_project_file':
        return '已移动文件';
      case 'rename_project_file':
        return '已重命名文件';
      case 'manipulate_project_file_lines':
        return '已处理文件片段';
      case 'get_project_file_info':
        return '已查看文件信息';
      case 'search_project_files':
        return '已搜索项目文件';
      case 'delete_project_file':
        return '已删除文件';
      case 'present_user_options':
        return '已展示选项';
      case 'set_agent_tasks':
        return '已整理执行计划';
      case 'load_agent_skill':
        return '已读取技能说明';
      case 'call_sub_agent':
        return '子智能体已返回';
      case 'run_continuity_check':
        return '已保存检查报告';
      case 'create_backup':
        return '已创建备份';
      case 'restore_backup':
        return '已恢复备份';
      default:
        return '已执行${_toolLabel(name)}';
    }
  }

  String _toolLabel(String name) {
    // 中文注释: 工具名到用户标签的映射独立出来，后续可同时给提示词和 UI 复用。
    switch (name) {
      case 'list_project_files':
        return '目录检查';
      case 'read_project_file':
        return '文件读取';
      case 'write_project_file':
        return '文件写入';
      case 'edit_project_file':
        return '文件修改';
      case 'create_project_entry':
        return '项目条目创建';
      case 'move_project_file':
        return '文件移动';
      case 'rename_project_file':
        return '文件重命名';
      case 'manipulate_project_file_lines':
        return '文件片段处理';
      case 'get_project_file_info':
        return '文件信息查看';
      case 'search_project_files':
        return '项目搜索';
      case 'present_user_options':
        return '用户选项';
      case 'set_agent_tasks':
        return '执行计划';
      case 'load_agent_skill':
        return '技能说明';
      case 'call_sub_agent':
        return '子智能体';
      default:
        return name.isEmpty ? '工具' : name;
    }
  }

  String _targetText(String name, JsonMap arguments, JsonMap result) {
    // 中文注释: 工具目标摘要尽量优先显示真正变更路径，其次退回参数中的目标说明。
    switch (name) {
      case 'read_project_file':
      case 'edit_project_file':
      case 'delete_project_file':
      case 'create_backup':
        return _pathTarget(
          result,
          ValueReaders.stringValue(arguments['relative_path'], '未指定路径'),
        );
      case 'write_project_file':
        return _pathTarget(
          result,
          ValueReaders.stringValue(
            arguments['relative_path'],
            ValueReaders.stringValue(arguments['title'], '未指定路径'),
          ),
        );
      case 'create_project_entry':
      case 'move_project_file':
      case 'rename_project_file':
      case 'manipulate_project_file_lines':
      case 'get_project_file_info':
        return _pathTarget(
          result,
          ValueReaders.stringValue(
            arguments['relative_path'],
            ValueReaders.stringValue(arguments['path'], '未指定路径'),
          ),
        );
      case 'search_project_files':
        return ValueReaders.stringValue(
          arguments['pattern'],
          ValueReaders.stringValue(arguments['query'], '未指定关键词'),
        );
      case 'present_user_options':
        return ValueReaders.stringValue(
          result['question'],
          ValueReaders.stringValue(arguments['question'], '等待用户选择'),
        );
      case 'set_agent_tasks':
        return ValueReaders.stringValue(
          result['goal'],
          ValueReaders.stringValue(arguments['goal'], '当前任务'),
        );
      case 'load_agent_skill':
        return ValueReaders.stringValue(
          result['name'],
          ValueReaders.stringValue(arguments['skill_id'], '技能'),
        );
      case 'call_sub_agent':
        return ValueReaders.stringValue(
          result['agent_name'],
          ValueReaders.stringValue(
            arguments['agent_id'],
            ValueReaders.stringValue(arguments['agentId'], '子智能体'),
          ),
        );
      case 'run_continuity_check':
        return _pathTarget(
          result,
          ValueReaders.stringValue(arguments['title'], '检查报告'),
        );
      case 'restore_backup':
        return _pathTarget(
          result,
          ValueReaders.stringValue(arguments['backup_path'], '备份文件'),
        );
      default:
        return '';
    }
  }

  String _errorReason(JsonMap event) {
    // 中文注释: 错误原因统一从 result.error 抽取，避免把工具返回结构泄漏到展示层调用方。
    final result = ValueReaders.mapValue(event['result']);
    return ValueReaders.stringValue(result['error']).trim();
  }

  String _recoverableText(JsonMap event, String text) {
    // 中文注释: 可自纠正结果不应显示成失败，而应提示“需要补充哪类信息”。
    final result = ValueReaders.mapValue(event['result']);
    final suggestedTool = ValueReaders.stringValue(result['suggested_tool']);
    final rawError = ValueReaders.stringValue(
      result['error'],
      ValueReaders.stringValue(event['error']),
    ).trim();
    final prefix = suggestedTool.trim().isEmpty ? '需要补充信息' : '需要先$suggestedTool';
    final clean = (rawError.isNotEmpty ? rawError : text).trim();
    if (clean.isEmpty) {
      return prefix;
    }
    return '$prefix：$clean';
  }

  String _pathTarget(JsonMap result, String fallbackPath) {
    // 中文注释: 路径展示优先走 changed_paths/relative_path/backup_path，保持用户看到真实操作对象。
    final changedPaths = ValueReaders.stringList(result['changed_paths']);
    if (changedPaths.isNotEmpty) {
      return changedPaths.first;
    }
    final relativePath = ValueReaders.stringValue(
      result['relative_path'],
    ).trim();
    if (relativePath.isNotEmpty) {
      return relativePath;
    }
    final backupPath = ValueReaders.stringValue(result['backup_path']).trim();
    if (backupPath.isNotEmpty) {
      return backupPath;
    }
    return fallbackPath;
  }
}
