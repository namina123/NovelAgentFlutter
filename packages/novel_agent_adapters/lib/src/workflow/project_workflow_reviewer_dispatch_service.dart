import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectWorkflowReviewerDispatchService {
  ProjectWorkflowReviewerDispatchService({
    AgentCollaborationContractService? collaborationContractService,
  }) : _collaborationContractService =
           collaborationContractService ?? AgentCollaborationContractService();

  final AgentCollaborationContractService _collaborationContractService;

  JsonMap resolve({
    required JsonMap task,
    required JsonMap mainAgent,
    required JsonMap selectedCollaborationGroup,
    required List<JsonMap> availableAgents,
    required List<JsonMap> availableGroups,
  }) {
    final collaborationContract = _collaborationContractService.resolve(
      candidateToolIds: const <String>[],
      selectedCollaborationGroup: selectedCollaborationGroup,
      runtimeContext: <String, Object?>{
        'task_type': ValueReaders.stringValue(task['task_type']),
      },
      intent: ValueReaders.stringValue(task['task_type']),
      mainAgent: mainAgent,
      availableAgents: availableAgents,
      availableGroups: availableGroups,
    );
    return collaborationContract.reviewer.toJson();
  }
}
