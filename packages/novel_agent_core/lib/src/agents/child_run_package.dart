import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'sub_agent_contract_components.dart';

class ChildRunPackage {
  const ChildRunPackage({
    this.packageId = '',
    this.executionPackageId = '',
    this.subSessionId = '',
    this.continueSessionId = '',
    this.strategy = '',
    this.groupId = '',
    this.groupName = '',
    this.agentId = '',
    this.agentName = '',
    this.agentRole = '',
    this.goal = const AgentExecutionGoalContract(),
    this.context = const AgentExecutionContextContract(),
    this.skillLoadout = const ChildSkillLoadoutContract(),
    this.permissionPolicy = const ChildExecutionPermissionContract(),
    this.modelPolicy = const ChildExecutionModelContract(),
    this.budgetPolicy = const ChildExecutionBudgetContract(),
    this.failurePolicy = const ChildExecutionFailurePolicyContract(),
    this.messages = const <JsonMap>[],
    this.responseContract = '',
    this.metadata = const <String, Object?>{},
  });

  final String packageId;
  final String executionPackageId;
  final String subSessionId;
  final String continueSessionId;
  final String strategy;
  final String groupId;
  final String groupName;
  final String agentId;
  final String agentName;
  final String agentRole;
  final AgentExecutionGoalContract goal;
  final AgentExecutionContextContract context;
  final ChildSkillLoadoutContract skillLoadout;
  final ChildExecutionPermissionContract permissionPolicy;
  final ChildExecutionModelContract modelPolicy;
  final ChildExecutionBudgetContract budgetPolicy;
  final ChildExecutionFailurePolicyContract failurePolicy;
  final List<JsonMap> messages;
  final String responseContract;
  final JsonMap metadata;

  factory ChildRunPackage.fromJson(JsonMap json) {
    return ChildRunPackage(
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      executionPackageId: ValueReaders.stringValue(
        json['execution_package_id'],
      ).trim(),
      subSessionId: ValueReaders.stringValue(json['sub_session_id']).trim(),
      continueSessionId: ValueReaders.stringValue(
        json['continue_session_id'],
      ).trim(),
      strategy: ValueReaders.stringValue(json['strategy']).trim(),
      groupId: ValueReaders.stringValue(json['group_id']).trim(),
      groupName: ValueReaders.stringValue(json['group_name']).trim(),
      agentId: ValueReaders.stringValue(json['agent_id']).trim(),
      agentName: ValueReaders.stringValue(json['agent_name']).trim(),
      agentRole: ValueReaders.stringValue(json['agent_role']).trim(),
      goal: AgentExecutionGoalContract.fromJson(
        ValueReaders.mapValue(json['goal']),
      ),
      context: AgentExecutionContextContract.fromJson(
        ValueReaders.mapValue(json['context']),
      ),
      skillLoadout: ChildSkillLoadoutContract.fromJson(
        ValueReaders.mapValue(json['skill_loadout']),
      ),
      permissionPolicy: ChildExecutionPermissionContract.fromJson(
        ValueReaders.mapValue(json['permission_policy']),
      ),
      modelPolicy: ChildExecutionModelContract.fromJson(
        ValueReaders.mapValue(json['model_policy']),
      ),
      budgetPolicy: ChildExecutionBudgetContract.fromJson(
        ValueReaders.mapValue(json['budget_policy']),
      ),
      failurePolicy: ChildExecutionFailurePolicyContract.fromJson(
        ValueReaders.mapValue(json['failure_policy']),
      ),
      messages: ValueReaders.mapList(
        json['messages'],
      ).map(ValueReaders.deepCopyMap).toList(growable: false),
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
      'execution_package_id': executionPackageId,
      'sub_session_id': subSessionId,
      'continue_session_id': continueSessionId,
      'strategy': strategy,
      'group_id': groupId,
      'group_name': groupName,
      'agent_id': agentId,
      'agent_name': agentName,
      'agent_role': agentRole,
      'goal': goal.toJson(),
      'context': context.toJson(),
      'skill_loadout': skillLoadout.toJson(),
      'permission_policy': permissionPolicy.toJson(),
      'model_policy': modelPolicy.toJson(),
      'budget_policy': budgetPolicy.toJson(),
      'failure_policy': failurePolicy.toJson(),
      'messages': messages
          .map(ValueReaders.deepCopyMap)
          .toList(growable: false),
      'response_contract': responseContract,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (packageId.trim().isEmpty) {
      result.add('missing_child_run_package_id');
    }
    if (executionPackageId.trim().isEmpty) {
      result.add('missing_child_run_execution_package_id');
    }
    if (agentId.trim().isEmpty) {
      result.add('missing_child_run_agent_id');
    }
    result.addAll(goal.validateBasics());
    result.addAll(context.validateBasics());
    result.addAll(skillLoadout.validateBasics());
    result.addAll(permissionPolicy.validateBasics());
    result.addAll(modelPolicy.validateBasics());
    result.addAll(budgetPolicy.validateBasics());
    result.addAll(failurePolicy.validateBasics());
    if (responseContract.trim().isEmpty) {
      result.add('missing_child_run_response_contract');
    }
    if (messages.isEmpty) {
      result.add('missing_child_run_messages');
    }
    return result;
  }
}
