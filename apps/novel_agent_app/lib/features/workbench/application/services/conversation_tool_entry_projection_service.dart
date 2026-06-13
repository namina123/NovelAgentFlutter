import 'dart:convert';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_tool_lifecycle_status.dart';
import '../../../../shared/services/runtime_exposure_policy_service.dart';
import '../../presentation/models/conversation_entry_view_data.dart';

class ConversationToolEntryProjectionService {
  ConversationToolEntryProjectionService({
    ToolEventPresenterService? toolEventPresenterService,
    RuntimeExposurePolicyService? runtimeExposurePolicyService,
    InformationEvidenceProjectionService? informationEvidenceProjectionService,
    RuntimeExposureTier exposureTier = RuntimeExposureTier.standard,
  }) : _toolEventPresenterService =
           toolEventPresenterService ?? ToolEventPresenterService(),
       _runtimeExposurePolicyService =
           runtimeExposurePolicyService ?? const RuntimeExposurePolicyService(),
       _informationEvidenceProjectionService =
           informationEvidenceProjectionService ??
           const InformationEvidenceProjectionService(),
       _exposureTier = exposureTier;

  final ToolEventPresenterService _toolEventPresenterService;
  final RuntimeExposurePolicyService _runtimeExposurePolicyService;
  final InformationEvidenceProjectionService
  _informationEvidenceProjectionService;
  final RuntimeExposureTier _exposureTier;

  List<ConversationEntryViewData> build(List<Object?> executedTools) {
    return buildWithOptions(executedTools);
  }

  List<ConversationEntryViewData> buildPendingCallEntries(
    List<Object?> pendingToolCalls,
  ) {
    final result = <ConversationEntryViewData>[];
    for (final rawTool in pendingToolCalls) {
      final tool = ValueReaders.mapValue(rawTool);
      if (tool.isEmpty) {
        continue;
      }
      result.add(_projectPendingCall(tool));
    }
    return result;
  }

