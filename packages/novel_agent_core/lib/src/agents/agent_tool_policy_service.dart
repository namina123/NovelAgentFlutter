import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../project/project_narrative_artifact_path_policy_service.dart';
import '../tools/domain/narrative_domain_tool_names.dart';

class AgentToolPolicyService {
  static const String formalDeliveryToolName =
      NarrativeDomainToolNames.submitChapterDelivery;

  static const Set<String> _formalDeliveryRecoveryReadOnlyToolNames = <String>{
    'list_project_files',
    'read_project_file',
    'get_project_file_info',
    'search_project_files',
    'load_agent_skill',
  };

  static const Set<String> _responseSynthesisReadOnlyToolNames = <String>{
    ..._formalDeliveryRecoveryReadOnlyToolNames,
    'list_history_sessions',
    'run_continuity_check',
  };

  static const Set<String> _formalDeliveryRecoveryNonSettlingToolNames =
      <String>{
        ..._formalDeliveryRecoveryReadOnlyToolNames,
        'set_agent_tasks',
        'present_user_options',
        'request_profile_clarification',
        'final_response',
        'tool_round_limit',
        formalDeliveryToolName,
      };
  static const ProjectNarrativeArtifactPathPolicyService
  _narrativeArtifactPathPolicyService =
      ProjectNarrativeArtifactPathPolicyService();

