import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';

class ProjectGuardPanel extends StatelessWidget {
  const ProjectGuardPanel({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.projectsRootPath,
    required this.allowOpenExisting,
    required this.onCreateRequested,
    required this.onOpenExistingRequested,
  });

  final String title;
  final String description;
  final String status;
  final String projectsRootPath;
  final bool allowOpenExisting;
  final VoidCallback onCreateRequested;
  final VoidCallback onOpenExistingRequested;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: surface.backgroundColor.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: surface.borderColor.withValues(alpha: 0.7),
              width: AppChrome.borderWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROJECT ENTRY',
                style: TextStyle(
                  color: colors.mutedTextColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: colors.mutedTextColor,
                  fontSize: 12,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: colors.inputBackground.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.lineColor.withValues(alpha: 0.72),
                    width: AppChrome.borderWidth,
                  ),
                ),
                child: Text(
                  '默认创建位置：$projectsRootPath',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.mutedTextColor,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
              if (status.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: colors.accentSoftColor.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.lineColor.withValues(alpha: 0.72),
                      width: AppChrome.borderWidth,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: colors.lineStrongColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
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
      ),
    );
  }
}
