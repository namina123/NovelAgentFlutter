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
    // 中文注释: 表达限制条目列表只关心规则方案与当前项目绑定状态，不承担保存和解析行为。
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
    // 中文注释: 编辑器只投影当前选中规则方案与对应 binding，不把列表页和详情页状态混在控制器里拼接。
    final selectedId = selectedProfileId(snapshot);
    if (selectedId.isEmpty) {
      return ExpressionConstraintBindingEditorViewData.empty();
    }
    final profile = _profileOf(snapshot, selectedId);
    if (profile == null) {
      return ExpressionConstraintBindingEditorViewData.empty();
    }
    final binding = _bindingOf(snapshot, selectedId);
    final selectedAgentIds = _selectedAgentIds(snapshot, binding);
    final selectedModeIds = _selectedModeIds(snapshot, binding);
    final availableStageOptions = _availableStageOptions(
      snapshot.availableStageOptions,
      selectedModeIds,
    );
    final selectedStageIds = _selectedStageIds(snapshot, binding);
    final selectedPolicyMode = _selectedPolicyMode(binding);
    return ExpressionConstraintBindingEditorViewData(
      profileId: profile.id,
      bindingId: binding?.id ?? profile.id,
      displayName: profile.displayName,
      summary: profile.summary,
      kindLabel: _kindLabel(profile.kind),
      originLabel: _originLabel(profile),
      sourcePath: _sourcePathOf(profile),
      entryAgentContextId: snapshot.entryAgentContextId,
      selectedPolicyMode: selectedPolicyMode,
      availablePolicyOptions: _policyOptions(),
      scopeSummary: _scopeSummary(
        snapshot,
        binding,
        selectedAgentIds: selectedAgentIds,
        selectedModeIds: selectedModeIds,
        selectedStageIds: selectedStageIds,
      ),
      strengthSummary: _strengthSummary(selectedPolicyMode),
      usageStrategySummary: _usageStrategySummary(selectedPolicyMode),
      recommendedScopeText: _recommendedScopeLabel(profile.recommendedScope),
      rules: List<String>.from(profile.rules),
      riskSignals: List<String>.from(profile.riskSignals),
      diagnosticFields: _diagnosticFields(
        snapshot,
        profile: profile,
        binding: binding,
        selectedPolicyMode: selectedPolicyMode,
        selectedAgentIds: selectedAgentIds,
        selectedModeIds: selectedModeIds,
        selectedStageIds: selectedStageIds,
      ),
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
      availableStageOptions: availableStageOptions,
      selectedAgentIds: selectedAgentIds,
      selectedModeIds: selectedModeIds,
      selectedStageIds: selectedStageIds,
      targetAgentIdsText: binding?.targetAgentIds.join(', ') ?? '',
      targetModeIdsText: binding?.targetModeIds.join(', ') ?? '',
      targetStageIdsText: binding?.targetStageIds.join(', ') ?? '',
      weightText: '${binding?.weight ?? 100}',
      hasBinding: binding != null,
      isBuiltin: ValueReaders.boolValue(profile.metadata['builtin']),
    );
  }

  String selectedProfileId(ProjectAssetsSnapshot snapshot) {
    // 中文注释: 详情页默认回落到首个规则方案，保证用户第一次打开“表达限制”页就能直接编辑。
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
    // 中文注释: 规则方案列表已经是稳定只读目录，这里只做轻量选择，不再复制或归一化对象。
    for (final profile in snapshot.catalog.expressionConstraints) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  String _statusLabel(ProjectExpressionConstraintBinding? binding) {
    // 中文注释: 列表 badge 只表达当前项目的启用策略，不把细作用域塞成过长标签。
    if (binding == null) {
      return '未纳入';
    }
    if (!binding.enabled) {
      return '已停用';
    }
    return switch (_selectedPolicyMode(binding)) {
      ExpressionConstraintExecutionPolicyModes.disabled => '已关闭',
      ExpressionConstraintExecutionPolicyModes.force => '强力约束',
      _ => '智能使用',
    };
  }

  String _scopeLabel(ProjectExpressionConstraintBinding? binding) {
    // 中文注释: 作用域摘要压成一行短文案，避免列表项被内部标识淹没。
    if (binding == null) {
      return '尚未纳入项目';
    }
    if (!binding.enabled) {
      return '当前已停用';
    }
    final segments = <String>[];
    if (binding.defaultForProject) {
      segments.add('全项目默认');
    }
    if (binding.targetAgentIds.isNotEmpty) {
      segments.add('智能体 ${binding.targetAgentIds.length}');
    }
    if (binding.targetModeIds.isNotEmpty) {
      segments.add('模式 ${binding.targetModeIds.length}');
    }
    if (binding.targetStageIds.isNotEmpty) {
      segments.add('阶段 ${binding.targetStageIds.length}');
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
      segments.add('智能体 ${scope.agentIds.join(', ')}');
    }
    if (scope.modeIds.isNotEmpty) {
      segments.add('模式 ${scope.modeIds.join(', ')}');
    }
    if (scope.stageIds.isNotEmpty) {
      segments.add('阶段 ${scope.stageIds.join(', ')}');
    }
    return segments.join(' · ');
  }

  String _originLabel(ExpressionConstraintProfile profile) {
    if (ValueReaders.boolValue(profile.metadata['builtin'])) {
      return '内置方案';
    }
    return '项目方案';
  }

  String _sourcePathOf(ExpressionConstraintProfile profile) {
    // 中文注释: 内置与项目自定义规则方案都统一从 metadata 里暴露来源路径，编辑面板只读取不解释。
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
    return _strategyCatalogService
        .modeDefinitions()
        .map((mode) {
          return ExpressionConstraintSelectableOptionViewData(
            id: mode.id,
            label: mode.title,
            note: mode.description,
          );
        })
        .toList(growable: false);
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

  String _selectedPolicyMode(ProjectExpressionConstraintBinding? binding) {
    final rawMode = ValueReaders.stringValue(
      binding?.metadata['policy_mode'],
    ).trim().toLowerCase();
    return switch (rawMode) {
      ExpressionConstraintExecutionPolicyModes.disabled =>
        ExpressionConstraintExecutionPolicyModes.disabled,
      ExpressionConstraintExecutionPolicyModes.force =>
        ExpressionConstraintExecutionPolicyModes.force,
      _ => ExpressionConstraintExecutionPolicyModes.adaptive,
    };
  }

  List<ExpressionConstraintPolicyOptionViewData> _policyOptions() {
    return const <ExpressionConstraintPolicyOptionViewData>[
      ExpressionConstraintPolicyOptionViewData(
        id: ExpressionConstraintExecutionPolicyModes.disabled,
        label: '关闭',
        description: '保留这套规则方案，但当前项目不注入表达规则，也不要求复核。',
      ),
      ExpressionConstraintPolicyOptionViewData(
        id: ExpressionConstraintExecutionPolicyModes.adaptive,
        label: '智能使用',
        description: '优先覆盖正文、修订等用户可见文本，必要时建议加强。',
      ),
      ExpressionConstraintPolicyOptionViewData(
        id: ExpressionConstraintExecutionPolicyModes.force,
        label: '强力约束',
        description: '对正文与修订强执行，明显偏离时直接阻塞修订。',
      ),
    ];
  }

  String _scopeSummary(
    ProjectAssetsSnapshot snapshot,
    ProjectExpressionConstraintBinding? binding, {
    required List<String> selectedAgentIds,
    required List<String> selectedModeIds,
    required List<String> selectedStageIds,
  }) {
    if (binding == null) {
      return '当前还没把这套表达规则纳入项目；保存后可按全项目或指定智能体生效。';
    }
    if (!binding.enabled) {
      return '已保留这套规则方案，但当前项目暂不参与运行解析。';
    }
    final segments = <String>[];
    if (binding.defaultForProject) {
      segments.add('全项目默认启用');
    }
    final agentLabels = _labelsForIds(
      selectedAgentIds,
      snapshot.availableAgentOptions,
    );
    if (agentLabels.isNotEmpty) {
      segments.add('定向智能体：${agentLabels.join('、')}');
    }
    final modeLabels = _labelsForIds(
      selectedModeIds,
      snapshot.availableModeOptions,
    );
    if (modeLabels.isNotEmpty) {
      segments.add('写作模式：${modeLabels.join('、')}');
    }
    final stageLabels = _labelsForIds(
      selectedStageIds,
      snapshot.availableStageOptions,
    );
    if (stageLabels.isNotEmpty) {
      segments.add('执行阶段：${stageLabels.join('、')}');
    }
    if (segments.isEmpty) {
      return '当前项目全局可用。';
    }
    return segments.join('；');
  }

  String _strengthSummary(String policyMode) {
    return switch (policyMode) {
      ExpressionConstraintExecutionPolicyModes.disabled =>
        '关闭注入与复核，只保留当前方案和范围配置。',
      ExpressionConstraintExecutionPolicyModes.force =>
        '正文与修订按强力约束执行，明显偏离会直接进入阻塞修订。',
      _ => '按写作轮次智能控制强度，常规正文以分段约束为主，并在已应用时要求复核。',
    };
  }

  String _usageStrategySummary(String policyMode) {
    return switch (policyMode) {
      ExpressionConstraintExecutionPolicyModes.disabled =>
        '当前策略为关闭；保留方案，但本轮不主动应用表达规则。',
      ExpressionConstraintExecutionPolicyModes.force =>
        '当前策略为强力约束；面向用户可见文本时优先强执行，并把明显偏离视为修补信号。',
      _ => '当前策略为智能使用；优先覆盖正文、修订等用户可见文本，技术轮次与研究轮次保持排除。',
    };
  }

  List<ExpressionConstraintDiagnosticFieldViewData> _diagnosticFields(
    ProjectAssetsSnapshot snapshot, {
    required ExpressionConstraintProfile profile,
    required ProjectExpressionConstraintBinding? binding,
    required String selectedPolicyMode,
    required List<String> selectedAgentIds,
    required List<String> selectedModeIds,
    required List<String> selectedStageIds,
  }) {
    final result = <ExpressionConstraintDiagnosticFieldViewData>[
      ExpressionConstraintDiagnosticFieldViewData(
        label: '策略模式标识',
        value: selectedPolicyMode,
      ),
      ExpressionConstraintDiagnosticFieldViewData(
        label: '规则方案标识',
        value: profile.id,
      ),
      ExpressionConstraintDiagnosticFieldViewData(
        label: '项目绑定标识',
        value: binding?.id.trim().isNotEmpty == true ? binding!.id : profile.id,
      ),
      ExpressionConstraintDiagnosticFieldViewData(
        label: '注入方式',
        value: _diagnosticInjectionMode(selectedPolicyMode),
      ),
    ];
    final recommendedScope = _recommendedScopeLabel(profile.recommendedScope);
    if (recommendedScope.trim().isNotEmpty && recommendedScope != '未给出推荐作用域') {
      result.add(
        ExpressionConstraintDiagnosticFieldViewData(
          label: '推荐作用域标识',
          value: recommendedScope,
        ),
      );
    }
    final sourcePath = _sourcePathOf(profile);
    if (sourcePath.trim().isNotEmpty) {
      result.add(
        ExpressionConstraintDiagnosticFieldViewData(
          label: '来源路径',
          value: sourcePath,
        ),
      );
    }
    if (snapshot.entryAgentContextId.trim().isNotEmpty) {
      result.add(
        ExpressionConstraintDiagnosticFieldViewData(
          label: '当前入口智能体标识',
          value: snapshot.entryAgentContextId.trim(),
        ),
      );
    }
    if (selectedAgentIds.isNotEmpty) {
      result.add(
        ExpressionConstraintDiagnosticFieldViewData(
          label: '智能体范围标识',
          value: selectedAgentIds.join(', '),
        ),
      );
    }
    if (selectedModeIds.isNotEmpty) {
      result.add(
        ExpressionConstraintDiagnosticFieldViewData(
          label: '模式范围标识',
          value: selectedModeIds.join(', '),
        ),
      );
    }
    if (selectedStageIds.isNotEmpty) {
      result.add(
        ExpressionConstraintDiagnosticFieldViewData(
          label: '阶段范围标识',
          value: selectedStageIds.join(', '),
        ),
      );
    }
    return result;
  }

  String _diagnosticInjectionMode(String policyMode) {
    return switch (policyMode) {
      ExpressionConstraintExecutionPolicyModes.disabled => 'disabled',
      ExpressionConstraintExecutionPolicyModes.force =>
        'brief_and_sections（用户可见文本强执行）',
      _ => 'brief_only / brief_and_sections（按轮次自动解析）',
    };
  }

  List<String> _labelsForIds(
    List<String> ids,
    List<ExpressionConstraintSelectableOptionViewData> options,
  ) {
    final labelById = <String, String>{
      for (final option in options)
        option.id.trim(): option.label.trim().isEmpty
            ? option.id.trim()
            : option.label.trim(),
    };
    final result = <String>[];
    for (final id in ids) {
      final cleanId = id.trim();
      if (cleanId.isEmpty) {
        continue;
      }
      final label = labelById[cleanId] ?? cleanId;
      if (!result.contains(label)) {
        result.add(label);
      }
    }
    return result;
  }
}