  List<ConversationEntryViewData> buildWithOptions(
    List<Object?> executedTools, {
    bool includeDetailBodies = true,
  }) {
    // 中文注释: 工具时间线投影单独抽出来，专门负责“轻量展示 + 连续重复压缩”。
    final result = <ConversationEntryViewData>[];
    _ProjectedToolGroup? currentGroup;
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      if (tool.isEmpty || _shouldSuppressFromTimeline(tool)) {
        continue;
      }
      final projected = _project(
        tool,
        includeDetailBodies: includeDetailBodies,
      );
      if (currentGroup != null && currentGroup.canAbsorb(projected)) {
        currentGroup = currentGroup.copyWith(count: currentGroup.count + 1);
        continue;
      }
      if (currentGroup != null) {
        result.add(currentGroup.toEntry());
      }
      currentGroup = _ProjectedToolGroup.fromEntry(projected);
    }
    if (currentGroup != null) {
      result.add(currentGroup.toEntry());
    }
    return result;
  }

  bool _shouldSuppressFromTimeline(JsonMap tool) {
    // 中文注释: 子智能体委派改由专属 preview/detail 流承接，主时间线不再重复刷底层工具回显。
    return ValueReaders.stringValue(tool['name']) == 'call_sub_agent';
  }

  ConversationEntryViewData _project(
    JsonMap tool, {
    required bool includeDetailBodies,
  }) {
    final name = ValueReaders.stringValue(tool['name'], '工具');
    final isError =
        !ValueReaders.boolValue(tool['ok'], true) &&
        !ValueReaders.boolValue(tool['not_executed']);
    return ConversationEntryViewData(
      id: 'tool_${ValueReaders.stringValue(tool['id'], name)}',
      kind: ConversationEntryKind.tool,
      title: _projectedToolTitle(name),
      body: _projectedToolBody(tool),
      isError: isError,
      toolLifecycleStatus: _toolLifecycleStatus(tool),
      detailTitle: _detailTitle(),
      detailSummary: _detailSummary(tool),
      detailBody: includeDetailBodies ? _detailBody(tool) : '',
      detailExpandedByDefault: false,
    );
  }

  ConversationEntryViewData _projectPendingCall(JsonMap tool) {
    final name = ValueReaders.stringValue(tool['name'], '工具');
    final target = _primaryTarget(tool);
    final rawId = ValueReaders.stringValue(
      tool['id'],
      '${name}_${target.hashCode}',
    );
    return ConversationEntryViewData(
      id: 'tool_pending_$rawId',
      kind: ConversationEntryKind.tool,
      title: _projectedToolTitle(name),
      body: _projectedPendingBody(name, target: target),
      toolLifecycleStatus: ConversationToolLifecycleStatus.running,
    );
  }

  String _detailSummary(JsonMap tool) {
    final informationProjection = _informationProjection(tool);
    if (informationProjection.hasContent &&
        informationProjection.summary.isNotEmpty) {
      return informationProjection.summary;
    }
    if (_runtimeExposurePolicyService.exposesInternalRuntimeTerms(
      _exposureTier,
    )) {
      final internalLines = _internalEvidenceLines(tool);
      if (internalLines.isNotEmpty) {
        return internalLines.first;
      }
    }
    final target = _primaryTarget(tool);
    if (target.isNotEmpty) {
      return target;
    }
    final arguments = ValueReaders.mapValue(tool['arguments']);
    if (arguments.isNotEmpty) {
      return '含参数';
    }
    final result = ValueReaders.mapValue(tool['result']);
    if (result.isNotEmpty) {
      return '含结果';
    }
    return '';
  }

  String _detailBody(JsonMap tool) {
    if (!_runtimeExposurePolicyService.exposesStructuredEvidence(
      _exposureTier,
    )) {
      return _standardDetailBody(tool);
    }
    final sections = <String>[];
    final informationProjection = _informationProjection(tool);
    final informationLines = informationProjection.hasContent
        ? informationProjection.userLines
        : const <String>[];
    if (informationLines.isNotEmpty) {
      sections.add('信息摘要');
      sections.add(informationLines.join('\n'));
    }
    final arguments = ValueReaders.mapValue(tool['arguments']);
    final result = ValueReaders.mapValue(tool['result']);
    if (arguments.isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add('');
      }
      sections.add('参数');
      sections.add(_prettyMap(arguments));
    }
    if (result.isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add('');
      }
      sections.add('结果');
      sections.add(_prettyMap(result));
    }
    final internalLines = _internalEvidenceLines(tool);
    if (internalLines.isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add('');
      }
      sections.add('运行证据');
      sections.add(internalLines.join('\n'));
    }
    if (_runtimeExposurePolicyService.exposesRawJson(_exposureTier) &&
        informationProjection.diagnosticLines.isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add('');
      }
      sections.add('信息诊断');
      sections.add(informationProjection.diagnosticLines.join('\n'));
    }
    if (_runtimeExposurePolicyService.exposesRawJson(_exposureTier)) {
      if (sections.isNotEmpty) {
        sections.add('');
      }
      sections.add('原始事件 JSON');
      sections.add(_prettyMap(tool));
    }
    return sections.join('\n');
  }

  String _standardDetailBody(JsonMap tool) {
    final sections = <String>[];
    final informationProjection = _informationProjection(tool);
    final informationLines = informationProjection.hasContent
        ? informationProjection.userLines
        : const <String>[];
    if (informationLines.isNotEmpty) {
      sections.add('信息摘要');
      sections.add(informationLines.join('\n'));
    }
    final evidenceLines = _standardEvidenceLines(tool);
    if (evidenceLines.isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add('');
      }
      sections.add('执行依据');
      sections.add(evidenceLines.join('\n'));
    }
    return sections.join('\n');
  }

  InformationEvidenceProjection _informationProjection(JsonMap tool) {
    return _informationEvidenceProjectionService.fromToolResult(
      ValueReaders.mapValue(tool['result']),
    );
  }

  String _primaryTarget(JsonMap tool) {
    final result = ValueReaders.mapValue(tool['result']);
    final changedPaths = ValueReaders.stringList(result['changed_paths']);
    if (changedPaths.isNotEmpty) {
      return changedPaths.first;
    }
    final relativePath = ValueReaders.stringValue(
      result['relative_path'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(tool['arguments'])['relative_path'],
      ),
    ).trim();
    if (relativePath.isNotEmpty) {
      return relativePath;
    }
    return ValueReaders.stringValue(result['question']).trim();
  }

  String _detailTitle() {
    switch (_exposureTier) {
      case RuntimeExposureTier.standard:
        return '执行依据';
      case RuntimeExposureTier.advanced:
        return '运行证据';
      case RuntimeExposureTier.diagnostic:
        return '工具细节';
    }
  }

  String _projectedToolTitle(String toolName) {
    if (_runtimeExposurePolicyService.exposesRawJson(_exposureTier)) {
      return toolName;
    }
    switch (toolName) {
      case 'list_project_files':
        return '目录检查';
      case 'read_project_file':
        return '文件读取';
      case 'write_project_file':
        return '文件写入';
      case 'submit_chapter_delivery':
        return '章节交付';
      case 'submit_narrative_state_claims':
        return '叙事状态更新';
      case 'submit_semantic_review':
        return '语义复核';
      case 'propose_constraint_binding':
        return '规则绑定';
      case 'request_profile_clarification':
        return '规则确认';
      case 'start_long_task_run':
        return '长任务启动';
      case 'load_agent_skill':
        return '技能加载';
      case 'propose_knowledge_card':
        return '知识卡提案';
      case 'propose_design_element':
        return '设计元素提案';
      case 'submit_research_note':
        return '研究记录';
      case 'propose_reference_work':
        return '引用边界提案';
      case 'request_external_research':
        return '资料研究请求';
      default:
        return '工具操作';
    }
  }

  String _projectedToolBody(JsonMap tool) {
    if (_runtimeExposurePolicyService.exposesRawJson(_exposureTier)) {
      return _toolEventPresenterService.textForExecutedTool(tool);
    }
    final name = ValueReaders.stringValue(tool['name']);
    final isError =
        !ValueReaders.boolValue(tool['ok'], true) &&
        !ValueReaders.boolValue(tool['not_executed']);
    if (ValueReaders.boolValue(tool['not_executed'])) {
      return '需要确认';
    }
    if (isError) {
      return '需要处理';
    }
    return _projectedCompletedBody(tool, toolName: name);
  }

  ConversationToolLifecycleStatus _toolLifecycleStatus(JsonMap tool) {
    if (ValueReaders.boolValue(tool['not_executed'])) {
      return ConversationToolLifecycleStatus.pendingConfirmation;
    }
    if (!ValueReaders.boolValue(tool['ok'], true)) {
      return ConversationToolLifecycleStatus.failed;
    }
    return ConversationToolLifecycleStatus.completed;
  }

  String _projectedPendingBody(String toolName, {required String target}) {
    switch (toolName) {
      case 'read_project_file':
        return target.isEmpty ? '已发起，正在读取文件' : '已发起，正在读取 $target';
      case 'list_project_files':
      case 'search_project_files':
        return '已发起，正在检查项目内容';
      case 'write_project_file':
      case 'edit_project_file':
      case 'create_project_entry':
      case 'rename_project_file':
      case 'manipulate_project_file_lines':
        return target.isEmpty ? '已发起，正在写入文件' : '已发起，正在写入 $target';
      case 'load_agent_skill':
        return '已发起，正在加载技能';
      case 'request_external_research':
        return '已发起，正在发起资料研究';
      case 'request_profile_clarification':
      case 'present_user_options':
        return '已发起，正在整理待确认项';
      case 'submit_chapter_delivery':
        return '已发起，正在提交章节交付';
      case 'submit_narrative_state_claims':
      case 'propose_knowledge_card':
      case 'propose_design_element':
      case 'submit_research_note':
      case 'propose_reference_work':
      case 'update_world_state':
      case 'update_character_state':
      case 'update_foreshadow_state':
      case 'update_timeline_state':
      case 'update_relationship_state':
        return '已发起，正在写回项目资料';
      default:
        return '已发起，正在等待工具返回';
    }
  }

  String _projectedCompletedBody(JsonMap tool, {required String toolName}) {
    final target = _primaryTarget(tool);
    switch (toolName) {
      case 'submit_chapter_delivery':
        return '已交付章节';
      case 'write_project_file':
      case 'edit_project_file':
      case 'create_project_entry':
      case 'rename_project_file':
      case 'manipulate_project_file_lines':
        if (_isChapterPath(target)) {
          return '已保存正文';
        }
        if (_isPlanningPath(target)) {
          return '已更新开局资料';
        }
        if (_isInformationPath(target)) {
          return '已更新资料';
        }
        return '已更新文件';
      case 'read_project_file':
        return _isChapterPath(target) ? '已读取正文' : '已读取文件';
      case 'list_project_files':
      case 'search_project_files':
        return '已检查项目内容';
      case 'load_agent_skill':
        return '已加载技能';
      case 'submit_narrative_state_claims':
      case 'propose_knowledge_card':
      case 'propose_design_element':
      case 'submit_research_note':
      case 'propose_reference_work':
      case 'update_world_state':
      case 'update_character_state':
      case 'update_foreshadow_state':
      case 'update_timeline_state':
      case 'update_relationship_state':
        return '已更新资料';
      case 'request_external_research':
        return '已登记资料研究';
      case 'request_profile_clarification':
      case 'present_user_options':
        return '需要确认';
      case 'submit_semantic_review':
        return '已完成复核';
      default:
        return _toolEventPresenterService.textForExecutedTool(tool);
    }
  }

  List<String> _standardEvidenceLines(JsonMap tool) {
    final lines = <String>[];
    final target = _primaryTarget(tool);
    if (target.isNotEmpty) {
      lines.add('相关对象：$target');
    }
    final arguments = ValueReaders.mapValue(tool['arguments']);
    final result = ValueReaders.mapValue(tool['result']);
    final question = ValueReaders.stringValue(
      result['question'],
      ValueReaders.stringValue(arguments['question']),
    ).trim();
    if (question.isNotEmpty && !lines.contains('待确认事项：$question')) {
      lines.add('待确认事项：$question');
    }
    final changedPaths = _informationChangedPaths(result);
    if (changedPaths.isNotEmpty) {
      lines.add('已更新 ${changedPaths.length} 个相关文件');
    }
    return lines;
  }

  List<String> _internalEvidenceLines(JsonMap tool) {
    final lines = <String>[];
    void addLine(String label, String value) {
      final clean = value.trim();
      if (clean.isEmpty) {
        return;
      }
      lines.add('$label：$clean');
    }

    void readInternalFields(JsonMap source) {
      addLine(
        'Prompt Block',
        ValueReaders.stringValue(source['prompt_block_id']),
      );
      addLine(
        'Tool Profile',
        ValueReaders.stringValue(source['tool_profile_id']),
      );
      addLine('子任务会话', ValueReaders.stringValue(source['sub_session_id']));
      final executionConstraint = ValueReaders.mapValue(
        source['execution_constraint'],
      );
      if (executionConstraint.isNotEmpty) {
        addLine('执行约束', executionConstraint.keys.join(', '));
      }
      final executionConstraintText = ValueReaders.stringValue(
        source['execution_constraint'],
      );
      addLine('执行约束', executionConstraintText);
    }

    readInternalFields(tool);
    readInternalFields(ValueReaders.mapValue(tool['arguments']));
    readInternalFields(ValueReaders.mapValue(tool['result']));
    return lines;
  }

  String _prettyMap(JsonMap map) {
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  List<String> _informationChangedPaths(JsonMap result) {
    final changedPaths = <String>[];

    void addPaths(Object? value) {
      for (final rawPath in ValueReaders.stringList(value)) {
        final normalized = rawPath.replaceAll('\\', '/').trim();
        if (normalized.isEmpty || changedPaths.contains(normalized)) {
          continue;
        }
        changedPaths.add(normalized);
      }
    }

    addPaths(result['changed_paths']);
    final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
    final persistence = ValueReaders.mapValue(
      ValueReaders.mapValue(domainOutcome['metadata'])['adapter_persistence'],
    );
    addPaths(persistence['changed_paths']);
    return changedPaths;
  }

  bool _isChapterPath(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/').trim().toLowerCase();
    return normalized.startsWith('chapters/');
  }

  bool _isPlanningPath(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/').trim().toLowerCase();
    return normalized.startsWith('premise/') ||
        normalized.startsWith('outlines/') ||
        normalized.startsWith('outline/') ||
        normalized.startsWith('chapter_outlines/') ||
        normalized.startsWith('volume_outlines/');
  }

  bool _isInformationPath(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/').trim().toLowerCase();
    return normalized.startsWith('assets/') ||
        normalized.startsWith('knowledge/') ||
        normalized.startsWith('references/') ||
        normalized.startsWith('.novel_agent/information/');
  }
}

