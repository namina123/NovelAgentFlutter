import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../review/reviewer_selection.dart';
import '../workflow/continuous_task_tool_exposure_runtime_resolution.dart';

class AgentCollaborationContract {
  const AgentCollaborationContract({
    required this.exposureResolution,
    required this.toolVisibility,
    required this.delegation,
    required this.reviewer,
  });

  final ContinuousTaskToolExposureRuntimeResolution exposureResolution;
  final AgentToolVisibilityContract toolVisibility;
  final AgentDelegationContract delegation;
  final AgentReviewerDispatchContract reviewer;

  JsonMap toJson() {
    return <String, Object?>{
      'exposure_resolution': exposureResolution.toJson(),
      'tool_visibility': toolVisibility.toJson(),
      'delegation': delegation.toJson(),
      'reviewer': reviewer.toJson(),
    };
  }
}

class AgentToolVisibilityContract {
  const AgentToolVisibilityContract({
    required this.visibleToolIds,
    required this.defaultAllowedToolIds,
    required this.requiresConfirmationToolIds,
    required this.interactionHintToolIds,
    required this.delegationAllowed,
  });

  final List<String> visibleToolIds;
  final List<String> defaultAllowedToolIds;
  final List<String> requiresConfirmationToolIds;
  final List<String> interactionHintToolIds;
  final bool delegationAllowed;

  bool get promptsUserChoice {
    return interactionHintToolIds.contains('present_user_options');
  }

  JsonMap toJson() {
    return <String, Object?>{
      'visible_tool_ids': List<String>.from(visibleToolIds),
      'default_allowed_tool_ids': List<String>.from(defaultAllowedToolIds),
      'requires_confirmation_tool_ids': List<String>.from(
        requiresConfirmationToolIds,
      ),
      'interaction_hint_tool_ids': List<String>.from(interactionHintToolIds),
      'delegation_allowed': delegationAllowed,
      'prompts_user_choice': promptsUserChoice,
    };
  }
}

class AgentDelegationContract {
  const AgentDelegationContract({
    required this.allowed,
    required this.childAgentIds,
    required this.primaryAgentId,
    required this.rationale,
    this.selectedAgentId = '',
  });

  final bool allowed;
  final List<String> childAgentIds;
  final String primaryAgentId;
  final String rationale;
  final String selectedAgentId;

  JsonMap toJson() {
    return <String, Object?>{
      'allowed': allowed,
      'child_agent_ids': List<String>.from(childAgentIds),
      'primary_agent_id': primaryAgentId,
      'selected_agent_id': selectedAgentId,
      'rationale': rationale,
    };
  }
}

class AgentReviewerDispatchContract {
  const AgentReviewerDispatchContract({
    required this.applicable,
    required this.shouldDelegate,
    required this.executionMode,
    required this.selectionMode,
    required this.selectionRationale,
    required this.agentId,
    required this.agentName,
    required this.agentRole,
    required this.groupId,
    required this.groupName,
    required this.groupMemberIds,
  });

  final bool applicable;
  final bool shouldDelegate;
  final String executionMode;
  final String selectionMode;
  final String selectionRationale;
  final String agentId;
  final String agentName;
  final String agentRole;
  final String groupId;
  final String groupName;
  final List<String> groupMemberIds;

  bool get hasDedicatedReviewer =>
      selectionMode == ReviewerSelectionModes.delegatedReviewer ||
      selectionMode == ReviewerSelectionModes.delegatedCriticOrEditor;

  bool get hasReviewerGroup => groupId.trim().isNotEmpty;

  JsonMap toJson() {
    return <String, Object?>{
      'applicable': applicable,
      'should_delegate': shouldDelegate,
      'review_execution_mode': executionMode,
      'selection_mode': selectionMode,
      'selection_rationale': selectionRationale,
      'agent_id': agentId,
      'agent_name': agentName,
      'agent_role': agentRole,
      'group_id': groupId,
      'group_name': groupName,
      'group_member_ids': List<String>.from(groupMemberIds),
    };
  }

  static AgentReviewerDispatchContract fromJson(JsonMap json) {
    return AgentReviewerDispatchContract(
      applicable: ValueReaders.boolValue(json['applicable']),
      shouldDelegate: ValueReaders.boolValue(json['should_delegate']),
      executionMode: ValueReaders.stringValue(
        json['review_execution_mode'],
      ).trim(),
      selectionMode: ValueReaders.stringValue(json['selection_mode']).trim(),
      selectionRationale: ValueReaders.stringValue(
        json['selection_rationale'],
      ).trim(),
      agentId: ValueReaders.stringValue(json['agent_id']).trim(),
      agentName: ValueReaders.stringValue(json['agent_name']).trim(),
      agentRole: ValueReaders.stringValue(json['agent_role']).trim(),
      groupId: ValueReaders.stringValue(json['group_id']).trim(),
      groupName: ValueReaders.stringValue(json['group_name']).trim(),
      groupMemberIds: ValueReaders.stringList(json['group_member_ids']),
    );
  }
}
