import 'package:novel_agent_core/novel_agent_core.dart';

typedef LoadProjectAgentGroupSelections =
    Future<List<ProjectAgentGroupSelection>> Function(
      ProjectDescriptor project,
    );
typedef SaveProjectAgentGroupSelections =
    Future<void> Function(
      ProjectDescriptor project,
      List<ProjectAgentGroupSelection> selections,
    );

class ProjectOpeningAgentGroupBindingService {
  ProjectOpeningAgentGroupBindingService({
    required LoadProjectAgentGroupSelections loadSelections,
    required SaveProjectAgentGroupSelections saveSelections,
  }) : _loadSelections = loadSelections,
       _saveSelections = saveSelections;

  final LoadProjectAgentGroupSelections _loadSelections;
  final SaveProjectAgentGroupSelections _saveSelections;

  Future<void> selectProjectDefaultGroup({
    required ProjectDescriptor project,
    required String groupId,
    String displayName = '',
  }) async {
    // 中文注释: 开局面板只修改项目级默认 group 绑定，不介入 mode/stage scoped 选择和 catalog 规则。
    final cleanGroupId = groupId.trim();
    if (cleanGroupId.isEmpty) {
      return;
    }
    final existingSelections = await _loadSelections(project);
    final nextSelections = _mergeSelections(
      existingSelections,
      groupId: cleanGroupId,
      displayName: displayName.trim(),
    );
    await _saveSelections(project, nextSelections);
  }

  List<ProjectAgentGroupSelection> _mergeSelections(
    List<ProjectAgentGroupSelection> existingSelections, {
    required String groupId,
    required String displayName,
  }) {
    // 中文注释: 默认组切换只收束未分 scope 的项目级条目，其他 scoped 选择保持原样。
    final nextSelections = <ProjectAgentGroupSelection>[];
    var targetInserted = false;
    for (final selection in existingSelections) {
      final isProjectLevel =
          selection.modeIds.isEmpty && selection.stageIds.isEmpty;
      if (!isProjectLevel) {
        nextSelections.add(selection);
        continue;
      }
      if (selection.groupId == groupId) {
        if (targetInserted) {
          continue;
        }
        nextSelections.add(
          ProjectAgentGroupSelection(
            groupId: selection.groupId,
            displayName: displayName.isEmpty
                ? selection.displayName
                : displayName,
            enabled: true,
            selectedByDefault: true,
            modeIds: selection.modeIds,
            stageIds: selection.stageIds,
            metadata: selection.metadata,
          ),
        );
        targetInserted = true;
        continue;
      }
      nextSelections.add(
        ProjectAgentGroupSelection(
          groupId: selection.groupId,
          displayName: selection.displayName,
          enabled: selection.enabled,
          selectedByDefault: false,
          modeIds: selection.modeIds,
          stageIds: selection.stageIds,
          metadata: selection.metadata,
        ),
      );
    }
    if (!targetInserted) {
      nextSelections.add(
        ProjectAgentGroupSelection(
          groupId: groupId,
          displayName: displayName,
          enabled: true,
          selectedByDefault: true,
          metadata: const <String, Object?>{
            'source': 'opening_agent_group_picker',
          },
        ),
      );
    }
    return nextSelections;
  }
}
