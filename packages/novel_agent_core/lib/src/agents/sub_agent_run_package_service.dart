import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_delegation_plan_service.dart';
import 'agent_member_directory_service.dart';
import 'agent_profile_mapper_service.dart';
import 'agent_selection_service.dart';
import 'agent_string_list_service.dart';
import 'agent_task_brief_service.dart';
import 'child_failure_disposition.dart';
import 'child_run_package.dart';
import 'execution_package.dart';
import 'resolved_agent_group_profile_builder_service.dart';
import 'resolved_agent_skill_loadout_builder_service.dart';
import 'sub_agent_contract_components.dart';
import 'sub_agent_message_builder_service.dart';

class SubAgentRunPackageService {
  SubAgentRunPackageService({
    AgentMemberDirectoryService? memberDirectoryService,
    AgentSelectionService? selectionService,
    AgentStringListService? stringListService,
    AgentTaskBriefService? taskBriefService,
    AgentDelegationPlanService? delegationPlanService,
    SubAgentMessageBuilderService? messageBuilderService,
    AgentProfileMapperService? profileMapperService,
    ResolvedAgentGroupProfileBuilderService? groupProfileBuilderService,
    ResolvedAgentSkillLoadoutBuilderService? skillLoadoutBuilderService,
  }) : _memberDirectoryService =
           memberDirectoryService ?? AgentMemberDirectoryService(),
       _selectionService = selectionService ?? AgentSelectionService(),
       _stringListService = stringListService ?? AgentStringListService(),
       _taskBriefService = taskBriefService ?? AgentTaskBriefService(),
       _delegationPlanService =
           delegationPlanService ?? AgentDelegationPlanService(),
       _messageBuilderService =
           messageBuilderService ?? SubAgentMessageBuilderService(),
       _profileMapperService =
           profileMapperService ?? const AgentProfileMapperService(),
       _groupProfileBuilderService =
           groupProfileBuilderService ??
           ResolvedAgentGroupProfileBuilderService(),
       _skillLoadoutBuilderService =
           skillLoadoutBuilderService ??
           ResolvedAgentSkillLoadoutBuilderService();

  final AgentMemberDirectoryService _memberDirectoryService;
  final AgentSelectionService _selectionService;
  final AgentStringListService _stringListService;
  final AgentTaskBriefService _taskBriefService;
  final AgentDelegationPlanService _delegationPlanService;
  final SubAgentMessageBuilderService _messageBuilderService;
  final AgentProfileMapperService _profileMapperService;
  final ResolvedAgentGroupProfileBuilderService _groupProfileBuilderService;
  final ResolvedAgentSkillLoadoutBuilderService _skillLoadoutBuilderService;

  JsonMap buildSubAgentRunPackage(
    JsonMap agentGroup,
    List<Object?> availableAgents,
    JsonMap arguments, {
    JsonMap mainContext = const <String, Object?>{},
    JsonMap parentAgent = const <String, Object?>{},
    String parentModelId = '',
    String? createdAt,
  }) {
    // 中文注释: 运行包是 GUI/CLI 共用的宿主合同，因此这里只组装数据，不做实际模型调用。
    if (agentGroup.isEmpty) {
      return <String, Object?>{'ok': false, 'error': 'Agent group is empty.'};
    }
    final task = _argumentText(arguments, const <String>['task', 'query']);
    if (task.isEmpty) {
      return <String, Object?>{'ok': false, 'error': 'task is required.'};
    }

    final child = _selectChildAgent(agentGroup, availableAgents, arguments);
    if (child.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'No usable child agent in group.',
        'available_children': <Object?>[],
      };
    }

