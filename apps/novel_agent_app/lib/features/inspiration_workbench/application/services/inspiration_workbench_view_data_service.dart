import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/inspiration_workbench_mode_option_view_data.dart';
import '../../presentation/models/inspiration_workbench_option_view_data.dart';
import '../../presentation/models/inspiration_workbench_preview_item_view_data.dart';
import '../../presentation/models/inspiration_workbench_preview_section_view_data.dart';
import '../../presentation/models/inspiration_workbench_stage_view_data.dart';
import '../../presentation/models/inspiration_workbench_view_data.dart';
import '../models/inspiration_workbench_snapshot.dart';
import 'inspiration_workbench_long_task_launch_view_data_service.dart';

class InspirationWorkbenchViewDataService {
  InspirationWorkbenchViewDataService({
    InspirationWorkbenchLongTaskLaunchViewDataService?
    longTaskLaunchViewDataService,
  }) : _longTaskLaunchViewDataService =
           longTaskLaunchViewDataService ??
           InspirationWorkbenchLongTaskLaunchViewDataService();

  final InspirationWorkbenchLongTaskLaunchViewDataService
  _longTaskLaunchViewDataService;

  InspirationWorkbenchViewData build({
    required String projectTitle,
    required InspirationWorkbenchSnapshot snapshot,
    required String status,
  }) {
    // 中文注释: 灵感页视图投影统一收口在这里，避免控制器和 widget 重复解析 core 领域对象。
    final definition = _definitionOf(snapshot);
    final state = snapshot.state;
    final selectedStage = _selectedStage(definition, snapshot.selectedStageId);
    final answers = _answersByFieldKey(state);
    return InspirationWorkbenchViewData(
      projectTitle: projectTitle,
      status: status,
      isLoading: snapshot.isLoading,
      modeOptions: snapshot.availableModes
          .map(
            (mode) => InspirationWorkbenchModeOptionViewData(
              id: mode.id,
              title: mode.title,
              description: mode.description,
              isSelected: mode.id == snapshot.selectedModeId,
            ),
          )
          .toList(growable: false),
      selectedModeTitle: definition?.title ?? '',
      selectedModeDescription: definition?.description ?? '',
      progressText: _progressText(state, definition),
      isReady: state?.isReady ?? false,
      stages: _buildStages(
        definition: definition,
        state: state,
        selectedStageId: snapshot.selectedStageId,
        answers: answers,
      ),
      selectedStageTitle: selectedStage?.title ?? '',
      selectedStageDescription: selectedStage?.description ?? '',
      selectedStageHelperText: selectedStage?.helperText ?? '',
      selectedStageFieldKey: selectedStage?.fieldKey ?? '',
      selectedStageAllowFreeText: selectedStage?.allowFreeText ?? false,
      selectedStageValue: answers[selectedStage?.fieldKey ?? '']?.value ?? '',
      selectedStageOptions: _buildStageOptions(selectedStage),
      previewSections: _buildPreviewSections(snapshot),
      longTaskLaunch: _longTaskLaunchViewDataService.build(
        projectType: snapshot.projectType,
        state: state,
      ),
    );
  }

  List<InspirationWorkbenchStageViewData> _buildStages({
    required ModeDefinition? definition,
    required ModeGuidanceState? state,
    required String selectedStageId,
    required Map<String, ModeGuidanceAnswer> answers,
  }) {
    if (definition == null) {
      return const <InspirationWorkbenchStageViewData>[];
    }
    return definition.stages.map((stage) {
      final answer = answers[stage.fieldKey];
      return InspirationWorkbenchStageViewData(
        id: stage.id,
        title: stage.title,
        description: stage.description,
        helperText: stage.helperText,
        answerPreview: _answerPreview(answer),
        isSelected: stage.id == selectedStageId,
        isCompleted: state?.completedStageIds.contains(stage.id) ?? false,
        isCurrent: state?.currentStageId == stage.id,
        allowFreeText: stage.allowFreeText,
        fieldKey: stage.fieldKey,
        answerOptions: _buildStageOptions(stage),
      );
    }).toList(growable: false);
  }

  List<InspirationWorkbenchOptionViewData> _buildStageOptions(
    ModeStageDefinition? stage,
  ) {
    if (stage == null) {
      return const <InspirationWorkbenchOptionViewData>[];
    }
    return stage.options
        .map(
          (option) => InspirationWorkbenchOptionViewData(
            id: option.id,
            fieldKey: option.fieldKey,
            label: option.label,
            value: option.value,
            description: option.description,
          ),
        )
        .toList(growable: false);
  }

