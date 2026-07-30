import 'package:flutter/material.dart';

import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/workspace_page_header.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../application/controllers/project_assets_controller.dart';
import '../models/project_assets_view_data.dart';
import '../models/project_rag_extraction_view_data.dart';
import 'rag_status_text.dart';

class ProjectAssetsKnowledgeBaseRagWorkspace extends StatelessWidget {
  const ProjectAssetsKnowledgeBaseRagWorkspace({
    super.key,
    required this.controller,
    required this.viewData,
  });

  final ProjectAssetsController controller;
  final ProjectAssetsViewData viewData;

  @override
  Widget build(BuildContext context) {
    final rag = viewData.ragExtraction;
    return WorkspacePageScaffold(
      header: WorkspacePageHeader(
        title: viewData.title,
        subtitle: viewData.description,
        onBackRequested: controller.onProjectAssetsBackRequested,
        actions: [
          ActionButton(
            label: rag.isLoading ? '正在整理并提取' : '导入并整理为语料',
            icon: Icons.file_upload_outlined,
            compact: true,
            emphasized: true,
            disabled: rag.isLoading,
            onPressed: () => controller.onProjectAssetsExtractRagRequested(
              modeId: rag.activeModeId,
            ),
          ),
          ActionButton(
            label: rag.isLoading ? '等待完成' : '挂载到当前项目',
            icon: Icons.link_rounded,
            compact: true,
            tone: ActionButtonTone.neutral,
            disabled: !rag.canMountCorpus || rag.isLoading,
            onPressed: controller.onProjectAssetsMountRagCorpusRequested,
          ),
          ActionButton(
            label: '刷新',
            icon: Icons.refresh_rounded,
            compact: true,
            tone: ActionButtonTone.neutral,
            onPressed: controller.onProjectAssetsRefreshRequested,
          ),
        ],
      ),
      statusText: '',
      isLoading: viewData.isLoading || rag.isLoading,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1180;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _PrimaryPane(rag: rag, controller: controller),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: _SummaryPane(rag: rag)),
              ],
            );
          }
          return ListView(
            children: [
              _PrimaryPane(rag: rag, controller: controller),
              const SizedBox(height: 12),
              _SummaryPane(rag: rag),
            ],
          );
        },
      ),
    );
  }
}

class _PrimaryPane extends StatelessWidget {
  const _PrimaryPane({required this.rag, required this.controller});

  final ProjectRagExtractionViewData rag;
  final ProjectAssetsController controller;

