import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_assets_view_data.dart';

class ProjectExpressionConstraintBindingActionService {
  const ProjectExpressionConstraintBindingActionService();

  List<ProjectExpressionConstraintBinding> upsertBinding({
    required List<ProjectExpressionConstraintBinding> currentBindings,
    required ExpressionConstraintProfile profile,
    required ExpressionConstraintBindingEditorRequestViewData request,
  }) {
    // 中文注释: 编辑器请求只负责生成一条新的绑定快照，不在控制器里散落 CSV 和权重清洗逻辑。
    final existing = _bindingOf(currentBindings, profile.id);
    final nextBinding = ProjectExpressionConstraintBinding(
      id: existing?.id.trim().isNotEmpty == true ? existing!.id : profile.id,
      profileId: profile.id,
      displayName: profile.displayName,
      enabled: request.enabled,
      defaultForProject: request.defaultForProject,
      targetAgentIds: _selectedAgentIds(request),
      targetModeIds: _selectedModeIds(request),
      targetStageIds: _selectedStageIds(request),
      weight: _weightValue(
        request.weightText,
        fallback: existing?.weight ?? 100,
      ),
      metadata: Map<String, Object?>.from(
        existing?.metadata ?? const <String, Object?>{},
      ),
    );
    final nextBindings = <ProjectExpressionConstraintBinding>[
      for (final binding in currentBindings)
        if (binding.profileId != profile.id) binding,
      nextBinding,
    ];
    nextBindings.sort(
      (left, right) => left.profileId.compareTo(right.profileId),
    );
    return nextBindings;
  }

  List<ProjectExpressionConstraintBinding> removeBinding({
    required List<ProjectExpressionConstraintBinding> currentBindings,
    required String profileId,
  }) {
    // 中文注释: 移除绑定只影响当前 profile，不应顺手清掉其他表达限制的项目设置。
    final cleanProfileId = profileId.trim();
    return currentBindings
        .where((binding) => binding.profileId != cleanProfileId)
        .toList(growable: false);
  }

  ProjectExpressionConstraintBinding? _bindingOf(
    List<ProjectExpressionConstraintBinding> bindings,
    String profileId,
  ) {
    // 中文注释: 当前最小入口约定同一 profile 只维护一条项目级 binding，因此直接按 profileId 查找即可。
    final cleanProfileId = profileId.trim();
    for (final binding in bindings) {
      if (binding.profileId == cleanProfileId) {
        return binding;
      }
    }
    return null;
  }

  List<String> _selectedAgentIds(
    ExpressionConstraintBindingEditorRequestViewData request,
  ) {
    if (request.selectedAgentIds.isNotEmpty) {
      return _dedupedList(request.selectedAgentIds);
    }
    return _csvList(request.targetAgentIdsText);
  }

  List<String> _selectedModeIds(
    ExpressionConstraintBindingEditorRequestViewData request,
  ) {
    if (request.selectedModeIds.isNotEmpty) {
      return _dedupedList(request.selectedModeIds);
    }
    return _csvList(request.targetModeIdsText);
  }

  List<String> _selectedStageIds(
    ExpressionConstraintBindingEditorRequestViewData request,
  ) {
    if (request.selectedStageIds.isNotEmpty) {
      return _dedupedList(request.selectedStageIds);
    }
    return _csvList(request.targetStageIdsText);
  }

  List<String> _csvList(String rawText) {
    // 中文注释: 作用域字段先继续使用轻量逗号文本，后续若升级专门选择器也只需替换这一层解析入口。
    final result = <String>[];
    for (final item in rawText.split(',')) {
      final cleanItem = item.trim();
      if (cleanItem.isEmpty || result.contains(cleanItem)) {
        continue;
      }
      result.add(cleanItem);
    }
    return result;
  }

  List<String> _dedupedList(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final cleanValue = value.trim();
      if (cleanValue.isEmpty || result.contains(cleanValue)) {
        continue;
      }
      result.add(cleanValue);
    }
    return result;
  }

  int _weightValue(String rawText, {required int fallback}) {
    // 中文注释: 权重输入失败时保持原值或默认值，避免一次误输把 binding 清成无意义的 0。
    final parsed = int.tryParse(rawText.trim());
    if (parsed == null || parsed <= 0) {
      return fallback;
    }
    return parsed;
  }
}
