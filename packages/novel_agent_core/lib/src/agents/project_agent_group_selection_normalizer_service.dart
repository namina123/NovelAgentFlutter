import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_agent_group_selection.dart';

class ProjectAgentGroupSelectionNormalizerService {
  const ProjectAgentGroupSelectionNormalizerService();

  ProjectAgentGroupSelection normalize(JsonMap raw) {
    // 中文注释: 项目级智能体组绑定文档只负责“当前项目选了什么组与作用域覆盖”，不夹带 catalog 规则。
    return ProjectAgentGroupSelection(
      groupId: ValueReaders.stringValue(raw['group_id'] ?? raw['id']).trim(),
      displayName: ValueReaders.stringValue(
        raw['display_name'] ?? raw['name'],
      ).trim(),
      enabled: ValueReaders.boolValue(raw['enabled'], true),
      selectedByDefault: ValueReaders.boolValue(
        raw['selected_by_default'] ?? raw['default'],
      ),
      taskFamilyIds: ValueReaders.stringList(
        raw['task_family_ids'] ?? raw['task_families'],
      ),
      modeIds: ValueReaders.stringList(raw['mode_ids'] ?? raw['modes']),
      stageIds: ValueReaders.stringList(raw['stage_ids'] ?? raw['stages']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(ProjectAgentGroupSelection selection) {
    return <String, Object?>{
      'group_id': selection.groupId,
      'display_name': selection.displayName,
      'enabled': selection.enabled,
      'selected_by_default': selection.selectedByDefault,
      'task_family_ids': ValueReaders.deepCopyList(
        selection.taskFamilyIds.cast<Object?>(),
      ),
      'mode_ids': ValueReaders.deepCopyList(selection.modeIds.cast<Object?>()),
      'stage_ids': ValueReaders.deepCopyList(
        selection.stageIds.cast<Object?>(),
      ),
      'metadata': ValueReaders.deepCopyMap(selection.metadata),
    };
  }
}