  @override
  Widget build(BuildContext context) {
    return PanelSurface(
      showBorder: true,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkspaceLead(rag: rag),
          const SizedBox(height: 16),
          _ProgressStrip(rag: rag),
          const SizedBox(height: 18),
          _Section(
            title: '提取模式',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rag.modes
                  .map(
                    (mode) => Tooltip(
                      message: mode.isImplemented
                          ? mode.title
                          : '「${mode.title}」暂未实现，敬请期待。',
                      child: ChoiceChip(
                        // 中文注释: 未实现的检索模式点明「暂未实现」，避免被当成坏了的按钮。
                        label: Text(
                          mode.isImplemented
                              ? mode.title
                              : '${mode.title}（暂未实现）',
                        ),
                        selected: mode.isSelected,
                        onSelected: mode.isImplemented && !rag.isLoading
                            ? (_) =>
                                controller.onProjectAssetsEntrySelected(mode.id)
                            : null,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 18),
          _Section(
            title: '当前语料',
            child: _FieldList(
              lines: [
                '标题：${rag.corpusSummary.title}',
                if (rag.corpusSummary.corpusId.trim().isNotEmpty)
                  '语料 ID：${rag.corpusSummary.corpusId}',
                '来源类型：${rag.corpusSummary.sourceKind.trim().isEmpty ? '未生成' : rag.corpusSummary.sourceKind}',
                '构建方式：${rag.corpusSummary.buildMode.trim().isEmpty ? '未生成' : rag.corpusSummary.buildMode}',
                '章数：${rag.corpusSummary.chapterCountLabel}',
                '分片数：${rag.corpusSummary.chunkCountLabel}',
                '模型辅助：${rag.corpusSummary.modelAssistedLabel}',
                if (rag.normalizationNote.trim().isNotEmpty)
                  '整理说明：${rag.normalizationNote}',
                if (rag.corpusSummary.updatedAt.trim().isNotEmpty)
                  '更新时间：${rag.corpusSummary.updatedAt}',
              ],
            ),
          ),
          if (!rag.analysisSummary.isEmpty) ...[
            const SizedBox(height: 18),
            _Section(
              title: '分析摘要',
              child: _FieldList(
                lines: [
                  if (rag.analysisSummary.premiseSummary.trim().isNotEmpty)
                    '前提：${rag.analysisSummary.premiseSummary}',
                  if (rag.analysisSummary.storyOutlineSummary.trim().isNotEmpty)
                    '总纲：${rag.analysisSummary.storyOutlineSummary}',
                  if (rag.analysisSummary.styleSummary.trim().isNotEmpty)
                    '风格：${rag.analysisSummary.styleSummary}',
                  if (rag.analysisSummary.characterNames.isNotEmpty)
                    '角色：${rag.analysisSummary.characterNames.join('、')}',
                  if (rag.analysisSummary.organizationNames.isNotEmpty)
                    '组织：${rag.analysisSummary.organizationNames.join('、')}',
                  if (rag.analysisSummary.worldRuleTitles.isNotEmpty)
                    '规则：${rag.analysisSummary.worldRuleTitles.join('、')}',
                ],
              ),
            ),
          ],
          if (rag.recentSourcePath.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            _Section(
              title: '最近源文',
              child: SelectableText(
                rag.recentSourcePath,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPane extends StatelessWidget {
  const _SummaryPane({required this.rag});

  final ProjectRagExtractionViewData rag;

  @override
  Widget build(BuildContext context) {
    return PanelSurface(
      role: PanelSurfaceRole.sidebar,
      showBorder: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('挂载摘要', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          _FieldList(
            lines: [
              '挂载数量：${rag.mountSummary.bindingCount}',
              if (rag.mountSummary.topCorpusId.trim().isNotEmpty)
                '主语料：${rag.mountSummary.topCorpusId}',
              if (rag.mountSummary.topMountScope.trim().isNotEmpty)
                '范围：${rag.mountSummary.topMountScope}',
              if (rag.mountSummary.topUsagePolicy.trim().isNotEmpty)
                '使用策略：${rag.mountSummary.topUsagePolicy}',
              if (rag.mountSummary.topActivationPolicy.trim().isNotEmpty)
                '激活策略：${rag.mountSummary.topActivationPolicy}',
              if (rag.mountSummary.corpusIds.isNotEmpty)
                '已挂载语料：${rag.mountSummary.corpusIds.join('、')}',
              if (rag.mountSummary.emptyMessage.trim().isNotEmpty)
                rag.mountSummary.emptyMessage,
            ],
          ),
          const SizedBox(height: 18),
          Text('使用顺序', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          _FieldList(
            lines: const [
              '1. 先经过拆书/整理，得到可用纯文本源文。',
              '2. 基于纯文本完成语料提取，并检查摘要是否合理。',
              '3. 将语料挂载到目标项目，再进入后续创作或检索流程。',
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceLead extends StatelessWidget {
  const _WorkspaceLead({required this.rag});

  final ProjectRagExtractionViewData rag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '语料提取',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '这里先把源文整理成可用纯文本，再构建为可挂载语料；它不进入普通创作工作区，也不暴露无关文件树。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.rag});

  final ProjectRagExtractionViewData rag;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rag.isLoading ? '正在处理' : '等待开始',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (rag.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (rag.isLoading)
            const LinearProgressIndicator(minHeight: 3)
          else
            Container(
              height: 3,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
            ),
          const SizedBox(height: 8),
          // 中文注释: 状态文案复用 RagStatusText——知识库项目的主目的就是 RAG，降级(向量化失败/退回关键词)
          // 在这里更不能埋成普通正文。空态保留原有"当前还没有进行中的提取任务。"提示(非降级，按普通正文渲染)。
          RagStatusText(
            status: rag.status.trim().isEmpty
                ? '当前还没有进行中的提取任务。'
                : rag.status,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _FieldList extends StatelessWidget {
  const _FieldList({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final visibleLines = lines
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visibleLines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: Theme.of(context).textTheme.bodySmall),
            ),
          )
          .toList(growable: false),
    );
  }
}
