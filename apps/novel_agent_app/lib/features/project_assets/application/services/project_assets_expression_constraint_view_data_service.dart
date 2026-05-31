import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_assets_view_data.dart';
import '../models/project_assets_snapshot.dart';
import '../../../agent_ecosystem/application/services/ecosystem_display_name_resolver_service.dart';

class ProjectAssetsExpressionConstraintViewDataService {
  const ProjectAssetsExpressionConstraintViewDataService({
    AgentDisplayNameResolverService? agentDisplayNameResolverService,
    StrategyCatalogService? strategyCatalogService,
  }) : _agentDisplayNameResolverService =
           agentDisplayNameResolverService ??
           const AgentDisplayNameResolverService(),
       _strategyCatalogService =
           strategyCatalogService ?? const StrategyCatalogService();

  final AgentDisplayNameResolverService _agentDisplayNameResolverService;
  final StrategyCatalogService _strategyCatalogService;

  List<ProjectAssetEntryViewData> buildEntries(ProjectAssetsSnapshot snapshot) {
    // 中文注释: 表达限制条目列表只关心 preset 与当前项目绑定状态，不承担保存和解析行为。
    final selectedId = selectedProfileId(snapshot);
    return snapshot.catalog.expressionConstraints
        .map((profile) {
          final binding = _bindingOf(snapshot, profile.id);
          return ProjectAssetEntryViewData(
            id: profile.id,
            title: profile.displayName,
            subtitle: profile.summary,
            badge: _statusLabel(binding),
            relativePath: _sourcePathOf(profile),
            meta:
                '${_kindLabel(profile.kind)} · ${_originLabel(profile)} · ${_scopeLabel(binding)}',
            isSelected: profile.id == selectedId,
          );
        })
        .toList(growable: false);
  }

  ExpressionConstraintBindingEditorViewData buildEditor(
    ProjectAssetsSnapshot snapshot,
  ) {
    // 中文注释: 编辑器只投影当前选中 preset 与对应 binding，不把列表页和详情页状态混在控制器里拼接。
    final selectedId = selectedProfileId(snapshot);
    if (selectedId.isEmpty) {
      return ExpressionConstraintBindingEditorViewData.empty();
    }
    final profile = _profileOf(snapshot, selectedId);
    if (profile == null) {
      return ExpressionConstraintBindingEditorViewData.empty();
    }
    final binding = _bindingOf(snapshot, selectedId);
    return ExpressionConstraintBindingEditorViewData(
      profileId: profile.id,
      displayName: profile.displayName,
      summary: profile.summary,
      kindLabel: _kindLabel(profile.kind),
      sourcePath: _sourcePathOf(profile),
      entryAgentContextId: snapshot.entryAgentContextId,
      recommendedScopeText: _recommendedScopeLabel(profile.recommendedScope),
      rules: List<String>.from(profile.rules),
      riskSignals: List<String>.from(profile.riskSignals),
      enabled: binding?.enabled ?? false,
      defaultForProject: binding?.defaultForProject ?? false,
      availableAgentOptions:
          List<ExpressionConstraintSelectableOptionViewData>.from(
            snapshot.availableAgentOptions,
          ),
      availableModeOptions:
          List<ExpressionConstraintSelectableOptionViewData>.from(
            snapshot.availableModeOptions,
          ),
      availableStageOptions: _availableStageOptions(
        snapshot.availableStageOptions,
        _selectedModeIds(snapshot, binding),
      ),
      selectedAgentIds: _selectedAgentIds(snapshot, binding),
      selectedModeIds: _selectedModeIds(snapshot, binding),
      selectedStageIds: _selectedStageIds(snapshot, binding),
      targetAgentIdsText: binding?.targetAgentIds.join(', ') ?? '',
      targetModeIdsText: binding?.targetModeIds.join(', ') ?? '',
      targetStageIdsText: binding?.targetStageIds.join(', ') ?? '',
      weightText: '${binding?.weight ?? 100}',
      hasBinding: binding != null,
      isBuiltin: ValueReaders.boolValue(profile.metadata['builtin']),
    );
  }

