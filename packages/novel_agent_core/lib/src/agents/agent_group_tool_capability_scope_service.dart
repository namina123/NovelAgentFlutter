import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../tools/tool_capability_family_catalog_service.dart';
import 'agent_task_family.dart';

class AgentGroupToolCapabilityScopeService {
  const AgentGroupToolCapabilityScopeService();

  List<String> resolveSupportedCapabilityFamilyIds(JsonMap group) {
    final metadata = ValueReaders.mapValue(group['metadata']);
    final explicitFamilies = <String>{
      ...ValueReaders.stringList(group['tool_capability_family_ids']),
      ...ValueReaders.stringList(group['tool_capability_families']),
      ...ValueReaders.stringList(metadata['tool_capability_family_ids']),
      ...ValueReaders.stringList(metadata['tool_capability_families']),
    };
    if (explicitFamilies.isNotEmpty) {
      return explicitFamilies.toList(growable: false);
    }

    final taskFamilies = <String>{
      ...ValueReaders.stringList(group['task_family_ids']),
      ...ValueReaders.stringList(group['task_families']),
      ...ValueReaders.stringList(metadata['task_family_ids']),
      ...ValueReaders.stringList(metadata['task_families']),
    };
    if (taskFamilies.contains(AgentTaskFamilies.referenceExtraction) ||
        taskFamilies.contains(AgentTaskFamilies.research)) {
      return const <String>[
        ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
        ToolCapabilityFamilyCatalogService.review,
        ToolCapabilityFamilyCatalogService.research,
        ToolCapabilityFamilyCatalogService.referenceExtraction,
      ];
    }
    if (taskFamilies.contains(AgentTaskFamilies.writing)) {
      return const <String>[
        ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
        ToolCapabilityFamilyCatalogService.writing,
        ToolCapabilityFamilyCatalogService.review,
        ToolCapabilityFamilyCatalogService.research,
      ];
    }
    if (taskFamilies.contains(AgentTaskFamilies.review)) {
      return const <String>[
        ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
        ToolCapabilityFamilyCatalogService.review,
      ];
    }
    return const <String>[];
  }
}
