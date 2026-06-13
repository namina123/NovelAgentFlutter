import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_typography.dart';
import 'conversation_entry_palette.dart';

class ConversationDetailSection extends StatefulWidget {
  const ConversationDetailSection({
    super.key,
    required this.title,
    required this.summary,
    required this.body,
    required this.expandedByDefault,
    required this.palette,
  });

  final String title;
  final String summary;
  final String body;
  final bool expandedByDefault;
  final ConversationEntryPalette palette;

  @override
  State<ConversationDetailSection> createState() =>
      _ConversationDetailSectionState();
}

class _ConversationDetailSectionState extends State<ConversationDetailSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.expandedByDefault;
  }

  @override
  void didUpdateWidget(covariant ConversationDetailSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body || oldWidget.title != widget.title) {
      _expanded = widget.expandedByDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanBody = widget.body.trim();
    if (cleanBody.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: widget.palette.detailBackground.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.palette.border.withValues(alpha: 0.22),
                width: AppChrome.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: widget.palette.foreground.withValues(alpha: 0.88),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _toggleLabel(),
                    style: TextStyle(
                      color: widget.palette.foreground.withValues(alpha: 0.88),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
            decoration: BoxDecoration(
              color: widget.palette.detailBackground.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.palette.border.withValues(alpha: 0.32),
                width: AppChrome.borderWidth,
              ),
            ),
            child: SelectableText(
              cleanBody,
              style: AppTypography.applyMonospaceFallback(
                TextStyle(
                  color: widget.palette.detailForeground,
                  fontSize: 11.4,
                  height: 1.56,
                  fontFamily: 'Consolas',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _toggleLabel() {
    // 中文注释: 折叠态保留一小段摘要，帮助用户在不展开时也能识别思考内容主题。
    final cleanTitle = widget.title.trim().isEmpty
        ? '查看细节'
        : widget.title.trim();
    final cleanSummary = widget.summary.trim();
    if (_expanded || cleanSummary.isEmpty) {
      return cleanTitle;
    }
    return '$cleanTitle · $cleanSummary';
  }
}