class _ProjectedToolGroup {
  const _ProjectedToolGroup({required this.entry, required this.count});

  final ConversationEntryViewData entry;
  final int count;

  factory _ProjectedToolGroup.fromEntry(ConversationEntryViewData entry) {
    return _ProjectedToolGroup(entry: entry, count: 1);
  }

  bool canAbsorb(ConversationEntryViewData candidate) {
    // 中文注释: 只压缩相邻且语义完全一致的工具提示，避免把不同上下文的调用硬并在一起。
    return entry.kind == candidate.kind &&
        entry.title == candidate.title &&
        entry.body == candidate.body &&
        entry.isError == candidate.isError;
  }

  _ProjectedToolGroup copyWith({ConversationEntryViewData? entry, int? count}) {
    return _ProjectedToolGroup(
      entry: entry ?? this.entry,
      count: count ?? this.count,
    );
  }

  ConversationEntryViewData toEntry() {
    if (count <= 1) {
      return entry;
    }
    return ConversationEntryViewData(
      id: '${entry.id}_x$count',
      kind: entry.kind,
      title: '${entry.title} ×$count',
      body: entry.body,
      isError: entry.isError,
      isRetryableFailure: entry.isRetryableFailure,
      toolLifecycleStatus: entry.toolLifecycleStatus,
      detailTitle: entry.detailTitle,
      detailSummary: entry.detailSummary,
      detailBody: entry.detailBody,
      detailExpandedByDefault: entry.detailExpandedByDefault,
    );
  }
}