    final now = DateTime.now();
    final createdAtText = createdAt ?? now.toIso8601String();
    final childAgentId = ValueReaders.stringValue(child['id'], 'agent');
    final continueSessionId = _argumentText(arguments, const <String>[
      'continue_session_id',
      'continueSessionId',
    ]);
    final subSessionId = continueSessionId.isNotEmpty
        ? continueSessionId
        : 'sub_${childAgentId}_${now.microsecondsSinceEpoch}';
    final groupId = ValueReaders.stringValue(agentGroup['id']).trim();
    final groupName = ValueReaders.stringValue(agentGroup['name']).trim();
    final intent = ValueReaders.stringValue(
      mainContext['intent'],
      _argumentText(arguments, const <String>['intent'], fallback: 'draft'),
    ).trim();
    final constraints = _stringListService.normalize(arguments['constraints']);
    final sourcePaths = _stringListService.normalize(
      arguments['source_paths'] ?? arguments['sourcePaths'],
    );
    final taskExcerpt = _argumentText(arguments, const <String>[
      'context_excerpt',
      'contextExcerpt',
      'task_excerpt',
      'taskExcerpt',
    ], fallback: task);
    final expectedOutput = _argumentText(arguments, const <String>[
      'expected_output',
      'expectedOutput',
    ], fallback: _taskBriefService.expectedOutputForAgent(child, intent));
    final request = <String, Object?>{
      'intent': intent,
      'task_excerpt': taskExcerpt,
      'constraints': constraints,
    };
    final plan = _delegationPlanService.buildDelegationPlan(
      agentGroup,
      availableAgents,
      request: request,
      createdAt: createdAtText,
    );
    final tasks = ValueReaders.mapList(plan['tasks']);
    final delegation = tasks
        .map(ValueReaders.deepCopyMap)
        .firstWhere(
          (entry) =>
              ValueReaders.stringValue(entry['agent_id']) == childAgentId,
          orElse: () => <String, Object?>{},
        );
    delegation['task'] = task;
    delegation['source_paths'] = sourcePaths;
    delegation['expected_output'] = expectedOutput;

