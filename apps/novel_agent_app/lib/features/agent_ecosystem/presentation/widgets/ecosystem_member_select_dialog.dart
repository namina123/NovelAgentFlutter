import 'package:flutter/material.dart';

import '../../../workbench/presentation/models/selector_option_view_data.dart';

/// 生态成员（智能体/技能/技能组）多选弹窗。点按钮唤起，勾选可用成员，确认返回选中 id 集。
///
/// 中文注释: 取代过去"手填 ID 文本框"——用户不用再知道并敲入成员 ID，直接从列表勾选。
/// 带搜索（按 label/id 过滤）、已选计数、空态提示。
Future<Set<String>> showEcosystemMemberSelectDialog({
  required BuildContext context,
  required String title,
  required List<SelectorOptionViewData> options,
  required Set<String> initiallySelected,
  String emptyHint = '暂无可选项。',
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) => _EcosystemMemberSelectDialog(
      title: title,
      options: options,
      initialSelection: Set<String>.from(initiallySelected),
      emptyHint: emptyHint,
    ),
  ).then((result) => result ?? Set<String>.from(initiallySelected));
}

class _EcosystemMemberSelectDialog extends StatefulWidget {
  const _EcosystemMemberSelectDialog({
    required this.title,
    required this.options,
    required this.initialSelection,
    required this.emptyHint,
  });

  final String title;
  final List<SelectorOptionViewData> options;
  final Set<String> initialSelection;
  final String emptyHint;

  @override
  State<_EcosystemMemberSelectDialog> createState() =>
      _EcosystemMemberSelectDialogState();
}

class _EcosystemMemberSelectDialogState
    extends State<_EcosystemMemberSelectDialog> {
  late final TextEditingController _searchController;
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selected = Set<String>.from(widget.initialSelection);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SelectorOptionViewData> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.options;
    }
    return widget.options
        .where(
          (o) => o.label.toLowerCase().contains(q) || o.id.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          Text(
            '已选 ${_selected.length} / 共 ${widget.options.length}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.options.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.emptyHint, style: theme.textTheme.bodyMedium),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search, size: 18),
                      labelText: '搜索',
                      hintText: '按名称或 ID 过滤',
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final option in _filtered)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            value: _selected.contains(option.id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked ?? false) {
                                  _selected.add(option.id);
                                } else {
                                  _selected.remove(option.id);
                                }
                              });
                            },
                            title: Text(option.label),
                            subtitle: Text(option.id, style: theme.textTheme.bodySmall),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.initialSelection),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('确认'),
        ),
      ],
    );
  }
}
