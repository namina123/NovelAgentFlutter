import 'package:flutter/material.dart';

import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../workbench/presentation/models/selector_option_view_data.dart';
import '../../../workbench/presentation/widgets/conversation_model_strip.dart';
import '../../application/controllers/book_deconstruction_controller.dart';
import '../../application/models/book_deconstruction_operation_kind.dart';
import '../contracts/book_deconstruction_action_handler.dart';
import '../models/book_deconstruction_continuity_view_data.dart';
import '../models/book_deconstruction_followup_group_view_data.dart';
import '../models/book_deconstruction_followup_option_view_data.dart';
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
                child: _SplitStep(viewData: viewData, actionHandler: handler),
              ),
              _StepCard(
                index: 3,
                title: '分析（可选）',
                description: '可选：用模型读拆书产物提取知识资产；不选模型则跳过（本地分析质量过低）。',
                child: _AnalysisStep(
                  viewData: viewData,
                  actionHandler: handler,
                ),
              ),
              _StepCard(
                index: 4,
                title: '确认进入创作',
                description: '选择续写路线并确认，进入后续创作。',
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
  });

  final int index;
  final String title;
  final String description;
  final Widget child;

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
    final isSplitting = viewData.operationKind ==
        BookDeconstructionOperationKind.splittingChapters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: viewData.splitUseModel,
          onChanged: viewData.canUseSplitModel
              ? (value) =>
                  actionHandler.onBookDeconstructionSplitUseModelChanged(
                    value ?? false,
                  )
              : null,
          title: const Text('使用模型辅助拆书'),
          subtitle: Text(
            viewData.canUseSplitModel
                ? '勾选后用所选模型做正文去噪与分章；不勾则纯规则分章。模型与分析步独立。'
                : '尚未配置可用模型（需在设置里给 provider 配模型）。',
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
            onModelSelected: actionHandler.onBookDeconstructionSplitModelSelected,
            showSurface: false,
          ),
          const SizedBox(height: 8),
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
          label: Text(isSplitting ? '正在拆书…' : '拆书'),
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
    final isAnalyzing = viewData.operationKind ==
        BookDeconstructionOperationKind.analyzingAssets;
    final canRun = viewData.analysisUseModel &&
        viewData.analysisModelOptionKey.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: viewData.analysisUseModel,
          onChanged: viewData.canAnalyze
              ? (value) =>
                  actionHandler.onBookDeconstructionAnalysisUseModelChanged(
                    value ?? false,
                  )
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
            label: Text(isAnalyzing ? '正在分析…' : '分析'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (viewData.continuity != null) ...[
          _ContinuitySummarySection(
            continuity: viewData.continuity!,
            actionHandler: actionHandler,
          ),
          const SizedBox(height: 12),
        ] else ...[
          Text('完成拆书后会在此选择续写路线。', style: textTheme.bodySmall),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: viewData.canConfirmSelection
              ? actionHandler.onBookDeconstructionConfirmRequested
              : null,
          icon: const Icon(Icons.assignment_turned_in_outlined),
          label: const Text('保存拆书结果'),
        ),
        if (viewData.confirmedPreviewPath.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '拆书结果已保存到当前项目。',
            style: textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ContinuitySummarySection extends StatelessWidget {
  const _ContinuitySummarySection({
    required this.continuity,
    required this.actionHandler,
  });

  final BookDeconstructionContinuityViewData continuity;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('续写路线', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(continuity.summary, style: textTheme.bodySmall),
        const SizedBox(height: 8),
        ...continuity.followupGroups.map((group) => _buildGroup(context, group)),
      ],
    );
  }

  Widget _buildGroup(
    BuildContext context,
    BookDeconstructionFollowupGroupViewData group,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.title, style: textTheme.titleSmall),
          if (group.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(group.description, style: textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          if (group.options.isEmpty)
            Text('当前暂无可用路线。', style: textTheme.bodySmall)
          else
            ...group.options.map((option) => _buildOption(context, option)),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    BookDeconstructionFollowupOptionViewData option,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => actionHandler.onBookDeconstructionFollowupOptionSelected(
            option.id,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: option.isSelected || option.isHighlighted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: Icon(
                    option.isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: option.isSelected || option.isHighlighted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.isSelected
                            ? '${option.title} · 已选择'
                            : option.isHighlighted
                            ? '${option.title} · 当前默认'
                            : option.title,
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(option.summary, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
