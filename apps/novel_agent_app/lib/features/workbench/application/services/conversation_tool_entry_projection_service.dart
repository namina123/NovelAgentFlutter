import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/runtime_exposure_policy_service.dart';
import '../../presentation/models/conversation_entry_view_data.dart';

class ConversationToolEntryProjectionService {
  static const String _knowledgeCardsRoot =
      '.novel_agent/information/knowledge_cards/';
  static const String _designElementsRoot =
      '.novel_agent/information/design_elements/';
  static const String _researchNotesRoot =
      '.novel_agent/information/research_notes/';
  static const String _referenceWorksRoot =
      '.novel_agent/information/reference_works/';

  ConversationToolEntryProjectionService({
    ToolEventPresenterService? toolEventPresenterService,
    RuntimeExposurePolicyService? runtimeExposurePolicyService,
    RuntimeExposureTier exposureTier = RuntimeExposureTier.standard,
  }) : _toolEventPresenterService =
           toolEventPresenterService ?? ToolEventPresenterService(),
       _runtimeExposurePolicyService =
           runtimeExposurePolicyService ?? const RuntimeExposurePolicyService(),
       _exposureTier = exposureTier;

  final ToolEventPresenterService _toolEventPresenterService;
  final RuntimeExposurePolicyService _runtimeExposurePolicyService;
  final RuntimeExposureTier _exposureTier;

  List<ConversationEntryViewData> build(List<Object?> executedTools) {
    return buildWithOptions(executedTools);
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
      detailTitle: _detailTitle(),
      detailSummary: _detailSummary(tool),
      detailBody: includeDetailBodies ? _detailBody(tool) : '',
      detailExpandedByDefault: false,
    );
  }

  String _detailSummary(JsonMap tool) {
    final informationSummary = _informationDetailSummary(tool);
    if (informationSummary.isNotEmpty) {
      return informationSummary;
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
    if (!_runtimeExposurePolicyService.exposesStructuredEvidence(_exposureTier)) {
      return _standardDetailBody(tool);
    }
    final sections = <String>[];
    final informationLines = _informationDetailLines(tool);
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
    final informationLines = _informationDetailLines(tool);
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

  String _informationDetailSummary(JsonMap tool) {
    final lines = _informationDetailLines(tool);
    if (lines.isEmpty) {
      return '';
    }
    return lines.first.replaceFirst('Information：', '').trim();
  }

  List<String> _informationDetailLines(JsonMap tool) {
    final result = ValueReaders.mapValue(tool['result']);
    final changedPaths = _informationChangedPaths(result);
    final changedCounts = _informationChangedCounts(changedPaths);
    final analysisInformation = _analysisInformation(result);
    final analysisCounts = _analysisInformationCounts(analysisInformation);
    final knowledge = _maxCount(
      ValueReaders.intValue(changedCounts['knowledge']),
      ValueReaders.intValue(analysisCounts['knowledge']),
    );
    final design = _maxCount(
      ValueReaders.intValue(changedCounts['design']),
      ValueReaders.intValue(analysisCounts['design']),
    );
    final research = _maxCount(
      ValueReaders.intValue(changedCounts['research']),
      ValueReaders.intValue(analysisCounts['research']),
    );
    final reference = _maxCount(
      ValueReaders.intValue(changedCounts['reference']),
      ValueReaders.intValue(analysisCounts['reference']),
    );
    final signal = _informationSignal(result);
    final hasInformation =
        knowledge > 0 ||
        design > 0 ||
        research > 0 ||
        reference > 0 ||
        signal.isNotEmpty;
    if (!hasInformation) {
      return const <String>[];
    }
    return <String>[
      'Information：knowledge $knowledge | design $design | research $research | reference $reference',
      if (signal.isNotEmpty) 'Information Signal：$signal',
      'Information Projections：'
          '${InformationProjectionDocument.knowledgeSummaryRelativePath} | '
          '${InformationProjectionDocument.designSummaryRelativePath} | '
          '${InformationProjectionDocument.researchSummaryRelativePath} | '
          '${InformationProjectionDocument.referenceBoundaryRelativePath}',
    ];
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
    switch (name) {
      case 'submit_chapter_delivery':
      case 'write_project_file':
      case 'edit_project_file':
      case 'create_project_entry':
      case 'rename_project_file':
      case 'manipulate_project_file_lines':
        return '已保存正文';
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
      addLine('Prompt Block', ValueReaders.stringValue(source['prompt_block_id']));
      addLine('Tool Profile', ValueReaders.stringValue(source['tool_profile_id']));
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

  JsonMap _informationChangedCounts(List<String> changedPaths) {
    var knowledge = 0;
    var design = 0;
    var research = 0;
    var reference = 0;
    for (final path in changedPaths) {
      if (path.startsWith(_knowledgeCardsRoot)) {
        knowledge += 1;
      } else if (path.startsWith(_designElementsRoot)) {
        design += 1;
      } else if (path.startsWith(_researchNotesRoot)) {
        research += 1;
      } else if (path.startsWith(_referenceWorksRoot)) {
        reference += 1;
      }
    }
    return <String, Object?>{
      'knowledge': knowledge,
      'design': design,
      'research': research,
      'reference': reference,
    };
  }

  JsonMap _analysisInformation(JsonMap result) {
    final direct = ValueReaders.mapValue(result['analysis_information']);
    if (direct.isNotEmpty) {
      return direct;
    }
    return ValueReaders.mapValue(
      ValueReaders.mapValue(result['execution'])['analysis_information'],
    );
  }

  JsonMap _analysisInformationCounts(JsonMap analysisInformation) {
    return <String, Object?>{
      'knowledge': ValueReaders.stringList(
        analysisInformation['knowledge_card_ids'],
      ).length,
      'design': ValueReaders.stringList(
        analysisInformation['design_element_ids'],
      ).length,
      'research': ValueReaders.stringList(
        analysisInformation['research_note_ids'],
      ).length,
      'reference': ValueReaders.stringList(
        analysisInformation['reference_work_ids'],
      ).length,
    };
  }

  String _informationSignal(JsonMap result) {
    final checkpointReview = ValueReaders.mapValue(result['checkpoint_review']);
    final checkpointReviewBody = ValueReaders.mapValue(
      checkpointReview['review'],
    );
    final direct = ValueReaders.stringValue(
      checkpointReviewBody['information_summary'],
    ).trim();
    if (direct.isNotEmpty) {
      return direct;
    }
    return ValueReaders.stringValue(result['information_summary']).trim();
  }

  int _maxCount(int left, int right) {
    return left >= right ? left : right;
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
      detailTitle: entry.detailTitle,
      detailSummary: entry.detailSummary,
      detailBody: entry.detailBody,
      detailExpandedByDefault: entry.detailExpandedByDefault,
    );
  }
}
