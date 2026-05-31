import 'package:flutter/material.dart';

import '../../app/layout/app_layout_scope.dart';
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
    return Row(
      children: [
        if (showBack) ...[
          IconButton(
            tooltip: '返回工作台',
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
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    );
  }
}