    final childProfile = _profileMapperService.fromDocument(child);
    final resolvedGroup = _groupProfileBuilderService.buildFromDocuments(
      agentGroup,
      availableAgents,
    );
    final loadout = _skillLoadoutBuilderService.build(profile: childProfile);
    final skillLoadout = ChildSkillLoadoutContract.fromResolved(loadout);
    final childToolPolicy = _toolPolicy(child);
    final allowedTools = _allowedTools(childToolPolicy, arguments);
    final blockedTools = _blockedTools(arguments, childToolPolicy);
    final permissionPolicy = ChildExecutionPermissionContract(
      allowedToolIds: allowedTools,
      blockedToolIds: blockedTools,
      allowedSkillIds: skillLoadout.finalSkillIds,
      allowedSkillGroupIds: skillLoadout.finalSkillGroupIds,
      allowFormalDelivery: false,
      allowRecursiveDelegation: false,
      allowUserQuestions: false,
      allowLongTaskControl: false,
      reason: '子智能体默认只能返回可合并结果，不拥有正式交付权、递归委派权或直接问用户权限。',
      metadata: const <String, Object?>{
        'formal_delivery_policy': 'parent_only',
      },
    );
    final goal = AgentExecutionGoalContract(
      intent: intent.isEmpty ? 'draft' : intent,
      task: task,
      taskExcerpt: taskExcerpt,
      expectedOutput: expectedOutput,
      constraints: constraints,
      metadata: const <String, Object?>{'scope': 'single_child_task'},
    );
    final context = AgentExecutionContextContract(
      mode: 'main_with_children',
      includeFullMainConversation: false,
      includeParentMessages: false,
      includeProjectStructure: true,
      projectTitle: ValueReaders.stringValue(
        mainContext['project_title'],
      ).trim(),
      contextExcerpt: taskExcerpt,
      sourcePaths: sourcePaths,
      description: '子智能体只接收主智能体整理的任务、摘录、结构信息和必要路径，不接收完整主会话。',
      metadata: const <String, Object?>{'isolation_level': 'excerpt_only'},
    );
    final maxToolRounds = ValueReaders.intValue(
      mainContext['sub_agent_max_tool_rounds'],
      2,
    ).clamp(1, 6);
    final maxConcurrentChildren = ValueReaders.intValue(
      mainContext['sub_agent_max_concurrency'],
      ValueReaders.intValue(arguments['max_concurrency'], 1),
    ).clamp(1, 4);
    final tokenBudget = ValueReaders.intValue(
      arguments['token_budget'],
      ValueReaders.intValue(mainContext['sub_agent_token_budget'], 0),
    );
    final maxRetryCount = ValueReaders.intValue(
      arguments['retry_budget'],
      ValueReaders.intValue(mainContext['sub_agent_retry_budget'], 1),
    ).clamp(0, 3);
    final timeoutSeconds = ValueReaders.intValue(
      arguments['timeout_seconds'],
      ValueReaders.intValue(mainContext['sub_agent_timeout_seconds'], 45),
    ).clamp(1, 300);
    final budgetPolicy = ChildExecutionBudgetContract(
      maxConcurrentChildren: maxConcurrentChildren,
      tokenBudget: tokenBudget,
      maxRetryCount: maxRetryCount,
      maxToolRounds: maxToolRounds,
      timeoutSeconds: timeoutSeconds,
      contextBudgetChars: taskExcerpt.length,
      outputBudgetChars: ValueReaders.intValue(
        arguments['output_budget_chars'],
        ValueReaders.intValue(mainContext['sub_agent_output_budget_chars'], 0),
      ),
      sourcePathCount: sourcePaths.length,
      metadata: const <String, Object?>{
        'budget_mode': 'main_agent_mediated',
        'collaboration_budget_contract': 'rrp13',
      },
    );
    final failurePolicy = ChildExecutionFailurePolicyContract(
      onToolError: ChildFailureDispositions.skipChild,
      onWaitingUser: ChildFailureDispositions.requireUser,
      onModelFailure: ChildFailureDispositions.retryChild,
      onTimeout: ChildFailureDispositions.retryChild,
      onEmptyResult: ChildFailureDispositions.retryChild,
      onBudgetExceeded: ChildFailureDispositions.fallbackSingleMain,
      retryableModelFailure: true,
      returnPartialResult: true,
      failToMainAgent: true,
      metadata: const <String, Object?>{
        'requires_parent_merge': true,
        'supports_partial_recovery': true,
      },
    );
    final modelPolicy = ChildExecutionModelContract(
      requestedModelId: _childRequestedModelId(child, parentModelId),
      providerProfile: childProfile.providerProfile,
      thinkingSupported: childProfile.thinkingSupported,
      thinkingEnabled: childProfile.thinkingEnabled,
      thinkingEffort: childProfile.thinkingEffort,
      temperature: childProfile.temperature,
      topP: childProfile.topP,
      topK: childProfile.topK,
      advancedModelOverrides: childProfile.advancedModelOverrides,
      metadata: const <String, Object?>{
        'effective_model_resolution': 'deferred_to_runtime',
      },
    );
    final messages = _messages(child, agentGroup, arguments, mainContext);
    final executionPackageId =
        'execution_${groupId.isEmpty ? 'group' : groupId}_${now.microsecondsSinceEpoch}';
    final childRunPackageId = 'child_run_$subSessionId';
    final childOutlines = _childOutlines(
      tasks: tasks,
      resolvedGroup: resolvedGroup,
      selectedAgentId: childAgentId,
      selectedChildRunPackageId: childRunPackageId,
      sourcePaths: sourcePaths,
      expectedOutput: expectedOutput,
      task: task,
    );
    final executionPackage = ExecutionPackage(
      packageId: executionPackageId,
      strategy: 'main_with_children',
      groupId: groupId,
      groupName: groupName,
      orchestration: resolvedGroup.orchestration,
      parentAgentId: ValueReaders.stringValue(parentAgent['id']).trim(),
      parentAgentName: ValueReaders.stringValue(parentAgent['name']).trim(),
      goal: goal,
      context: context,
      failurePolicy: failurePolicy,
      children: childOutlines,
      responseContract: '主智能体负责合并子结果，子智能体默认不能直接形成正式交付。',
      metadata: <String, Object?>{
        'group_member_count': childOutlines.length,
        'selected_agent_id': childAgentId,
        'relation_to_writing_execution_result': 'collaboration_results_input',
      },
    );
    final childRunPackage = ChildRunPackage(
      packageId: childRunPackageId,
      executionPackageId: executionPackageId,
      subSessionId: subSessionId,
      continueSessionId: continueSessionId,
      strategy: 'main_with_children',
      groupId: groupId,
      groupName: groupName,
      agentId: childAgentId,
      agentName: ValueReaders.stringValue(child['name'], childAgentId),
      agentRole: ValueReaders.stringValue(child['role']).trim(),
      goal: goal,
      context: context,
      skillLoadout: skillLoadout,
      permissionPolicy: permissionPolicy,
      modelPolicy: modelPolicy,
      budgetPolicy: budgetPolicy,
      failurePolicy: failurePolicy,
      messages: messages,
      responseContract: '返回给主智能体的内容应是可合并结论、风险、建议或正文片段；不要要求用户直接回答子智能体。',
      metadata: <String, Object?>{
        'delegation': ValueReaders.deepCopyMap(delegation),
        'agent_snapshot': ValueReaders.deepCopyMap(child),
      },
    );

