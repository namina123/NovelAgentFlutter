import 'package:flutter/material.dart';

import '../../app/layout/adaptive_page_frame.dart';
import '../theme/novel_theme_context.dart';

class WorkspacePageScaffold extends StatelessWidget {
  const WorkspacePageScaffold({
    super.key,
    required this.header,
    required this.body,
    this.headerBottom,
    this.statusText = '',
    this.isLoading = false,
  });

  final Widget header;
  final Widget body;
  final Widget? headerBottom;
  final String statusText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return AdaptivePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          if (headerBottom != null) ...[
            const SizedBox(height: 12),
            headerBottom!,
          ],
          if (statusText.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: colors.mutedTextColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(child: body),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