  bool lastToolWasOnlyPlan(List<Object?> executedTools) {
    // 中文注释: 计划型工具不代表任务已完成，这里集中判断避免宿主误把“列待办”当最终产物。
    if (executedTools.isEmpty) {
      return false;
    }
    var sawPlan = false;
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name == 'set_agent_tasks') {
        sawPlan = true;
        continue;
      }
      if (name == 'final_response' || name == 'tool_round_limit') {
        continue;
      }
      return false;
    }
    return sawPlan;
  }

  JsonMap afterToolRoundDecision(
    JsonMap nextResult, {
    required bool roundHasPlanTool,
    required bool planContinueRetryUsed,
    bool emptyReadOnlyRetryUsed = false,
    bool formalDeliveryRequired = false,
    int formalDeliveryContinueRetryCount = 0,
    int maxFormalDeliveryContinueRetries = 6,
    List<Object?> executedTools = const <Object?>[],
    List<Object?> writtenPaths = const <Object?>[],
  }) {
    // 中文注释: 工具轮后的续跑判断集中在核心策略层，避免不同宿主各自给正式交付补丁。
    final content = ValueReaders.stringValue(nextResult['content']).trim();
    final toolCalls = ValueReaders.objectList(nextResult['tool_calls']);
    if (toolCalls.isNotEmpty) {
      return <String, Object?>{
        'retry_after_plan': false,
        'retry_after_formal_delivery': false,
        'continue_instruction': '',
      };
    }
    if (formalDeliveryRequired &&
        executedTools.isNotEmpty &&
        formalDeliveryContinueRetryCount < maxFormalDeliveryContinueRetries &&
        !formalDeliveryAlreadySatisfied(
          executedTools: executedTools,
          writtenPaths: writtenPaths,
        )) {
      final restrictToFormalDelivery =
          content.isNotEmpty || hasFormalDeliveryRecoveryTrigger(executedTools);
      return <String, Object?>{
        'retry_after_plan': false,
        'retry_after_formal_delivery': true,
        'restrict_to_formal_delivery': restrictToFormalDelivery,
        'continue_instruction': _formalDeliveryContinueInstruction(content),
      };
    }
    if (!emptyReadOnlyRetryUsed &&
        content.isEmpty &&
        writtenPaths.isEmpty &&
        _shouldRetryAfterReadOnlyContextRound(executedTools)) {
      return <String, Object?>{
        'retry_after_plan': false,
        'retry_after_formal_delivery': false,
        'retry_after_read_only_context': true,
        'restrict_to_formal_delivery': false,
        'continue_instruction': _readOnlyContextContinueInstruction(),
      };
    }
    if (!roundHasPlanTool || planContinueRetryUsed || content.isNotEmpty) {
      return <String, Object?>{
        'retry_after_plan': false,
        'retry_after_formal_delivery': false,
        'retry_after_read_only_context': false,
        'restrict_to_formal_delivery': false,
        'continue_instruction': '',
      };
    }
    return <String, Object?>{
      'retry_after_plan': true,
      'retry_after_formal_delivery': false,
      'retry_after_read_only_context': false,
      'restrict_to_formal_delivery': false,
      'continue_instruction':
          '刚才只是更新了执行计划，还没有完成用户任务。请不要停在待办列表；现在继续执行当前步骤，必要时调用读取/写入/修改工具，或给出实质回答。',
    };
  }

  JsonMap afterExecutedToolRoundDecision({
    required bool formalDeliveryRequired,
    required int formalDeliveryContinueRetryCount,
    int maxFormalDeliveryContinueRetries = 6,
    required List<Object?> executedTools,
    List<Object?> recentExecutedTools = const <Object?>[],
    required List<Object?> writtenPaths,
    bool waitingForUserChoice = false,
    bool stoppedByToolError = false,
  }) {
    // 中文注释: 正式交付任务只在“侧向工作已结算”后强拉回交付；纯读取/技能加载仍允许模型继续判断是否需要资料工具。
    final recoverableFormalDeliveryFailure = _recoverableFormalDeliveryFailure(
      recentExecutedTools,
    );
    final canRecoverAfterToolError = recoverableFormalDeliveryFailure.isNotEmpty;
    if (!formalDeliveryRequired ||
        waitingForUserChoice ||
        (stoppedByToolError && !canRecoverAfterToolError) ||
        formalDeliveryContinueRetryCount >= maxFormalDeliveryContinueRetries ||
        formalDeliveryAlreadySatisfied(
          executedTools: executedTools,
          writtenPaths: writtenPaths,
        ) ||
        (!hasFormalDeliveryRecoveryTrigger(recentExecutedTools) &&
            !canRecoverAfterToolError)) {
      return const <String, Object?>{
        'continue_formal_delivery': false,
        'restrict_to_formal_delivery': false,
        'continue_instruction': '',
      };
    }
    return <String, Object?>{
      'continue_formal_delivery': true,
      'restrict_to_formal_delivery': true,
      'continue_instruction': _formalDeliveryContinueInstruction(
        '',
        previousDeliveryError: ValueReaders.stringValue(
          recoverableFormalDeliveryFailure['error'],
        ),
      ),
    };
  }

  bool hasFormalDeliveryRecoveryTrigger(List<Object?> executedTools) {
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name.isEmpty ||
          _formalDeliveryRecoveryNonSettlingToolNames.contains(name)) {
        continue;
      }
      if (ValueReaders.boolValue(tool['not_executed'])) {
        continue;
      }
      if (_isMergeableSubAgentFailure(tool)) {
        return true;
      }
      if (!ValueReaders.boolValue(tool['ok'], true)) {
        continue;
      }
      if (name == 'write_project_file' &&
          _writeProjectFileAlreadyDeliveredChapter(tool)) {
        continue;
      }
      return true;
    }
    return false;
  }

  bool formalDeliveryAlreadySatisfied({
    required List<Object?> executedTools,
    required List<Object?> writtenPaths,
  }) {
    if (_hasAcceptedFormalDelivery(executedTools)) {
      return true;
    }
    return writtenPaths.any(
      (path) => _isChapterPath(ValueReaders.stringValue(path)),
    );
  }

  JsonMap finalContentPolicy(
    String content, {
    required bool waitingForUserChoice,
    required List<Object?> executedTools,
    required List<Object?> writtenPaths,
  }) {
    // 中文注释: 最终正文为空时，核心统一给出收口策略，避免不同宿主出现不同的空响应体验。
    final cleanContent = content.trim();
    final hasWrittenPaths = writtenPaths.any(
      (path) => ValueReaders.stringValue(path).trim().isNotEmpty,
    );
    if (waitingForUserChoice && cleanContent.isEmpty) {
      return <String, Object?>{
        'mode': 'waiting_for_user_choice',
        'content': '我需要你先选择一个方向。你也可以忽略按钮，直接输入自己的想法。',
        'path_list': writtenPaths,
      };
    }
    if (cleanContent.isEmpty && lastToolWasOnlyPlan(executedTools)) {
      return <String, Object?>{
        'mode': 'only_plan',
        'content':
            '我已经列出执行计划，但还没有产出实质内容。请直接输入“继续”，我会按当前计划推进；如果你愿意，也可以指出优先处理哪一步。',
        'path_list': writtenPaths,
      };
    }
    if (cleanContent.isEmpty && hasWrittenPaths) {
      return <String, Object?>{
        'mode': 'written_only',
        'content': '',
        'path_list': writtenPaths,
      };
    }
    if (cleanContent.isNotEmpty && hasWrittenPaths) {
      return <String, Object?>{
        'mode': 'append_written_paths',
        'content': cleanContent,
        'path_list': writtenPaths,
      };
    }
    return <String, Object?>{
      'mode': 'content',
      'content': cleanContent,
      'path_list': writtenPaths,
    };
  }

  bool _hasAcceptedFormalDelivery(List<Object?> executedTools) {
    for (final rawTool in executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) != formalDeliveryToolName) {
        continue;
      }
      final result = ValueReaders.mapValue(tool['result']);
      if (!ValueReaders.boolValue(result['ok'], true)) {
        continue;
      }
      final status = ValueReaders.stringValue(
        result['domain_outcome_status'],
        ValueReaders.stringValue(
          ValueReaders.mapValue(result['domain_outcome'])['outcome_status'],
        ),
      ).trim();
      if (status.isEmpty || status == 'accepted') {
        return true;
      }
    }
    return false;
  }

  bool _shouldRetryAfterReadOnlyContextRound(List<Object?> executedTools) {
    if (executedTools.isEmpty) {
      return false;
    }
    var sawEligibleReadOnlyTool = false;
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name.isEmpty ||
          name == 'final_response' ||
          name == 'tool_round_limit') {
        continue;
      }
      if (ValueReaders.boolValue(tool['not_executed'])) {
        continue;
      }
      if (!ValueReaders.boolValue(tool['ok'], true)) {
        return false;
      }
      if (_responseSynthesisReadOnlyToolNames.contains(name)) {
        sawEligibleReadOnlyTool = true;
        continue;
      }
      return false;
    }
    return sawEligibleReadOnlyTool;
  }

  bool _isChapterPath(String path) {
    return _narrativeArtifactPathPolicyService.isNarrativeDeliveryPath(path);
  }

  bool _writeProjectFileAlreadyDeliveredChapter(JsonMap tool) {
    final arguments = ValueReaders.mapValue(tool['arguments']);
    final result = ValueReaders.mapValue(tool['result']);
    final candidatePaths = <String>[
      ValueReaders.stringValue(arguments['relative_path']),
      ValueReaders.stringValue(result['relative_path']),
      ...ValueReaders.stringList(result['changed_paths']),
    ];
    return candidatePaths.any(_isChapterPath);
  }

  bool _isMergeableSubAgentFailure(JsonMap tool) {
    if (ValueReaders.stringValue(tool['name']) != 'call_sub_agent') {
      return false;
    }
    if (ValueReaders.boolValue(tool['ok'], true)) {
      return false;
    }
    final result = ValueReaders.mapValue(tool['result']);
    final disposition = ValueReaders.stringValue(
      result['failure_disposition'],
    ).trim();
    return disposition.isNotEmpty && disposition != 'require_user';
  }

  JsonMap _recoverableFormalDeliveryFailure(List<Object?> recentExecutedTools) {
    for (final rawTool in recentExecutedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) != formalDeliveryToolName ||
          ValueReaders.boolValue(tool['ok'], true) ||
          ValueReaders.boolValue(tool['not_executed'])) {
        continue;
      }
      final arguments = ValueReaders.mapValue(tool['arguments']);
      final chapterPath = ValueReaders.stringValue(
        arguments['chapter_path'],
        ValueReaders.stringValue(arguments['relative_path']),
      ).trim();
      final chapterContent = ValueReaders.stringValue(
        arguments['chapter_content'],
        ValueReaders.stringValue(arguments['content']),
      ).trim();
      if (!_isChapterPath(chapterPath) || chapterContent.isEmpty) {
        continue;
      }
      final result = ValueReaders.mapValue(tool['result']);
      final outcomeStatus = ValueReaders.stringValue(
        result['domain_outcome_status'],
        ValueReaders.stringValue(
          ValueReaders.mapValue(result['domain_outcome'])['outcome_status'],
        ),
      ).trim();
      final error = ValueReaders.stringValue(
        result['error'],
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(result['domain_outcome'])['error'],
          )['message'],
        ),
      ).trim();
      if (outcomeStatus == 'invalid_payload' || error.isNotEmpty) {
        return <String, Object?>{
          'tool_name': formalDeliveryToolName,
          'outcome_status': outcomeStatus,
          'error': error,
        };
      }
    }
    return const <String, Object?>{};
  }

  String _formalDeliveryContinueInstruction(
    String previousContent, {
    String previousDeliveryError = '',
  }) {
    final hadDraftText = previousContent.trim().isNotEmpty;
    return [
      '当前是正式章节/样章/补写正文交付任务，但还没有形成受控章节交付。',
      if (hadDraftText) '你刚才已经给出了一段文本，但它还不能替代正式交付；请把可用正文整理为章节正文。',
      if (previousDeliveryError.trim().isNotEmpty)
        '上一轮 submit_chapter_delivery 未通过：${previousDeliveryError.trim()}',
      '现在请继续完成本轮交付：如还缺少必要上下文，可以只读取确实需要的项目文件；如资料已经足够，不要继续停在研究、说明或计划。',
      '如果子智能体只返回建议、审稿失败或空返回，主智能体必须自行兜底合并已有上下文并完成正文，不要把协作失败当作章节任务完成。',
      '如果已经调用过 request_external_research、submit_research_note、propose_knowledge_card 或 propose_design_element，就把其中真正可用的依据整合进正文，不要继续把本轮停在资料沉淀。',
      '如果失败原因涉及章节承接或字数 gate，就直接改写完整 chapter_content：第一段必须承接上一章已落定状态，不要倒带重演；同时把正文修到满足本轮长度窗口。',
      '正文达到可交付状态后，必须调用 submit_chapter_delivery，提交 chapter_path、chapter_content、title 和必要 submission；不要只用散文说明、只写 research/knowledge，或只声明“已完成”。',
    ].join('\n');
  }

  String _readOnlyContextContinueInstruction() {
    return [
      '你刚才主要在读取、检索或检查项目资料，但还没有真正完成用户请求。',
      '现在请基于已经读取到的上下文直接给出本轮实质结果：需要分析就直接分析，需要开局方案就直接给方案，需要正文/试写就直接写，不要只回复“已读取文件”或继续停在工具状态。',
      '除非确实缺少关键事实，否则不要重复读取同一批文件，也不要把本轮停在研究说明。',
    ].join('\n');
  }
}
