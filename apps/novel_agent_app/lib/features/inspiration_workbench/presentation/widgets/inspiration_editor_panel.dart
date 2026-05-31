import 'package:flutter/material.dart';

import '../contracts/inspiration_workbench_action_handler.dart';
import '../models/inspiration_workbench_option_view_data.dart';
import '../models/inspiration_workbench_view_data.dart';
import 'inspiration_long_task_launch_panel.dart';

class InspirationEditorPanel extends StatefulWidget {
  const InspirationEditorPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final InspirationWorkbenchViewData viewData;
  final InspirationWorkbenchActionHandler actionHandler;

  @override
  State<InspirationEditorPanel> createState() => _InspirationEditorPanelState();
}

class _InspirationEditorPanelState extends State<InspirationEditorPanel> {
  late final TextEditingController _controller = TextEditingController();
  String _boundStageKey = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTextController();
  }

  @override
  void didUpdateWidget(covariant InspirationEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTextController();
  }

  @override
  void dispose() {
    // 中文注释: 文本输入控制器只属于当前编辑面板，因此由本组件自己释放。
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 编辑面板只围绕当前阶段提供输入和选项，不承担阶段列表和预览展示。
    final viewData = widget.viewData;
    if (viewData.selectedStageTitle.trim().isEmpty) {
      return const Center(child: Text('请选择一个灵感阶段。'));
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          viewData.selectedStageTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          viewData.selectedStageDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (viewData.selectedStageHelperText.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            viewData.selectedStageHelperText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (viewData.longTaskLaunch.isVisible) ...[
          const SizedBox(height: 16),
          InspirationLongTaskLaunchPanel(
            viewData: viewData.longTaskLaunch,
            actionHandler: widget.actionHandler,
          ),
        ],
        if (viewData.selectedStageOptions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '推荐方向',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...viewData.selectedStageOptions.map(_buildOptionCard),
        ],
        if (viewData.selectedStageAllowFreeText) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: '直接整理你当前已经确认的想法、边界和约束。',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _submitText,
              child: const Text('保存当前阶段'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionCard(InspirationWorkbenchOptionViewData option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: () {
          widget.actionHandler.onInspirationWorkbenchOptionSelected(
            stageId: widget.viewData.stages
                .firstWhere((stage) => stage.isSelected)
                .id,
            fieldKey: option.fieldKey,
            value: option.value,
            label: option.label,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  option.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Text(option.value),
              if (option.description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  option.description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _submitText() {
    widget.actionHandler.onInspirationWorkbenchTextSubmitted(
      stageId: widget.viewData.stages.firstWhere((stage) => stage.isSelected).id,
      fieldKey: widget.viewData.selectedStageFieldKey,
      value: _controller.text,
    );
  }

  void _syncTextController() {
    final stageKey =
        '${widget.viewData.selectedStageFieldKey}|${widget.viewData.selectedStageTitle}';
    if (_boundStageKey == stageKey &&
        _controller.text == widget.viewData.selectedStageValue) {
      return;
    }
    _boundStageKey = stageKey;
    _controller.value = TextEditingValue(
      text: widget.viewData.selectedStageValue,
      selection: TextSelection.collapsed(
        offset: widget.viewData.selectedStageValue.length,
      ),
    );
  }
}
