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
    return DocumentWorkspaceCanvasFrame(
      title: title,
      relativePath: relativePath,
      status: status,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.perm_media_outlined,
                size: 54,
                color: surface.highlightForegroundColor,
              ),
              const SizedBox(height: 14),
              Text(
                previewTypeLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: surface.foregroundColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                summary,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: surface.mutedForegroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
