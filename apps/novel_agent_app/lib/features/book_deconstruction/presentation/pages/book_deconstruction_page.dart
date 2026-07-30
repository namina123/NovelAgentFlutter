import 'package:flutter/material.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../workbench/presentation/models/selector_option_view_data.dart';
import '../../../workbench/presentation/widgets/conversation_model_strip.dart';
import '../../application/controllers/book_deconstruction_controller.dart';
import '../../application/models/book_deconstruction_operation_kind.dart';
import '../contracts/book_deconstruction_action_handler.dart';
import '../models/book_deconstruction_view_data.dart';
import '../widgets/book_deconstruction_import_panel.dart';
import '../widgets/book_deconstruction_preview_panel.dart';
import '../widgets/book_deconstruction_toolbar.dart';

class BookDeconstructionPage extends StatelessWidget {
  const BookDeconstructionPage({super.key, required this.controller});

  final BookDeconstructionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final viewData = controller.viewData;
        final handler = controller;
        return WorkspacePageScaffold(
          header: BookDeconstructionToolbar(
            controller: controller,
            viewData: viewData,
          ),
          statusText: viewData.status,
          isLoading: viewData.isLoading,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StepCard(
                index: 1,
                title: '导入源文稿',
                description: '选择文本文件，或直接粘贴原文（单一入口）。',
                child: BookDeconstructionImportPanel(
                  viewData: viewData,
                  actionHandler: handler,
                ),
              ),
              _StepCard(
                index: 2,
                title: '拆书（纯净分章）',
                description: '只产出纯净的分章正文；可选勾选模型做去噪/分章辅助。',
                cancelVisible: viewData.isLoading &&
                    viewData.operationKind ==
                        BookDeconstructionOperationKind.splittingChapters,
                onCancel: handler.onBookDeconstructionCancelRequested,
                child: _SplitStep(viewData: viewData, actionHandler: handler),
              ),
              _StepCard(
                index: 3,
                title: '分析（可选）',
                description: '可选：用模型读拆书产物提取知识资产；不选模型则跳过（本地分析质量过低）。',
                cancelVisible: viewData.isLoading &&
                    viewData.operationKind ==
                        BookDeconstructionOperationKind.analyzingAssets,
                onCancel: handler.onBookDeconstructionCancelRequested,
                child: _AnalysisStep(
                  viewData: viewData,
                  actionHandler: handler,
                ),
              ),
              _StepCard(
                index: 4,
                title: '确认进入创作',
                description: '选择目标写作类型并确认，在当前项目内进入创作。',
                child: _ConfirmStep(viewData: viewData, actionHandler: handler),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// 一张步骤卡片：序号 + 标题 + 说明 + 内容。宽窄屏一致的纵向流。
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.title,
    required this.description,
    required this.child,
    this.cancelVisible = false,
    this.onCancel,
  });

