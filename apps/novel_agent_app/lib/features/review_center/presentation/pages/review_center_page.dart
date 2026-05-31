import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/section_heading.dart';
import '../../../../shared/widgets/workspace_page_header.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../../shared/widgets/workspace_pane_layout.dart';
import '../contracts/review_center_action_handler.dart';
import '../models/review_center_view_data.dart';
import '../widgets/review_center_analysis_panel.dart';

class ReviewCenterPage extends StatefulWidget {
  const ReviewCenterPage({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ReviewCenterViewData viewData;
  final ReviewCenterActionHandler actionHandler;

  @override
  State<ReviewCenterPage> createState() => _ReviewCenterPageState();
}

class _ReviewCenterPageState extends State<ReviewCenterPage> {
  late String _reviewType;
  late final TextEditingController _scopeController;
  late final TextEditingController _sourceController;

  @override
  void initState() {
    super.initState();
    _reviewType = widget.viewData.initialReviewTypeFilter;
    _scopeController = TextEditingController(
      text: widget.viewData.initialScopeFilter,
    );
    _sourceController = TextEditingController(
      text: widget.viewData.initialSourceFilter,
    );
  }

  @override
  void dispose() {
    _scopeController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReviewCenterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData.initialReviewTypeFilter !=
        widget.viewData.initialReviewTypeFilter) {
      _reviewType = widget.viewData.initialReviewTypeFilter;
    }
    if (oldWidget.viewData.initialScopeFilter !=
        widget.viewData.initialScopeFilter) {
      _scopeController.text = widget.viewData.initialScopeFilter;
    }
    if (oldWidget.viewData.initialSourceFilter !=
        widget.viewData.initialSourceFilter) {
      _sourceController.text = widget.viewData.initialSourceFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedEntry();
    return WorkspacePageScaffold(
      header: WorkspacePageHeader(
        title: widget.viewData.title,
        subtitle: widget.viewData.description,
        onBackRequested: widget.actionHandler.onReviewCenterBackRequested,
        actions: [
          ActionButton(
            label: '刷新',
            icon: Icons.refresh_rounded,
            compact: true,
            tone: ActionButtonTone.neutral,
            onPressed: widget.actionHandler.onReviewCenterRefreshRequested,
          ),
        ],
      ),
      headerBottom: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              key: ValueKey<String>('review-type-$_reviewType'),
              initialValue: _reviewType.isEmpty ? null : _reviewType,
              decoration: const InputDecoration(labelText: '类型'),
              items: widget.viewData.reviewTypes
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                setState(() {
                  _reviewType = value ?? '';
                });
              },
            ),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              controller: _scopeController,
              decoration: const InputDecoration(labelText: '范围'),
            ),
          ),
          SizedBox(
            width: 240,
            child: TextField(
              controller: _sourceController,
              decoration: const InputDecoration(labelText: '来源路径'),
            ),
          ),
          ActionButton(label: '筛选', compact: true, onPressed: _submitFilter),
          ActionButton(
            label: '清空',
            compact: true,
            tone: ActionButtonTone.neutral,
            onPressed: widget.actionHandler.onReviewCenterFilterCleared,
          ),
          ActionButton(
            label: '审稿当前文件',
            compact: true,
            onPressed:
                widget.actionHandler.onReviewCenterCreateCurrentReviewRequested,
          ),
          ActionButton(
            label: '创建修复任务',
            compact: true,
            tone: ActionButtonTone.warm,
            onPressed:
                widget.actionHandler.onReviewCenterCreateRepairTaskRequested,
          ),
        ],
      ),
      statusText: widget.viewData.status,
      body: WorkspacePaneLayout(
        breakpoint: 1320,
        leadingPaneWidth: 300,
        trailingPaneWidth: 420,
        leadingCompactHeight: 260,
        trailingCompactHeight: 320,
        leadingPane: PanelSurface(
          padding: const EdgeInsets.all(12),
          child: ListView.builder(
            itemCount: widget.viewData.entries.length,
            itemBuilder: (context, index) {
              final item = widget.viewData.entries[index];
              return ListTile(
                dense: true,
                selected: item.isSelected,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${item.badge}｜${item.subtitle}',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  widget.actionHandler.onReviewCenterEntrySelected(item.id);
                },
                trailing: IconButton(
                  onPressed: () {
                    widget.actionHandler.onReviewCenterEntryOpened(item.id);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                ),
              );
            },
          ),
        ),
        mainPane: PanelSurface(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                title: selected?.title ?? '报告详情',
                subtitle: selected?.relativePath ?? '未选中报告',
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.viewData.detailBody,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: AppPalette.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        trailingPane: PanelSurface(
          padding: const EdgeInsets.all(12),
          child: ReviewCenterAnalysisPanel(
            analysis: widget.viewData.analysis,
            actionHandler: widget.actionHandler,
          ),
        ),
      ),
    );
  }

  ReviewCenterEntryViewData? _selectedEntry() {
    for (final item in widget.viewData.entries) {
      if (item.isSelected) {
        return item;
      }
    }
    return widget.viewData.entries.isEmpty
        ? null
        : widget.viewData.entries.first;
  }

  void _submitFilter() {
    widget.actionHandler.onReviewCenterFilterSubmitted(
      reviewType: _reviewType,
      scope: _scopeController.text,
      sourcePath: _sourceController.text,
    );
  }
}
