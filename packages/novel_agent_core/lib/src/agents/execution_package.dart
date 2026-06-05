import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'sub_agent_contract_components.dart';

class ChildRunOutline {
  const ChildRunOutline({
    this.childRunPackageId = '',
    this.agentId = '',
    this.agentName = '',
    this.agentRole = '',
    this.task = '',
    this.expectedOutput = '',
    this.skills = const <String>[],
    this.skillGroups = const <String>[],
    this.isPrimary = false,
    this.isRequired = false,
    this.selected = false,
    this.status = '',
    this.metadata = const <String, Object?>{},
  });

  final String childRunPackageId;
  final String agentId;
  final String agentName;
  final String agentRole;
  final String task;
  final String expectedOutput;
  final List<String> skills;
  final List<String> skillGroups;
  final bool isPrimary;
  final bool isRequired;
  final bool selected;
  final String status;
  final JsonMap metadata;

  factory ChildRunOutline.fromJson(JsonMap json) {
    return ChildRunOutline(
      childRunPackageId: ValueReaders.stringValue(
        json['child_run_package_id'],
      ).trim(),
      agentId: ValueReaders.stringValue(json['agent_id']).trim(),
      agentName: ValueReaders.stringValue(json['agent_name']).trim(),
      agentRole: ValueReaders.stringValue(json['agent_role']).trim(),
      task: ValueReaders.stringValue(json['task']).trim(),
      expectedOutput: ValueReaders.stringValue(json['expected_output']).trim(),
      skills: ValueReaders.stringList(json['skills']),
      skillGroups: ValueReaders.stringList(json['skill_groups']),
      isPrimary: ValueReaders.boolValue(json['is_primary']),
      isRequired: ValueReaders.boolValue(json['is_required']),
      selected: ValueReaders.boolValue(json['selected']),
      status: ValueReaders.stringValue(json['status']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'child_run_package_id': childRunPackageId,
      'agent_id': agentId,
      'agent_name': agentName,
      'agent_role': agentRole,
      'task': task,
      'expected_output': expectedOutput,
      'skills': skills,
      'skill_groups': skillGroups,
      'is_primary': isPrimary,
      'is_required': isRequired,
      'selected': selected,
      'status': status,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (childRunPackageId.trim().isEmpty) {
      result.add('missing_child_run_outline_package_id');
    }
    if (agentId.trim().isEmpty) {
      result.add('missing_child_run_outline_agent_id');
    }
    if (task.trim().isEmpty) {
      result.add('missing_child_run_outline_task');
    }
    return result;
  }
}

class ExecutionPackage {
  const ExecutionPackage({
    this.packageId = '',
    this.strategy = '',
    this.groupId = '',
    this.groupName = '',
    this.orchestration = '',
    this.parentAgentId = '',
    this.parentAgentName = '',
    this.goal = const AgentExecutionGoalContract(),
    this.context = const AgentExecutionContextContract(),
    this.failurePolicy = const ChildExecutionFailurePolicyContract(),
    this.children = const <ChildRunOutline>[],
    this.responseContract = '',
    this.metadata = const <String, Object?>{},
  });

  final String packageId;
  final String strategy;
  final String groupId;
  final String groupName;
  final String orchestration;
  final String parentAgentId;
  final String parentAgentName;
  final AgentExecutionGoalContract goal;
  final AgentExecutionContextContract context;
  final ChildExecutionFailurePolicyContract failurePolicy;
  final List<ChildRunOutline> children;
  final String responseContract;
  final JsonMap metadata;

  factory ExecutionPackage.fromJson(JsonMap json) {
    return ExecutionPackage(
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      strategy: ValueReaders.stringValue(json['strategy']).trim(),
      groupId: ValueReaders.stringValue(json['group_id']).trim(),
      groupName: ValueReaders.stringValue(json['group_name']).trim(),
      orchestration: ValueReaders.stringValue(json['orchestration']).trim(),
      parentAgentId: ValueReaders.stringValue(json['parent_agent_id']).trim(),
      parentAgentName: ValueReaders.stringValue(
        json['parent_agent_name'],
      ).trim(),
      goal: AgentExecutionGoalContract.fromJson(
        ValueReaders.mapValue(json['goal']),
      ),
      context: AgentExecutionContextContract.fromJson(
        ValueReaders.mapValue(json['context']),
      ),
      failurePolicy: ChildExecutionFailurePolicyContract.fromJson(
        ValueReaders.mapValue(json['failure_policy']),
      ),
      children: ValueReaders.mapList(
        json['children'],
      ).map(ChildRunOutline.fromJson).toList(growable: false),
      responseContract: ValueReaders.stringValue(
        json['response_contract'],
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'package_id': packageId,
      'strategy': strategy,
      'group_id': groupId,
      'group_name': groupName,
      'orchestration': orchestration,
      'parent_agent_id': parentAgentId,
      'parent_agent_name': parentAgentName,
      'goal': goal.toJson(),
      'context': context.toJson(),
      'failure_policy': failurePolicy.toJson(),
      'children': children
          .map((child) => child.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'response_contract': responseContract,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (packageId.trim().isEmpty) {
      result.add('missing_execution_package_id');
    }
    if (strategy.trim().isEmpty) {
      result.add('missing_execution_package_strategy');
    }
    if (groupId.trim().isEmpty) {
      result.add('missing_execution_package_group_id');
    }
    result.addAll(goal.validateBasics());
    result.addAll(context.validateBasics());
    result.addAll(failurePolicy.validateBasics());
    for (final child in children) {
      result.addAll(child.validateBasics());
    }
    if (children.isEmpty) {
      result.add('missing_execution_package_children');
    }
    if (responseContract.trim().isEmpty) {
      result.add('missing_execution_package_response_contract');
    }
    return result;
  }
}