  final int index;
  final String title;
  final String description;
  final Widget child;
  /// 中文注释: 长操作进行中时在卡片标题行露出"取消"，避免用户只能去顶栏找。
  final bool cancelVisible;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PanelSurface(
        showBorder: true,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StepBadge(index: index),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(description, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                if (cancelVisible && onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('取消'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

String _selectedModelLabel(
  List<SelectorOptionViewData> options,
  String selectedKey,
) {
  final cleanKey = selectedKey.trim();
  if (cleanKey.isEmpty) {
    return '选择模型';
  }
  for (final option in options) {
    if (option.id == cleanKey) {
      return option.label;
    }
  }
  return '选择模型';
}

class _SplitStep extends StatelessWidget {
  const _SplitStep({required this.viewData, required this.actionHandler});

  final BookDeconstructionViewData viewData;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final isSplitting =
        viewData.operationKind ==
        BookDeconstructionOperationKind.splittingChapters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: viewData.splitUseModel,
          onChanged: viewData.canUseSplitModel
              ? (value) => actionHandler
                    .onBookDeconstructionSplitUseModelChanged(value ?? false)
              : null,
          title: const Text('使用模型辅助拆书'),
          subtitle: Text(
            viewData.canUseSplitModel
                ? '勾选后用所选模型做正文去噪与分章；不勾则纯规则分章。模型与分析步独立。'
                : '尚未配置可用模型（需在设置里给接口配模型）。',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (viewData.splitUseModel) ...[
          const SizedBox(height: 8),
          ConversationModelStrip(
            modelLabel: _selectedModelLabel(
              viewData.splitModelOptions,
              viewData.splitModelOptionKey,
            ),
            modelOptions: viewData.splitModelOptions,
            onModelSelected:
                actionHandler.onBookDeconstructionSplitModelSelected,
            showSurface: false,
          ),
          const SizedBox(height: 8),
          // 中文注释: 粘贴内容(无源文件)时模型去噪会被跳过、走规则分章——显式提示，避免用户以为已用模型。
          if (viewData.sourceAbsolutePath.trim().isEmpty)
            Text(
              '当前是粘贴内容，模型去噪会跳过、按规则分章。如需模型去噪请先在步骤①选择文件。',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
        FilledButton.icon(
          onPressed: viewData.canSplit
              ? actionHandler.onBookDeconstructionSplitRequested
              : null,
          icon: isSplitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_fix_high_outlined),
          label: Text(isSplitting ? '正在拆书...' : '拆书'),
        ),
        const SizedBox(height: 12),
        BookDeconstructionPreviewPanel(
          viewData: viewData,
          actionHandler: actionHandler,
        ),
      ],
    );
  }
}

class _AnalysisStep extends StatelessWidget {
  const _AnalysisStep({required this.viewData, required this.actionHandler});

  final BookDeconstructionViewData viewData;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final isAnalyzing =
        viewData.operationKind ==
        BookDeconstructionOperationKind.analyzingAssets;
    final canRun =
        viewData.analysisUseModel &&
        viewData.analysisModelOptionKey.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: viewData.analysisUseModel,
          onChanged: viewData.canAnalyze
              ? (value) => actionHandler
                    .onBookDeconstructionAnalysisUseModelChanged(value ?? false)
              : null,
          title: const Text('使用模型分析'),
          subtitle: Text(
            viewData.canAnalyze
                ? '勾选并选模型后，用内置隐藏智能体读拆书产物提取知识资产。模型与拆书步独立。'
                : '尚未配置可用模型；不分析也可直接确认（本地分析质量过低，故不提供无模型分析）。',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (viewData.analysisUseModel) ...[
          const SizedBox(height: 8),
          ConversationModelStrip(
            modelLabel: _selectedModelLabel(
              viewData.analysisModelOptions,
              viewData.analysisModelOptionKey,
            ),
            modelOptions: viewData.analysisModelOptions,
            onModelSelected:
                actionHandler.onBookDeconstructionAnalysisModelSelected,
            showSurface: false,
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: canRun && !viewData.isLoading
                ? actionHandler.onBookDeconstructionAnalysisRequested
                : null,
            icon: isAnalyzing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology_outlined),
            label: Text(isAnalyzing ? '正在分析...' : '分析'),
          ),
        ],
        if (viewData.analysisStatusMessage.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            viewData.analysisStatusMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.viewData, required this.actionHandler});

  final BookDeconstructionViewData viewData;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final options = viewData.targetWritingTypeOptions;
    final selectionLocked = viewData.isCommitInProgress;
    final hasBuildResult =
        viewData.planGroups.isNotEmpty || viewData.previewSections.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('目标写作项目类型', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        if (!hasBuildResult)
          Text('完成拆书后会在此选择要把项目复合成哪种写作类型。', style: textTheme.bodySmall)
        else if (options.isEmpty)
          Text('当前项目类型暂无可复合的写作类型。', style: textTheme.bodySmall)
        else ...[
          Text(
            '拆完书后，把当前拆书项目复合成下列写作类型（保留拆书能力），即可在同项目内创作。',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option.label),
                  selected: option.id == viewData.selectedTargetWritingTypeId,
                  onSelected: selectionLocked
                      ? null
                      : (_) => actionHandler
                            .onBookDeconstructionTargetWritingTypeSelected(
                              option.id,
                            ),
                ),
            ],
          ),
          if (viewData.selectedTargetWritingTypeId == 'long_novel') ...[
            const SizedBox(height: 12),
            Text('长篇运行基准', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('长篇长任务需要先确定运行方式，确认后才会写入项目类型。', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue:
                  viewData.targetRuntimeBaselineOptions.any(
                    (option) =>
                        option.id == viewData.selectedTargetRuntimeBaselineId,
                  )
                  ? viewData.selectedTargetRuntimeBaselineId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '运行基准',
                border: OutlineInputBorder(),
              ),
              hint: const Text('请选择运行基准'),
              items: viewData.targetRuntimeBaselineOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option.id,
                      child: Text(option.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged:
                  selectionLocked ||
                      viewData.isLoading ||
                      !viewData.canSelectTargetRuntimeBaseline ||
                      viewData.targetRuntimeBaselineOptions.isEmpty
                  ? null
                  : (value) => actionHandler
                        .onBookDeconstructionTargetRuntimeBaselineSelected(
                          value ?? '',
                        ),
            ),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: viewData.inheritAsLiveNarrative,
            onChanged: selectionLocked || viewData.isLoading
                ? null
                : actionHandler
                      .onBookDeconstructionInheritAsLiveNarrativeChanged,
            title: const Text('将分章作为续写正文基础'),
            subtitle: const Text(
              '开启：分章写进正文 chapters/，续写在其后接写；关闭：分章只进资源目录 analysis/。',
            ),
          ),
          if (viewData.hasStagedAnalysis) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: viewData.applyStagedAnalysisResults,
              onChanged: selectionLocked || viewData.isLoading
                  ? null
                  : actionHandler
                        .onBookDeconstructionApplyStagedAnalysisResultsChanged,
              title: const Text('应用步骤③暂存分析结果'),
              subtitle: const Text('默认不应用；开启后才会在本次确认中挂载并投影当前暂存的分析资料包。'),
            ),
          ],
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: viewData.canConfirmSelection
              ? actionHandler.onBookDeconstructionConfirmRequested
              : null,
          icon: const Icon(Icons.assignment_turned_in_outlined),
          // 中文注释: 该按钮触发的是项目类型落定与进入创作（不可逆），而非单纯保存文件；
          // 文案须如实反映，避免用户以为是无害保存。
          label: const Text('确认并进入创作'),
        ),
        if (viewData.confirmedPreviewPath.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('拆书结果已保存到当前项目。', style: textTheme.bodySmall),
          if (viewData.canCreateDerivedProject) ...[
            const SizedBox(height: 8),
            // 中文注释: controller 早已实现派生项目流程，这里补上唯一缺失的 UI 入口，
            // 让"确认后可多路派生"的承诺真正可达。派生会立即切换到新项目，故二次确认。
            FilledButton.tonalIcon(
              onPressed: viewData.isLoading
                  ? null
                  : () async {
                      final confirmed = await showConfirmationDialog(
                        context,
                        title: '派生新写作项目？',
                        message: '将基于当前拆书成果创建一个新的写作项目并立即切换过去；当前拆书项目会保留，可随时回到作品库打开。',
                        confirmLabel: '派生并切换',
                      );
                      if (confirmed) {
                        actionHandler
                            .onBookDeconstructionCreateDerivedProjectRequested();
                      }
                    },
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('派生新写作项目'),
            ),
          ],
        ],
      ],
    );
  }
}
