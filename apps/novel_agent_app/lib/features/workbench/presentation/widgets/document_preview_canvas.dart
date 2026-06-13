import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'document_workspace_canvas_frame.dart';

class DocumentPreviewCanvas extends StatelessWidget {
  const DocumentPreviewCanvas({
    super.key,
    required this.title,
    required this.relativePath,
    required this.status,
    required this.previewTypeLabel,
    required this.summary,
  });

  final String title;
  final String relativePath;
  final String status;
  final String previewTypeLabel;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    return DocumentWorkspaceCanvasFrame(
      title: title,
      relativePath: relativePath,
      status: status,
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: surface.backgroundColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: surface.borderColor.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.accentSoftColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.perm_media_outlined,
                    size: 34,
                    color: surface.highlightForegroundColor,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  previewTypeLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: surface.foregroundColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  summary,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                    color: surface.mutedForegroundColor,
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
