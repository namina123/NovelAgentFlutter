import 'project_agent_group_selection.dart';

class ProjectAgentGroupSelectionResolverService {
  const ProjectAgentGroupSelectionResolverService();

  List<ProjectAgentGroupSelection> resolveActiveSelections(
    List<ProjectAgentGroupSelection> selections, {
    String taskFamilyId = '',
    String modeId = '',
    String stageId = '',
  }) {
    // 中文注释: 项目级 group 选择的 mode/stage 作用域统一从这里判断，避免后续 app 和 adapter 各自复制过滤规则。
    final cleanTaskFamilyId = taskFamilyId.trim();
    final result = <ProjectAgentGroupSelection>[];
    for (final selection in selections) {
      if (!selection.enabled) {
        continue;
      }
      if (!_matchesScope(selection.taskFamilyIds, cleanTaskFamilyId)) {
        continue;
      }
      if (!_matchesScope(selection.modeIds, modeId)) {
        continue;
      }
      if (!_matchesScope(selection.stageIds, stageId)) {
        continue;
      }
      result.add(selection);
    }
    result.sort((left, right) {
      if (cleanTaskFamilyId.isNotEmpty) {
        final leftSpecific = left.taskFamilyIds.contains(cleanTaskFamilyId);
        final rightSpecific = right.taskFamilyIds.contains(cleanTaskFamilyId);
        if (leftSpecific != rightSpecific) {
          return leftSpecific ? -1 : 1;
        }
      }
      if (left.selectedByDefault == right.selectedByDefault) {
        return left.groupId.compareTo(right.groupId);
      }
      return left.selectedByDefault ? -1 : 1;
    });
    return result;
  }

  ProjectAgentGroupSelection? resolvePreferredSelection(
    List<ProjectAgentGroupSelection> selections, {
    String taskFamilyId = '',
    String modeId = '',
    String stageId = '',
  }) {
    final active = resolveActiveSelections(
      selections,
      taskFamilyId: taskFamilyId,
      modeId: modeId,
      stageId: stageId,
    );
    if (active.isEmpty) {
      return null;
    }
    return active.first;
  }

  bool _matchesScope(List<String> scopedIds, String currentId) {
    if (scopedIds.isEmpty) {
      return true;
    }
    final cleanCurrentId = currentId.trim();
    if (cleanCurrentId.isEmpty) {
      return false;
    }
    return scopedIds.contains(cleanCurrentId);
  }
}
