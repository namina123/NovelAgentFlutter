import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';

const _reviewAuthorityPolicyCodecService = OpenJsonContractCodecService();
const _reviewAuthorityPolicyValidatorService =
    OpenJsonStructureValidatorService();
const _reviewAuthorityPolicyKnownFields = <String>{
  'trigger_authority',
  'execution_authority',
  'scheduling_authority',
  'metadata',
};

abstract final class ReviewTriggerAuthorities {
  static const String agentGroupPolicy = 'agent_group_policy';
  static const String runtimeSupervisorPolicy =
      'runtime_supervisor_policy';

  static const List<String> knownValues = <String>[
    agentGroupPolicy,
    runtimeSupervisorPolicy,
  ];
}

abstract final class ReviewExecutionAuthorities {
  static const String reviewerSelectionPolicy = 'reviewer_selection_policy';

  static const List<String> knownValues = <String>[reviewerSelectionPolicy];
}

abstract final class ReviewSchedulingAuthorities {
  static const String workflowSupervisorPolicy = 'workflow_supervisor_policy';

  static const List<String> knownValues = <String>[workflowSupervisorPolicy];
}

abstract final class ReviewAuthorityPolicyValidationCodes {
  static const String missingTriggerAuthority =
      'missing_review_trigger_authority';
  static const String invalidTriggerAuthority =
      'invalid_review_trigger_authority';
  static const String missingExecutionAuthority =
      'missing_review_execution_authority';
  static const String invalidExecutionAuthority =
      'invalid_review_execution_authority';
  static const String missingSchedulingAuthority =
      'missing_review_scheduling_authority';
  static const String invalidSchedulingAuthority =
      'invalid_review_scheduling_authority';
}

class ReviewAuthorityPolicy {
  const ReviewAuthorityPolicy({
    this.triggerAuthority = ReviewTriggerAuthorities.agentGroupPolicy,
    this.executionAuthority =
        ReviewExecutionAuthorities.reviewerSelectionPolicy,
    this.schedulingAuthority =
        ReviewSchedulingAuthorities.workflowSupervisorPolicy,
    this.metadata = const <String, Object?>{},
  });

  const ReviewAuthorityPolicy.standardProject({
    this.metadata = const <String, Object?>{},
  }) : triggerAuthority = ReviewTriggerAuthorities.agentGroupPolicy,
       executionAuthority =
           ReviewExecutionAuthorities.reviewerSelectionPolicy,
       schedulingAuthority =
           ReviewSchedulingAuthorities.workflowSupervisorPolicy;

  const ReviewAuthorityPolicy.longTask({
    this.metadata = const <String, Object?>{},
  }) : triggerAuthority = ReviewTriggerAuthorities.runtimeSupervisorPolicy,
       executionAuthority =
           ReviewExecutionAuthorities.reviewerSelectionPolicy,
       schedulingAuthority =
           ReviewSchedulingAuthorities.workflowSupervisorPolicy;

  final String triggerAuthority;
  final String executionAuthority;
  final String schedulingAuthority;
  final JsonMap metadata;

  bool get isAgentGroupTriggered =>
      triggerAuthority == ReviewTriggerAuthorities.agentGroupPolicy;

  bool get isRuntimeSupervisorTriggered =>
      triggerAuthority == ReviewTriggerAuthorities.runtimeSupervisorPolicy;

  ReviewAuthorityPolicy copyWith({
    String? triggerAuthority,
    String? executionAuthority,
    String? schedulingAuthority,
    JsonMap? metadata,
  }) {
    // 中文注释: authority policy 会被普通项目与长任务共同消费，因此提供稳定 copy 入口供后续策略层扩展。
    return ReviewAuthorityPolicy(
      triggerAuthority: triggerAuthority ?? this.triggerAuthority,
      executionAuthority: executionAuthority ?? this.executionAuthority,
      schedulingAuthority: schedulingAuthority ?? this.schedulingAuthority,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ReviewAuthorityPolicy.fromJson(JsonMap json) {
    // 中文注释: open contract 保留未知字段，方便后续在不破坏当前权限语义的前提下增量扩展。
    return ReviewAuthorityPolicy(
      triggerAuthority: _readTriggerAuthority(json['trigger_authority']),
      executionAuthority: _readExecutionAuthority(json['execution_authority']),
      schedulingAuthority: _readSchedulingAuthority(
        json['scheduling_authority'],
      ),
      metadata: _reviewAuthorityPolicyCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _reviewAuthorityPolicyKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _reviewAuthorityPolicyCodecService.encodeWithUnknownFields(
      <String, Object?>{
        'trigger_authority': triggerAuthority,
        'execution_authority': executionAuthority,
        'scheduling_authority': schedulingAuthority,
      },
      metadata: metadata,
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _reviewAuthorityPolicyValidatorService.requireNonBlankString(
        triggerAuthority,
        ReviewAuthorityPolicyValidationCodes.missingTriggerAuthority,
      ),
    );
    if (!_isKnownValue(
      triggerAuthority,
      ReviewTriggerAuthorities.knownValues,
    )) {
      result.add(ReviewAuthorityPolicyValidationCodes.invalidTriggerAuthority);
    }
    result.addAll(
      _reviewAuthorityPolicyValidatorService.requireNonBlankString(
        executionAuthority,
        ReviewAuthorityPolicyValidationCodes.missingExecutionAuthority,
      ),
    );
    if (!_isKnownValue(
      executionAuthority,
      ReviewExecutionAuthorities.knownValues,
    )) {
      result.add(
        ReviewAuthorityPolicyValidationCodes.invalidExecutionAuthority,
      );
    }
    result.addAll(
      _reviewAuthorityPolicyValidatorService.requireNonBlankString(
        schedulingAuthority,
        ReviewAuthorityPolicyValidationCodes.missingSchedulingAuthority,
      ),
    );
    if (!_isKnownValue(
      schedulingAuthority,
      ReviewSchedulingAuthorities.knownValues,
    )) {
      result.add(
        ReviewAuthorityPolicyValidationCodes.invalidSchedulingAuthority,
      );
    }
    return result;
  }
}

String _readTriggerAuthority(Object? raw) {
  final value = ValueReaders.stringValue(raw).trim();
  return value.isEmpty
      ? ReviewTriggerAuthorities.agentGroupPolicy
      : value;
}

String _readExecutionAuthority(Object? raw) {
  final value = ValueReaders.stringValue(raw).trim();
  return value.isEmpty
      ? ReviewExecutionAuthorities.reviewerSelectionPolicy
      : value;
}

String _readSchedulingAuthority(Object? raw) {
  final value = ValueReaders.stringValue(raw).trim();
  return value.isEmpty
      ? ReviewSchedulingAuthorities.workflowSupervisorPolicy
      : value;
}

bool _isKnownValue(String value, List<String> knownValues) {
  return value.trim().isNotEmpty && knownValues.contains(value.trim());
}
