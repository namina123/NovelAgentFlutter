import 'package:flutter/material.dart';

import '../contracts/project_assets_action_handler.dart';
import '../models/project_rag_extraction_view_data.dart';

class ProjectRagExtractionPanel extends StatelessWidget {
  const ProjectRagExtractionPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ProjectRagExtractionViewData viewData;
  final ProjectAssetsActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          viewData.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          viewData.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '使用顺序：先提取语料，再点击“挂载语料”，挂载后当前项目才能实际使用这份语料。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (viewData.status.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(viewData.status, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: viewData.modes
              .map(
                (mode) => ChoiceChip(
                  label: Text(mode.title),
                  selected: mode.isSelected,
                  onSelected: mode.isImplemented
                      ? (_) => actionHandler.onProjectAssetsTabSelected(
                          'rag_extraction',
                        )
                      : null,
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          title: viewData.corpusSummary.title,
          lines: <String>[
            if (viewData.corpusSummary.corpusId.trim().isNotEmpty)
              '语料 ID：${viewData.corpusSummary.corpusId}',
            if (viewData.corpusSummary.sourceKind.trim().isNotEmpty)
              '来源类型：${viewData.corpusSummary.sourceKind}',
            if (viewData.corpusSummary.buildMode.trim().isNotEmpty)
              '构建方式：${viewData.corpusSummary.buildMode}',
            if (viewData.corpusSummary.language.trim().isNotEmpty)
              '语言：${viewData.corpusSummary.language}',
            '章数：${viewData.corpusSummary.chapterCountLabel}',
            '分片数：${viewData.corpusSummary.chunkCountLabel}',
            '模型辅助：${viewData.corpusSummary.modelAssistedLabel}',
            if (viewData.corpusSummary.indexBackendLabel.trim().isNotEmpty)
              '索引后端：${viewData.corpusSummary.indexBackendLabel}',
            if (viewData.corpusSummary.updatedAt.trim().isNotEmpty)
              '更新时间：${viewData.corpusSummary.updatedAt}',
            if (viewData.corpusSummary.sourcePath.trim().isNotEmpty)
              '源路径：${viewData.corpusSummary.sourcePath}',
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: '挂载摘要',
          lines: <String>[
            if (viewData.mountSummary.bindingCount > 0)
              '挂载数量：${viewData.mountSummary.bindingCount}',
            if (viewData.mountSummary.corpusIds.isNotEmpty)
              '语料：${viewData.mountSummary.corpusIds.join('、')}',
            if (viewData.mountSummary.topCorpusId.trim().isNotEmpty)
              '主语料：${viewData.mountSummary.topCorpusId}',
            if (viewData.mountSummary.topBindingId.trim().isNotEmpty)
              '主绑定：${viewData.mountSummary.topBindingId}',
            if (viewData.mountSummary.topMountScope.trim().isNotEmpty)
              '范围：${viewData.mountSummary.topMountScope}',
            if (viewData.mountSummary.topUsagePolicy.trim().isNotEmpty)
              '使用策略：${viewData.mountSummary.topUsagePolicy}',
            if (viewData.mountSummary.topActivationPolicy.trim().isNotEmpty)
              '激活策略：${viewData.mountSummary.topActivationPolicy}',
            if (viewData.mountSummary.emptyMessage.trim().isNotEmpty)
              viewData.mountSummary.emptyMessage,
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: '最近源文件',
          lines: <String>[
            if (viewData.recentSourcePath.trim().isNotEmpty)
              viewData.recentSourcePath
            else
              '当前还没有最近构建过的语料源文件。',
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton(
              onPressed: viewData.canBuildTxt && !viewData.isLoading
                  ? () => actionHandler.onProjectAssetsExtractRagRequested(
                        modeId: viewData.activeModeId,
                      )
                  : null,
              child: const Text('提取 txt 语料'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: viewData.canMountCorpus && !viewData.isLoading
                  ? actionHandler.onProjectAssetsMountRagCorpusRequested
                  : null,
              child: const Text('挂载语料'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...lines
              .where((line) => line.trim().isNotEmpty)
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(line, style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
        ],
      ),
    );
  }
}
