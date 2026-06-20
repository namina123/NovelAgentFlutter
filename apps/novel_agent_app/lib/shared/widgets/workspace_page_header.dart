import 'package:flutter/material.dart';

import '../../app/layout/app_layout_scope.dart';
import 'horizontal_overflow_scrollbar.dart';
import 'section_heading.dart';

class WorkspacePageHeader extends StatelessWidget {
  const WorkspacePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBackRequested,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBackRequested;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutScope.of(context);
    final showBack = metrics.isCompact && onBackRequested != null;
    final actionItems = _buildActionItems();
    return Row(
      children: [
        if (showBack) ...[
          IconButton(
            tooltip: '返回',
            onPressed: onBackRequested,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: SectionHeading(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          ),
        ),
        if (actionItems.isNotEmpty) ...[
          const SizedBox(width: 12),
          Flexible(
            child: SizedBox(
              height: 40,
              child: HorizontalOverflowScrollbar(
                builder: (context, controller) => SingleChildScrollView(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actionItems,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActionItems() {
    if (actions.isEmpty) {
      return const <Widget>[];
    }
    final items = <Widget>[];
    for (var index = 0; index < actions.length; index++) {
      if (index > 0) {
        items.add(const SizedBox(width: 8));
      }
      items.add(actions[index]);
    }
    return items;
  }
}
