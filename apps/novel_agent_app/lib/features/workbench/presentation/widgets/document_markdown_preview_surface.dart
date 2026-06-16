import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/theme/novel_theme_context.dart';

class DocumentMarkdownPreviewSurface extends StatefulWidget {
  const DocumentMarkdownPreviewSurface({super.key, required this.content});

  final String content;

  @override
  State<DocumentMarkdownPreviewSurface> createState() =>
      _DocumentMarkdownPreviewSurfaceState();
}

class _DocumentMarkdownPreviewSurfaceState
    extends State<DocumentMarkdownPreviewSurface> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final styleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(fontSize: 16.2, height: 1.84, color: surface.foregroundColor),
      pPadding: EdgeInsets.zero,
      a: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.accentColor,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.w800,
        color: surface.foregroundColor,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: surface.foregroundColor.withValues(alpha: 0.92),
      ),
      del: TextStyle(
        fontSize: 15.4,
        height: 1.7,
        decoration: TextDecoration.lineThrough,
        color: surface.mutedForegroundColor,
      ),
      h1: TextStyle(
        fontSize: 28,
        height: 1.24,
        fontWeight: FontWeight.w800,
        color: surface.foregroundColor,
      ),
      h2: TextStyle(
        fontSize: 23,
        height: 1.28,
        fontWeight: FontWeight.w800,
        color: surface.foregroundColor,
      ),
      h3: TextStyle(
        fontSize: 19,
        height: 1.34,
        fontWeight: FontWeight.w700,
        color: surface.foregroundColor,
      ),
      h4: TextStyle(
        fontSize: 16.2,
        height: 1.36,
        fontWeight: FontWeight.w700,
        color: surface.foregroundColor.withValues(alpha: 0.94),
      ),
      h1Padding: const EdgeInsets.only(top: 2, bottom: 14),
      h2Padding: const EdgeInsets.only(top: 14, bottom: 10),
      h3Padding: const EdgeInsets.only(top: 12, bottom: 7),
      h4Padding: const EdgeInsets.only(top: 10, bottom: 6),
      blockSpacing: 18,
      listIndent: 24,
      listBullet: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colors.accentColor.withValues(alpha: 0.9),
      ),
      listBulletPadding: const EdgeInsets.only(right: 10),
      checkbox: TextStyle(fontSize: 14.2, color: colors.accentColor),
      blockquote: TextStyle(
        fontSize: 14.2,
        height: 1.72,
        color: surface.mutedForegroundColor,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      blockquoteDecoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.18),
        border: Border(
          left: BorderSide(
            color: surface.borderColor.withValues(alpha: 0.24),
            width: 3,
          ),
        ),
      ),
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'Consolas',
        color: surface.highlightForegroundColor,
      ),
      codeblockPadding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      codeblockDecoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.16),
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.14),
          width: AppChrome.borderWidth,
        ),
      ),
      tableHead: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: surface.foregroundColor,
      ),
      tableBody: TextStyle(
        fontSize: 13.8,
        height: 1.6,
        color: surface.foregroundColor.withValues(alpha: 0.94),
      ),
      tableHeadAlign: TextAlign.left,
      tablePadding: const EdgeInsets.only(top: 6, bottom: 10),
      tableBorder: TableBorder.all(
        color: surface.borderColor.withValues(alpha: 0.22),
        width: AppChrome.borderWidth,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      tableCellsDecoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.08),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: surface.borderColor.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
      ),
    );
    final normalizedStyleSheet = styleSheet.copyWith(
      code: AppTypography.applyMonospaceFallback(styleSheet.code!),
      tableBody: AppTypography.applyMonospaceFallback(styleSheet.tableBody!),
      checkbox: AppTypography.applyMonospaceFallback(styleSheet.checkbox!),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: RawScrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          radius: const Radius.circular(999),
          thickness: 8,
          child: SingleChildScrollView(
            controller: _verticalController,
            padding: const EdgeInsets.fromLTRB(2, 2, 12, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RawScrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  radius: const Radius.circular(999),
                  thickness: 8,
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: math.max(0, constraints.maxWidth),
                      ),
                      child: MarkdownBody(
                        data: widget.content,
                        selectable: true,
                        styleSheet: normalizedStyleSheet,
                        extensionSet: md.ExtensionSet.gitHubFlavored,
                        softLineBreak: true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
