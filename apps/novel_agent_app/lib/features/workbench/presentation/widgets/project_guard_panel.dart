import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';

class ProjectGuardPanel extends StatelessWidget {
  const ProjectGuardPanel({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.allowOpenExisting,
    required this.onCreateRequested,
    required this.onOpenExistingRequested,
  });

  final String title;
  final String description;
  final String status;
  final bool allowOpenExisting;
  final VoidCallback onCreateRequested;
  final VoidCallback onOpenExistingRequested;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.55,
              ),
            ),
            if (status.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 22),
            ActionButton(
              label: '创建新项目',
              icon: Icons.add_business_outlined,
              expanded: true,
              tone: ActionButtonTone.warm,
              onPressed: onCreateRequested,
            ),
            if (allowOpenExisting) ...[
              const SizedBox(height: 10),
              ActionButton(
                label: '打开已有项目',
                icon: Icons.folder_open_outlined,
                expanded: true,
                tone: ActionButtonTone.neutral,
                onPressed: onOpenExistingRequested,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