  String selectedProfileId(ProjectAssetsSnapshot snapshot) {
    // 中文注释: 详情页默认回落到首个 preset，保证用户第一次打开“表达限制”页就能直接编辑。
    if (snapshot.selectedExpressionConstraintId.trim().isNotEmpty) {
      return snapshot.selectedExpressionConstraintId.trim();
    }
    if (snapshot.catalog.expressionConstraints.isEmpty) {
      return '';
    }
    return snapshot.catalog.expressionConstraints.first.id;
  }

  ProjectExpressionConstraintBinding? _bindingOf(
    ProjectAssetsSnapshot snapshot,
    String profileId,
  ) {
    // 中文注释: 同一 profile 当前只允许一条项目级 binding，因此直接按 profileId 查找即可。
    for (final binding in snapshot.catalog.expressionConstraintBindings) {
      if (binding.profileId == profileId) {
        return binding;
      }
    }
    return null;
  }

  List<String> _selectedAgentIds(
    ProjectAssetsSnapshot snapshot,
    ProjectExpressionConstraintBinding? binding,
  ) {
    final availableIds = snapshot.availableAgentOptions
        .map((item) => item.id.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final fromBinding = <String>[
      for (final agentId in binding?.targetAgentIds ?? const <String>[])
        if (availableIds.contains(agentId.trim())) agentId.trim(),
    ];
    if (fromBinding.isNotEmpty) {
      return fromBinding;
    }
    final entryAgentId = snapshot.entryAgentContextId.trim();
    if (entryAgentId.isNotEmpty && availableIds.contains(entryAgentId)) {
      return <String>[entryAgentId];
    }
    return const <String>[];
  }

  List<String> _selectedModeIds(
    ProjectAssetsSnapshot snapshot,
    ProjectExpressionConstraintBinding? binding,
  ) {
    final availableIds = snapshot.availableModeOptions
        .map((item) => item.id.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    return _selectedIds(binding?.targetModeIds, availableIds);
  }

  List<String> _selectedStageIds(
    ProjectAssetsSnapshot snapshot,
    ProjectExpressionConstraintBinding? binding,
  ) {
    final selectedModeIds = _selectedModeIds(snapshot, binding);
    final availableIds = _availableStageOptions(
      snapshot.availableStageOptions,
      selectedModeIds,
    ).map((item) => item.id.trim()).where((item) => item.isNotEmpty).toSet();
    return _selectedIds(binding?.targetStageIds, availableIds);
  }

  List<String> _selectedIds(List<String>? source, Set<String> availableIds) {
    final result = <String>[];
    for (final item in source ?? const <String>[]) {
      final cleanItem = item.trim();
      if (cleanItem.isEmpty ||
          !availableIds.contains(cleanItem) ||
          result.contains(cleanItem)) {
        continue;
      }
      result.add(cleanItem);
    }
    return result;
  }

  List<ExpressionConstraintSelectableOptionViewData> _availableStageOptions(
    List<ExpressionConstraintSelectableOptionViewData> options,
    List<String> selectedModeIds,
  ) {
    if (selectedModeIds.isEmpty) {
      return List<ExpressionConstraintSelectableOptionViewData>.from(options);
    }
    final selectedModeSet = selectedModeIds.map((item) => item.trim()).toSet();
    return options
        .where((item) => selectedModeSet.contains(item.groupId.trim()))
        .toList(growable: false);
  }

  ExpressionConstraintProfile? _profileOf(
    ProjectAssetsSnapshot snapshot,
    String profileId,
  ) {
    // 中文注释: preset 列表已经是稳定只读目录，这里只做轻量选择，不再复制或归一化对象。
    for (final profile in snapshot.catalog.expressionConstraints) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  String _statusLabel(ProjectExpressionConstraintBinding? binding) {
    // 中文注释: 列表 badge 只表达当前项目是否启用，不把细作用域塞成过长标签。
    if (binding == null) {
      return '未绑定';
    }
    return binding.enabled ? '已启用' : '已停用';
  }

  String _scopeLabel(ProjectExpressionConstraintBinding? binding) {
    // 中文注释: 作用域摘要压成一行短文案，避免列表项被 agent/mode/stage 原始 ID 淹没。
    if (binding == null) {
      return '未设置项目绑定';
    }
    final segments = <String>[];
    if (binding.defaultForProject) {
      segments.add('全项目默认');
    }
    if (binding.targetAgentIds.isNotEmpty) {
      segments.add('Agent ${binding.targetAgentIds.length}');
    }
    if (binding.targetModeIds.isNotEmpty) {
      segments.add('Mode ${binding.targetModeIds.length}');
    }
    if (binding.targetStageIds.isNotEmpty) {
      segments.add('Stage ${binding.targetStageIds.length}');
    }
    if (segments.isEmpty) {
      return '全项目可用';
    }
    return segments.join(' · ');
  }

  String _recommendedScopeLabel(ExpressionConstraintScope scope) {
    // 中文注释: 推荐作用域只做提示，不会反向改写当前项目 binding。
    if (scope.isGlobal) {
      return '未给出推荐作用域';
    }
    final segments = <String>[];
    if (scope.projectTypeIds.isNotEmpty) {
      segments.add('项目类型 ${scope.projectTypeIds.join(', ')}');
    }
    if (scope.agentIds.isNotEmpty) {
      segments.add('Agent ${scope.agentIds.join(', ')}');
    }
    if (scope.modeIds.isNotEmpty) {
      segments.add('Mode ${scope.modeIds.join(', ')}');
    }
    if (scope.stageIds.isNotEmpty) {
      segments.add('Stage ${scope.stageIds.join(', ')}');
    }
    return segments.join(' · ');
  }

  String _originLabel(ExpressionConstraintProfile profile) {
    if (ValueReaders.boolValue(profile.metadata['builtin'])) {
      return '内置预设';
    }
    return '项目预设';
  }

  String _sourcePathOf(ExpressionConstraintProfile profile) {
    // 中文注释: 内置与项目自定义 preset 都统一从 metadata 里暴露来源路径，编辑面板只读取不解释。
    return ValueReaders.stringValue(
      profile.metadata['source_path'],
      ValueReaders.stringValue(profile.metadata['source']),
    );
  }

  String _kindLabel(ExpressionConstraintKind kind) {
    // 中文注释: app 层自己决定展示文案，避免把中文 UI 标签下沉进 core 枚举。
    switch (kind) {
      case ExpressionConstraintKind.naturalExpression:
        return '自然表达';
      case ExpressionConstraintKind.narrativeBoundary:
        return '叙事边界';
      case ExpressionConstraintKind.terminologyControl:
        return '术语控制';
      case ExpressionConstraintKind.rhythmControl:
        return '节奏控制';
      case ExpressionConstraintKind.continuityGuard:
        return '连续性护栏';
      case ExpressionConstraintKind.custom:
        return '自定义';
    }
  }

  List<ExpressionConstraintSelectableOptionViewData> buildAgentOptions(
    List<JsonMap> agents,
  ) {
    final result = <ExpressionConstraintSelectableOptionViewData>[];
    final seen = <String>{};
    for (final agent in agents) {
      final agentId = ValueReaders.stringValue(agent['id']).trim();
      if (agentId.isEmpty || !seen.add(agentId)) {
        continue;
      }
      result.add(
        ExpressionConstraintSelectableOptionViewData(
          id: agentId,
          label: _agentDisplayNameResolverService.resolve(agent),
          note: ValueReaders.stringValue(agent['description']),
        ),
      );
    }
    return result;
  }

  List<ExpressionConstraintSelectableOptionViewData> buildModeOptions() {
    return _strategyCatalogService.modeDefinitions().map((mode) {
      return ExpressionConstraintSelectableOptionViewData(
        id: mode.id,
        label: mode.title,
        note: mode.description,
      );
    }).toList(growable: false);
  }

  List<ExpressionConstraintSelectableOptionViewData> buildStageOptions() {
    final result = <ExpressionConstraintSelectableOptionViewData>[];
    final seen = <String>{};
    for (final mode in _strategyCatalogService.modeDefinitions()) {
      for (final stage in mode.stages) {
        if (!seen.add(stage.id)) {
          continue;
        }
        result.add(
          ExpressionConstraintSelectableOptionViewData(
            id: stage.id,
            label: stage.title,
            note: mode.title,
            groupId: mode.id,
          ),
        );
      }
    }
    return result;
  }
}
