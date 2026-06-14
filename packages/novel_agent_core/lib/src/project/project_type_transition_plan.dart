import 'project_storage_strategy.dart';
import 'project_type_definition.dart';
import 'project_type_transition_blocker.dart';
import 'project_type_transition_request.dart';

class ProjectTypeTransitionPlan {
  const ProjectTypeTransitionPlan({
    required this.request,
    required this.sourceProjectTypeDefinition,
    required this.targetProjectTypeDefinition,
    required this.availableTargetProjectTypeIds,
    required this.targetStorageStrategy,
    required this.targetRuntimeBaselineId,
    required this.requiresRuntimeBaselineSelection,
    required this.blockers,
  });

  final ProjectTypeTransitionRequest request;
  final ProjectTypeDefinition? sourceProjectTypeDefinition;
  final ProjectTypeDefinition? targetProjectTypeDefinition;
  final List<String> availableTargetProjectTypeIds;
  final ProjectStorageStrategy targetStorageStrategy;
  final String targetRuntimeBaselineId;
  final bool requiresRuntimeBaselineSelection;
  final List<ProjectTypeTransitionBlocker> blockers;

  bool get canTransition {
    // 中文注释: 转换计划只要没有阻断原因，就视为可进入下一步收口。
    return blockers.isEmpty;
  }

  bool get preservesStorageStrategy {
    // 中文注释: 第一阶段只允许同存储策略内的类型转换，所以这里直接暴露是否保持原策略不变。
    return request.storageStrategy == targetStorageStrategy;
  }

  bool get requiresLongTaskArchiveCheck {
    // 中文注释: 长篇长任务回切普通小说时，必须能显式看见“先归档活跃长任务”这条约束。
    return request.sourceProjectTypeId.trim() == 'long_novel' &&
        request.targetProjectTypeId.trim() == 'novel';
  }
}