  List<InspirationWorkbenchPreviewSectionViewData> _buildPreviewSections(
    InspirationWorkbenchSnapshot snapshot,
  ) {
    final bundle = snapshot.assetBundle;
    if (bundle == null) {
      return const <InspirationWorkbenchPreviewSectionViewData>[];
    }
    return <InspirationWorkbenchPreviewSectionViewData>[
      InspirationWorkbenchPreviewSectionViewData(
        id: 'premise',
        title: '故事前提',
        emptyHint: '当前模式还没有沉淀出故事前提。',
        items: bundle.premises
            .map(
              (item) => InspirationWorkbenchPreviewItemViewData(
                id: item.id,
                title: item.displayName,
                summary: item.summary,
                path: bundle.markdownPathsByAssetId[item.id] ?? '',
                metaLines: <String>[
                  if (item.corePromise.trim().isNotEmpty)
                    '核心承诺：${item.corePromise}',
                  if (item.mainConflict.trim().isNotEmpty)
                    '主冲突：${item.mainConflict}',
                  ...item.boundaries.map((entry) => '边界：$entry'),
                ],
              ),
            )
            .toList(growable: false),
      ),
      InspirationWorkbenchPreviewSectionViewData(
        id: 'style',
        title: '风格约束',
        emptyHint: '当前模式还没有沉淀出风格约束。',
        items: bundle.styleProfiles
            .map(
              (item) => InspirationWorkbenchPreviewItemViewData(
                id: item.id,
                title: item.displayName,
                summary: item.summary,
                path: bundle.markdownPathsByAssetId[item.id] ?? '',
                metaLines: item.guardrails
                    .map((entry) => '护栏：$entry')
                    .toList(growable: false),
              ),
            )
            .toList(growable: false),
      ),
      InspirationWorkbenchPreviewSectionViewData(
        id: 'world',
        title: '世界锚点',
        emptyHint: '当前模式还没有沉淀出世界锚点。',
        items: bundle.worldRuleSets
            .map(
              (item) => InspirationWorkbenchPreviewItemViewData(
                id: item.id,
                title: item.displayName,
                summary: item.summary,
                path: bundle.markdownPathsByAssetId[item.id] ?? '',
                metaLines: item.rules
                    .map((entry) => '规则：$entry')
                    .toList(growable: false),
              ),
            )
            .toList(growable: false),
      ),
      InspirationWorkbenchPreviewSectionViewData(
        id: 'characters',
        title: '角色锚点',
        emptyHint: '当前模式还没有沉淀出角色锚点。',
        items: bundle.characterProfiles
            .map(
              (item) => InspirationWorkbenchPreviewItemViewData(
                id: item.id,
                title: item.displayName,
                summary: item.summary,
                path: bundle.markdownPathsByAssetId[item.id] ?? '',
                metaLines: <String>[
                  if (item.storyRole.trim().isNotEmpty) '角色职责：${item.storyRole}',
                ],
              ),
            )
            .toList(growable: false),
      ),
    ];
  }

  Map<String, ModeGuidanceAnswer> _answersByFieldKey(ModeGuidanceState? state) {
    final result = <String, ModeGuidanceAnswer>{};
    if (state == null) {
      return result;
    }
    for (final answer in state.answers) {
      result[answer.fieldKey] = answer;
    }
    return result;
  }

  String _answerPreview(ModeGuidanceAnswer? answer) {
    if (answer == null) {
      return '未填写';
    }
    final preferred = answer.label.trim().isNotEmpty ? answer.label : answer.value;
    final normalized = preferred.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 36) {
      return normalized;
    }
    return '${normalized.substring(0, 36)}...';
  }

  String _progressText(ModeGuidanceState? state, ModeDefinition? definition) {
    final completed = state?.completedStageIds.length ?? 0;
    final total = definition?.stages.length ?? 0;
    return '$completed/$total';
  }

  ModeDefinition? _definitionOf(InspirationWorkbenchSnapshot snapshot) {
    for (final mode in snapshot.availableModes) {
      if (mode.id == snapshot.selectedModeId) {
        return mode;
      }
    }
    return null;
  }

  ModeStageDefinition? _selectedStage(
    ModeDefinition? definition,
    String selectedStageId,
  ) {
    if (definition == null) {
      return null;
    }
    for (final stage in definition.stages) {
      if (stage.id == selectedStageId) {
        return stage;
      }
    }
    return definition.stages.isEmpty ? null : definition.stages.first;
  }
}
