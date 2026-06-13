import '../common/value_readers.dart';
import '../agents/agent_task_family.dart';
import '../agents/resolved_agent_group_profile.dart';

class ReferenceExtractionTaskFamilySupportService {
  const ReferenceExtractionTaskFamilySupportService();

  bool supportsReferenceExtraction(ResolvedAgentGroupProfile group) {
    final taskFamilyIds = <String>{
      ...ValueReaders.stringList(group.metadata['task_family_ids']),
      ...ValueReaders.stringList(group.metadata['task_families']),
      ...ValueReaders.stringList(group.metadata['capability_ids']),
    };
    return taskFamilyIds.contains(AgentTaskFamilies.referenceExtraction);
  }
}