    return <String, Object?>{
      'ok': true,
      'interaction_type': 'sub_agent_run_package',
      'strategy': 'main_with_children',
      'group_id': groupId,
      'group_name': groupName,
      'orchestration': resolvedGroup.orchestration,
      'execution_package_id': executionPackage.packageId,
      'child_run_package_id': childRunPackage.packageId,
      'agent_id': childRunPackage.agentId,
      'agent_name': childRunPackage.agentName,
      'agent': ValueReaders.deepCopyMap(child),
      'sub_session_id': childRunPackage.subSessionId,
      'continue_session_id': childRunPackage.continueSessionId,
      'task': task,
      'expected_output': expectedOutput,
      'delegation': ValueReaders.deepCopyMap(delegation),
      'messages': messages
          .map(ValueReaders.deepCopyMap)
          .toList(growable: false),
      'tool_scope': <String, Object?>{
        'agent_id': childRunPackage.agentId,
        'allowed_tools': childRunPackage.permissionPolicy.allowedToolIds,
        'skills': childRunPackage.skillLoadout.finalSkillIds,
        'skill_groups': childRunPackage.skillLoadout.finalSkillGroupIds,
        'blocked_tools': blockedTools,
        'allow_formal_delivery': false,
        'reason': childRunPackage.permissionPolicy.reason,
      },
      'context_policy': childRunPackage.context.toJson(),
      'source_paths': sourcePaths,
      'execution': <String, Object?>{
        'strategy': 'main_with_children',
        'run_model': true,
        'return_to_main_agent': true,
        'max_tool_rounds': maxToolRounds,
        'visibility': 'internal_runtime_only',
      },
      'response_contract': childRunPackage.responseContract,
      'created_at': createdAtText,
      'execution_package': executionPackage.toJson(),
      'child_run_package': childRunPackage.toJson(),
      'available_children': childOutlines
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
    };
  }

  List<JsonMap> _messages(
    JsonMap child,
    JsonMap agentGroup,
    JsonMap arguments,
    JsonMap mainContext,
  ) {
    return <JsonMap>[
      <String, Object?>{
        'role': 'system',
        'content': _messageBuilderService.childSystemPrompt(
          child,
          agentGroup,
          arguments,
          mainContext,
        ),
      },
      <String, Object?>{
        'role': 'system',
        'content': _messageBuilderService.childStructureMessage(
          agentGroup,
          arguments,
          mainContext,
        ),
      },
      <String, Object?>{
        'role': 'user',
        'content': _messageBuilderService.childUserMessage(arguments),
      },
    ];
  }

  List<String> _allowedTools(JsonMap childToolPolicy, JsonMap arguments) {
    final allowedTools = _stringListService.normalize(
      arguments['allowed_tools'] ?? childToolPolicy['allowed_tools'],
    );
    return allowedTools.toSet().toList(growable: false);
  }

  List<String> _blockedTools(JsonMap arguments, JsonMap childToolPolicy) {
    final blockedTools = _stringListService.normalize(
      arguments['blocked_tools'],
    );
    for (final toolId in _stringListService.normalize(
      childToolPolicy['blocked_tools'],
    )) {
      if (!blockedTools.contains(toolId)) {
        blockedTools.add(toolId);
      }
    }
    for (final toolId in const <String>[
      'call_sub_agent',
      'present_user_options',
      'submit_chapter_delivery',
      'start_long_task_run',
    ]) {
      if (!blockedTools.contains(toolId)) {
        blockedTools.add(toolId);
      }
    }
    return blockedTools;
  }

  JsonMap _toolPolicy(JsonMap child) {
    final direct = ValueReaders.mapValue(child['tool_policy']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final extensions = ValueReaders.mapValue(child['novel_agent_extensions']);
    final extensionPolicy = ValueReaders.mapValue(extensions['tool_policy']);
    if (extensionPolicy.isNotEmpty) {
      return extensionPolicy;
    }
    return ValueReaders.mapValue(
      ValueReaders.mapValue(child['metadata'])['tool_policy'],
    );
  }

  String _childRequestedModelId(JsonMap child, String parentModelId) {
    final childModelId = _argumentText(child, const <String>[
      'model_id',
      'model',
    ]);
    if (childModelId.isNotEmpty) {
      return childModelId;
    }
    return parentModelId;
  }

  List<ChildRunOutline> _childOutlines({
    required List<JsonMap> tasks,
    required dynamic resolvedGroup,
    required String selectedAgentId,
    required String selectedChildRunPackageId,
    required List<String> sourcePaths,
    required String expectedOutput,
    required String task,
  }) {
    final membersById = <String, dynamic>{
      for (final member in resolvedGroup.members) member.profile.id: member,
    };
    final outlines = <ChildRunOutline>[];
    for (final entry in tasks) {
      final agentId = ValueReaders.stringValue(entry['agent_id']).trim();
      final member = membersById[agentId];
      final childRunPackageId = agentId == selectedAgentId
          ? selectedChildRunPackageId
          : 'child_run_plan_$agentId';
      outlines.add(
        ChildRunOutline(
          childRunPackageId: childRunPackageId,
          agentId: agentId,
          agentName: ValueReaders.stringValue(entry['agent_name']).trim(),
          agentRole: ValueReaders.stringValue(
            entry['role'],
            member == null ? '' : member.profile.role,
          ).trim(),
          task: agentId == selectedAgentId
              ? task
              : ValueReaders.stringValue(entry['task']).trim(),
          expectedOutput: agentId == selectedAgentId
              ? expectedOutput
              : ValueReaders.stringValue(entry['expected_output']).trim(),
          skills: _stringListService.normalize(
            member == null ? const <String>[] : member.profile.skills,
          ),
          skillGroups: _stringListService.normalize(
            member == null ? const <String>[] : member.profile.skillGroups,
          ),
          isPrimary: member == null ? false : member.isPrimary,
          isRequired: member == null ? false : member.isRequired,
          selected: agentId == selectedAgentId,
          status: 'planned',
          metadata: <String, Object?>{'source_paths': sourcePaths},
        ),
      );
    }
    if (outlines.isEmpty) {
      outlines.add(
        ChildRunOutline(
          childRunPackageId: selectedChildRunPackageId,
          agentId: selectedAgentId,
          task: task,
          expectedOutput: expectedOutput,
          selected: true,
          status: 'planned',
          metadata: <String, Object?>{'source_paths': sourcePaths},
        ),
      );
    }
    return outlines;
  }

  JsonMap _selectChildAgent(
    JsonMap agentGroup,
    List<Object?> availableAgents,
    JsonMap arguments,
  ) {
    // 中文注释: 先尊重显式指定的 agent_id，再退回规则选人，最后才用第一候选兜底。
    final candidates = _memberDirectoryService.agentsInGroup(
      agentGroup,
      availableAgents,
    );
    final byId = _memberDirectoryService.agentsById(candidates);
    final requestedId = _argumentText(arguments, const <String>[
      'agent_id',
      'agentId',
      'target_agent_id',
      'targetAgentId',
    ]);
    if (requestedId.isNotEmpty && byId.containsKey(requestedId)) {
      return ValueReaders.mapValue(byId[requestedId]);
    }
    final task = _argumentText(arguments, const <String>['task', 'query']);
    final selectedId = _selectionService.selectAgentIdForTask(task, candidates);
    if (selectedId.isNotEmpty && byId.containsKey(selectedId)) {
      return ValueReaders.mapValue(byId[selectedId]);
    }
    return candidates.isEmpty
        ? <String, Object?>{}
        : ValueReaders.deepCopyMap(candidates.first);
  }

  String _argumentText(
    JsonMap arguments,
    List<String> keys, {
    String fallback = '',
  }) {
    // 中文注释: 字段兼容读取集中放这里，避免运行包服务里散落大量命名分支。
    for (final key in keys) {
      final value = ValueReaders.stringValue(arguments[key]).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }
}
