import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'child_failure_disposition.dart';
import 'resolved_agent_skill_loadout.dart';

class AgentExecutionGoalContract {
  const AgentExecutionGoalContract({
    this.intent = '',
    this.task = '',
    this.taskExcerpt = '',
    this.expectedOutput = '',
    this.constraints = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String intent;
  final String task;
  final String taskExcerpt;
  final String expectedOutput;
  final List<String> constraints;
  final JsonMap metadata;

  factory AgentExecutionGoalContract.fromJson(JsonMap json) {
    return AgentExecutionGoalContract(
      intent: ValueReaders.stringValue(json['intent']).trim(),
      task: ValueReaders.stringValue(json['task']).trim(),
      taskExcerpt: ValueReaders.stringValue(json['task_excerpt']).trim(),
      expectedOutput: ValueReaders.stringValue(json['expected_output']).trim(),
      constraints: ValueReaders.stringList(json['constraints']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'intent': intent,
      'task': task,
      'task_excerpt': taskExcerpt,
      'expected_output': expectedOutput,
      'constraints': constraints,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (intent.trim().isEmpty) {
      result.add('missing_agent_execution_goal_intent');
    }
    if (task.trim().isEmpty) {
      result.add('missing_agent_execution_goal_task');
    }
    return result;
  }
}

class AgentExecutionContextContract {
  const AgentExecutionContextContract({
    this.mode = '',
    this.includeFullMainConversation = false,
    this.includeParentMessages = false,
    this.includeProjectStructure = true,
    this.projectTitle = '',
    this.contextExcerpt = '',
    this.sourcePaths = const <String>[],
    this.description = '',
    this.metadata = const <String, Object?>{},
  });

  final String mode;
  final bool includeFullMainConversation;
  final bool includeParentMessages;
  final bool includeProjectStructure;
  final String projectTitle;
  final String contextExcerpt;
  final List<String> sourcePaths;
  final String description;
  final JsonMap metadata;

  factory AgentExecutionContextContract.fromJson(JsonMap json) {
    return AgentExecutionContextContract(
      mode: ValueReaders.stringValue(json['mode']).trim(),
      includeFullMainConversation: ValueReaders.boolValue(
        json['include_full_main_conversation'],
      ),
      includeParentMessages: ValueReaders.boolValue(
        json['include_parent_messages'],
      ),
      includeProjectStructure: ValueReaders.boolValue(
        json['include_project_structure'],
        true,
      ),
      projectTitle: ValueReaders.stringValue(json['project_title']).trim(),
      contextExcerpt: ValueReaders.stringValue(json['context_excerpt']).trim(),
      sourcePaths: ValueReaders.stringList(json['source_paths']),
      description: ValueReaders.stringValue(json['description']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'mode': mode,
      'include_full_main_conversation': includeFullMainConversation,
      'include_parent_messages': includeParentMessages,
      'include_project_structure': includeProjectStructure,
      'project_title': projectTitle,
      'context_excerpt': contextExcerpt,
      'source_paths': sourcePaths,
      'description': description,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (mode.trim().isEmpty) {
      result.add('missing_agent_execution_context_mode');
    }
    if (includeFullMainConversation) {
      result.add('invalid_agent_execution_context_full_main_conversation');
    }
    if (includeParentMessages) {
      result.add('invalid_agent_execution_context_parent_messages');
    }
    return result;
  }
}

class ChildExecutionPermissionContract {
  const ChildExecutionPermissionContract({
    this.allowedToolIds = const <String>[],
    this.blockedToolIds = const <String>[],
    this.allowedSkillIds = const <String>[],
    this.allowedSkillGroupIds = const <String>[],
    this.allowFormalDelivery = false,
    this.allowRecursiveDelegation = false,
    this.allowUserQuestions = false,
    this.allowLongTaskControl = false,
    this.reason = '',
    this.metadata = const <String, Object?>{},
  });

  final List<String> allowedToolIds;
  final List<String> blockedToolIds;
  final List<String> allowedSkillIds;
  final List<String> allowedSkillGroupIds;
  final bool allowFormalDelivery;
  final bool allowRecursiveDelegation;
  final bool allowUserQuestions;
  final bool allowLongTaskControl;
  final String reason;
  final JsonMap metadata;

  factory ChildExecutionPermissionContract.fromJson(JsonMap json) {
    return ChildExecutionPermissionContract(
      allowedToolIds: ValueReaders.stringList(json['allowed_tool_ids']),
      blockedToolIds: ValueReaders.stringList(json['blocked_tool_ids']),
      allowedSkillIds: ValueReaders.stringList(json['allowed_skill_ids']),
      allowedSkillGroupIds: ValueReaders.stringList(
        json['allowed_skill_group_ids'],
      ),
      allowFormalDelivery: ValueReaders.boolValue(
        json['allow_formal_delivery'],
      ),
      allowRecursiveDelegation: ValueReaders.boolValue(
        json['allow_recursive_delegation'],
      ),
      allowUserQuestions: ValueReaders.boolValue(json['allow_user_questions']),
      allowLongTaskControl: ValueReaders.boolValue(
        json['allow_long_task_control'],
      ),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'allowed_tool_ids': allowedToolIds,
      'blocked_tool_ids': blockedToolIds,
      'allowed_skill_ids': allowedSkillIds,
      'allowed_skill_group_ids': allowedSkillGroupIds,
      'allow_formal_delivery': allowFormalDelivery,
      'allow_recursive_delegation': allowRecursiveDelegation,
      'allow_user_questions': allowUserQuestions,
      'allow_long_task_control': allowLongTaskControl,
      'reason': reason,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (allowedToolIds.isNotEmpty &&
        allowedToolIds.any(blockedToolIds.contains)) {
      result.add('conflicting_child_execution_allowed_blocked_tools');
    }
    if (allowFormalDelivery &&
        blockedToolIds.contains('submit_chapter_delivery')) {
      result.add('conflicting_child_execution_formal_delivery_policy');
    }
    if (allowRecursiveDelegation && blockedToolIds.contains('call_sub_agent')) {
      result.add('conflicting_child_execution_recursive_policy');
    }
    if (allowUserQuestions && blockedToolIds.contains('present_user_options')) {
      result.add('conflicting_child_execution_user_question_policy');
    }
    return result;
  }
}

class ChildExecutionModelContract {
  const ChildExecutionModelContract({
    this.requestedModelId = '',
    this.providerProfile = '',
    this.thinkingSupported = true,
    this.thinkingEnabled = false,
    this.thinkingEffort = '',
    this.temperature,
    this.topP,
    this.topK,
    this.advancedModelOverrides = const <Object?>[],
    this.metadata = const <String, Object?>{},
  });

  final String requestedModelId;
  final String providerProfile;
  final bool thinkingSupported;
  final bool thinkingEnabled;
  final String thinkingEffort;
  final double? temperature;
  final double? topP;
  final int? topK;
  final List<Object?> advancedModelOverrides;
  final JsonMap metadata;

  factory ChildExecutionModelContract.fromJson(JsonMap json) {
    return ChildExecutionModelContract(
      requestedModelId: ValueReaders.stringValue(
        json['requested_model_id'],
      ).trim(),
      providerProfile: ValueReaders.stringValue(
        json['provider_profile'],
      ).trim(),
      thinkingSupported: ValueReaders.boolValue(
        json['thinking_supported'],
        true,
      ),
      thinkingEnabled: ValueReaders.boolValue(json['thinking_enabled']),
      thinkingEffort: ValueReaders.stringValue(json['thinking_effort']).trim(),
      temperature: json['temperature'] == null
          ? null
          : ValueReaders.doubleValue(json['temperature']),
      topP: json['top_p'] == null
          ? null
          : ValueReaders.doubleValue(json['top_p']),
      topK: json['top_k'] == null ? null : ValueReaders.intValue(json['top_k']),
      advancedModelOverrides: ValueReaders.deepCopyList(
        ValueReaders.objectList(json['advanced_model_overrides']),
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'requested_model_id': requestedModelId,
      'provider_profile': providerProfile,
      'thinking_supported': thinkingSupported,
      'thinking_enabled': thinkingEnabled,
      'thinking_effort': thinkingEffort,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (topK != null) 'top_k': topK,
      'advanced_model_overrides': ValueReaders.deepCopyList(
        advancedModelOverrides,
      ),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (providerProfile.trim().isEmpty) {
      result.add('missing_child_execution_model_provider_profile');
    }
    return result;
  }
}

class ChildExecutionBudgetContract {
  const ChildExecutionBudgetContract({
    this.maxConcurrentChildren = 1,
    this.tokenBudget = 0,
    this.maxRetryCount = 0,
    this.maxToolRounds = 0,
    this.timeoutSeconds = 0,
    this.contextBudgetChars = 0,
    this.outputBudgetChars = 0,
    this.sourcePathCount = 0,
    this.metadata = const <String, Object?>{},
  });

  final int maxConcurrentChildren;
  final int tokenBudget;
  final int maxRetryCount;
  final int maxToolRounds;
  final int timeoutSeconds;
  final int contextBudgetChars;
  final int outputBudgetChars;
  final int sourcePathCount;
  final JsonMap metadata;

  factory ChildExecutionBudgetContract.fromJson(JsonMap json) {
    return ChildExecutionBudgetContract(
      maxConcurrentChildren: ValueReaders.intValue(
        json['max_concurrent_children'],
        1,
      ),
      tokenBudget: ValueReaders.intValue(json['token_budget']),
      maxRetryCount: ValueReaders.intValue(json['max_retry_count']),
      maxToolRounds: ValueReaders.intValue(json['max_tool_rounds']),
      timeoutSeconds: ValueReaders.intValue(json['timeout_seconds']),
      contextBudgetChars: ValueReaders.intValue(json['context_budget_chars']),
      outputBudgetChars: ValueReaders.intValue(json['output_budget_chars']),
      sourcePathCount: ValueReaders.intValue(json['source_path_count']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'max_concurrent_children': maxConcurrentChildren,
      'token_budget': tokenBudget,
      'max_retry_count': maxRetryCount,
      'max_tool_rounds': maxToolRounds,
      'timeout_seconds': timeoutSeconds,
      'context_budget_chars': contextBudgetChars,
      'output_budget_chars': outputBudgetChars,
      'source_path_count': sourcePathCount,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (maxConcurrentChildren <= 0) {
      result.add('invalid_child_execution_budget_concurrency');
    }
    if (tokenBudget < 0 || maxRetryCount < 0) {
      result.add('invalid_child_execution_budget_retry_values');
    }
    if (maxToolRounds <= 0) {
      result.add('invalid_child_execution_budget_tool_rounds');
    }
    if (timeoutSeconds <= 0) {
      result.add('invalid_child_execution_budget_timeout');
    }
    if (contextBudgetChars < 0 ||
        outputBudgetChars < 0 ||
        sourcePathCount < 0) {
      result.add('invalid_child_execution_budget_values');
    }
    return result;
  }
}

class ChildExecutionFailurePolicyContract {
  const ChildExecutionFailurePolicyContract({
    this.onToolError = '',
    this.onWaitingUser = '',
    this.onModelFailure = '',
    this.onTimeout = '',
    this.onEmptyResult = '',
    this.onBudgetExceeded = '',
    this.retryableModelFailure = true,
    this.returnPartialResult = true,
    this.failToMainAgent = true,
    this.metadata = const <String, Object?>{},
  });

  final String onToolError;
  final String onWaitingUser;
  final String onModelFailure;
  final String onTimeout;
  final String onEmptyResult;
  final String onBudgetExceeded;
  final bool retryableModelFailure;
  final bool returnPartialResult;
  final bool failToMainAgent;
  final JsonMap metadata;

  factory ChildExecutionFailurePolicyContract.fromJson(JsonMap json) {
    return ChildExecutionFailurePolicyContract(
      onToolError: ValueReaders.stringValue(json['on_tool_error']).trim(),
      onWaitingUser: ValueReaders.stringValue(json['on_waiting_user']).trim(),
      onModelFailure: ValueReaders.stringValue(json['on_model_failure']).trim(),
      onTimeout: ValueReaders.stringValue(json['on_timeout']).trim(),
      onEmptyResult: ValueReaders.stringValue(json['on_empty_result']).trim(),
      onBudgetExceeded: ValueReaders.stringValue(
        json['on_budget_exceeded'],
      ).trim(),
      retryableModelFailure: ValueReaders.boolValue(
        json['retryable_model_failure'],
        true,
      ),
      returnPartialResult: ValueReaders.boolValue(
        json['return_partial_result'],
        true,
      ),
      failToMainAgent: ValueReaders.boolValue(json['fail_to_main_agent'], true),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'on_tool_error': onToolError,
      'on_waiting_user': onWaitingUser,
      'on_model_failure': onModelFailure,
      'on_timeout': onTimeout,
      'on_empty_result': onEmptyResult,
      'on_budget_exceeded': onBudgetExceeded,
      'retryable_model_failure': retryableModelFailure,
      'return_partial_result': returnPartialResult,
      'fail_to_main_agent': failToMainAgent,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (onToolError.trim().isEmpty ||
        onWaitingUser.trim().isEmpty ||
        onModelFailure.trim().isEmpty ||
        onTimeout.trim().isEmpty ||
        onEmptyResult.trim().isEmpty ||
        onBudgetExceeded.trim().isEmpty) {
      result.add('missing_child_execution_failure_policy');
    }
    for (final disposition in <String>[
      onToolError,
      onWaitingUser,
      onModelFailure,
      onTimeout,
      onEmptyResult,
      onBudgetExceeded,
    ]) {
      if (disposition.trim().isNotEmpty &&
          !ChildFailureDispositions.isKnown(disposition)) {
        result.add('invalid_child_execution_failure_disposition');
        break;
      }
    }
    return result;
  }
}

class ChildSkillLoadoutContract {
  const ChildSkillLoadoutContract({
    this.agentId = '',
    this.profileSkillIds = const <String>[],
    this.profileSkillGroupIds = const <String>[],
    this.selectedDirectSkillIds = const <String>[],
    this.selectedSkillGroupIds = const <String>[],
    this.disabledSkillIds = const <String>[],
    this.finalSkillIds = const <String>[],
    this.finalSkillGroupIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String agentId;
  final List<String> profileSkillIds;
  final List<String> profileSkillGroupIds;
  final List<String> selectedDirectSkillIds;
  final List<String> selectedSkillGroupIds;
  final List<String> disabledSkillIds;
  final List<String> finalSkillIds;
  final List<String> finalSkillGroupIds;
  final JsonMap metadata;

  factory ChildSkillLoadoutContract.fromResolved(
    ResolvedAgentSkillLoadout loadout,
  ) {
    final finalSkillIds = <String>[
      ...loadout.profileSkillIds,
      ...loadout.selectedDirectSkillIds,
    ]..removeWhere(loadout.disabledSkillIds.contains);
    final finalSkillGroups = <String>[
      ...loadout.profileSkillGroupIds,
      ...loadout.selectedSkillGroupIds,
    ];
    return ChildSkillLoadoutContract(
      agentId: loadout.agentId,
      profileSkillIds: loadout.profileSkillIds,
      profileSkillGroupIds: loadout.profileSkillGroupIds,
      selectedDirectSkillIds: loadout.selectedDirectSkillIds,
      selectedSkillGroupIds: loadout.selectedSkillGroupIds,
      disabledSkillIds: loadout.disabledSkillIds,
      finalSkillIds: finalSkillIds.toSet().toList(growable: false),
      finalSkillGroupIds: finalSkillGroups.toSet().toList(growable: false),
      metadata: ValueReaders.deepCopyMap(loadout.metadata),
    );
  }

  factory ChildSkillLoadoutContract.fromJson(JsonMap json) {
    return ChildSkillLoadoutContract(
      agentId: ValueReaders.stringValue(json['agent_id']).trim(),
      profileSkillIds: ValueReaders.stringList(json['profile_skill_ids']),
      profileSkillGroupIds: ValueReaders.stringList(
        json['profile_skill_group_ids'],
      ),
      selectedDirectSkillIds: ValueReaders.stringList(
        json['selected_direct_skill_ids'],
      ),
      selectedSkillGroupIds: ValueReaders.stringList(
        json['selected_skill_group_ids'],
      ),
      disabledSkillIds: ValueReaders.stringList(json['disabled_skill_ids']),
      finalSkillIds: ValueReaders.stringList(json['final_skill_ids']),
      finalSkillGroupIds: ValueReaders.stringList(
        json['final_skill_group_ids'],
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'agent_id': agentId,
      'profile_skill_ids': profileSkillIds,
      'profile_skill_group_ids': profileSkillGroupIds,
      'selected_direct_skill_ids': selectedDirectSkillIds,
      'selected_skill_group_ids': selectedSkillGroupIds,
      'disabled_skill_ids': disabledSkillIds,
      'final_skill_ids': finalSkillIds,
      'final_skill_group_ids': finalSkillGroupIds,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (agentId.trim().isEmpty) {
      result.add('missing_child_skill_loadout_agent_id');
    }
    return result;
  }
}

class CollaborationMergeContract {
  const CollaborationMergeContract({
    this.mergeMode = '',
    this.parentReviewRequired = true,
    this.allowsDirectDelivery = false,
    this.acceptedResultTypes = const <String>[],
    this.relationToWritingExecutionResult = '',
    this.metadata = const <String, Object?>{},
  });

  final String mergeMode;
  final bool parentReviewRequired;
  final bool allowsDirectDelivery;
  final List<String> acceptedResultTypes;
  final String relationToWritingExecutionResult;
  final JsonMap metadata;

  factory CollaborationMergeContract.fromJson(JsonMap json) {
    return CollaborationMergeContract(
      mergeMode: ValueReaders.stringValue(json['merge_mode']).trim(),
      parentReviewRequired: ValueReaders.boolValue(
        json['parent_review_required'],
        true,
      ),
      allowsDirectDelivery: ValueReaders.boolValue(
        json['allows_direct_delivery'],
      ),
      acceptedResultTypes: ValueReaders.stringList(
        json['accepted_result_types'],
      ),
      relationToWritingExecutionResult: ValueReaders.stringValue(
        json['relation_to_writing_execution_result'],
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'merge_mode': mergeMode,
      'parent_review_required': parentReviewRequired,
      'allows_direct_delivery': allowsDirectDelivery,
      'accepted_result_types': acceptedResultTypes,
      'relation_to_writing_execution_result': relationToWritingExecutionResult,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (mergeMode.trim().isEmpty) {
      result.add('missing_collaboration_merge_mode');
    }
    if (relationToWritingExecutionResult.trim().isEmpty) {
      result.add('missing_collaboration_result_relation');
    }
    return result;
  }
}
