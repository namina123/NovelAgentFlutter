import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/app_feedback.dart';
import '../models/conversation_entry_view_data.dart';
import 'conversation_detail_section.dart';
import 'conversation_entry_palette.dart';
import 'conversation_panel_style.dart';

class ConversationMessageEntryTile extends StatelessWidget {
  const ConversationMessageEntryTile({
    super.key,
    required this.entry,
    required this.palette,
  });

  final ConversationEntryViewData entry;
  final ConversationEntryPalette palette;

  /// 把整条消息正文复制到剪贴板并给出瞬时反馈。
  void _copyBody(BuildContext context) {
    final body = entry.body.trim();
    if (body.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: body));
    AppFeedback.show(context, '已复制到剪贴板', severity: AppFeedbackSeverity.success);
  }

  @override
  Widget build(BuildContext context) {
    final style = ConversationPanelStyle.of(context);
    final bodyTextColor = entry.isError
        ? palette.foreground
        : context.novelThemeColors.textColor;
    final useFastBodyRendering = entry.id == 'assistant_streaming';
    final colors = context.novelThemeColors;
    final isUser = entry.kind == ConversationEntryKind.user;
    final isLongFormBody = entry.body.trim().contains('\n\n');
    final isAssistant = entry.kind == ConversationEntryKind.assistant;
    final roleLabel = switch (entry.kind) {
      ConversationEntryKind.user => 'YOU',
      ConversationEntryKind.assistant => 'AI',
      ConversationEntryKind.system => 'SYSTEM',
      ConversationEntryKind.tool => 'TOOL',
    };
    final textLineCount = '\n'.allMatches(entry.body).length + 1;
    final headerColor = isUser
        ? colors.lineStrongColor
        : palette.foreground.withValues(alpha: 0.88);
    final cardMaxWidth = isUser ? 520.0 : 700.0;
    final card = Container(
      padding: EdgeInsets.fromLTRB(
        style.bandPadding.left + 1,
        style.bandPadding.top + (isLongFormBody ? 1 : 0),
        style.bandPadding.right + 1,
        style.bandPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: isUser
            ? palette.background.withValues(alpha: 0.7)
            : isAssistant
            ? palette.background.withValues(alpha: 0.04)
            : palette.background.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(style.sectionRadius),
        border: isAssistant
            ? Border(
                top: BorderSide(
                  color: palette.border.withValues(alpha: 0.08),
                  width: AppChrome.borderWidth,
                ),
              )
            : Border.all(
                color: palette.border.withValues(alpha: isUser ? 0.16 : 0.08),
                width: AppChrome.borderWidth,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: isUser
                      ? colors.accentColor.withValues(alpha: 0.14)
                      : palette.foreground.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(palette.icon, size: 10, color: headerColor),
              ),
              SizedBox(width: style.gap(-0.75, min: 5)),
              Expanded(
                child: Text(
                  entry.title,
                  style: TextStyle(
                    color: headerColor,
                    fontSize: style.metaFontSize + (isAssistant ? 0.05 : 0),
                    letterSpacing: isAssistant ? 0.01 : 0.04,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: style.gap(-0.75, min: 3)),
              Text(
                roleLabel,
                style: TextStyle(
                  fontSize: style.metaFontSize - 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: isAssistant ? 0.08 : 0.14,
                  color: isUser
                      ? colors.lineStrongColor
                      : colors.mutedTextColor.withValues(alpha: 0.72),
                ),
              ),
              if (entry.body.trim().isNotEmpty) ...[
                SizedBox(width: style.gap(-0.75, min: 4)),
                // 中文注释: 消息级「复制」常驻在卡片头部——不依赖悬停（移动端无 hover），
                // 也不与正文 SelectableText 的长按选区手势冲突。
                IconButton(
                  tooltip: '复制全文',
                  icon: Icon(
                    Icons.content_copy,
                    size: 13.5,
                    color: colors.mutedTextColor.withValues(alpha: 0.85),
                  ),
                  onPressed: () => _copyBody(context),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 12,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
                ),
              ],
            ],
          ),
          if (entry.body.trim().isNotEmpty) ...[
            SizedBox(height: style.bandGap),
            if (!isUser && textLineCount > 1)
              Padding(
                padding: EdgeInsets.only(bottom: isLongFormBody ? 10 : 8),
                child: Container(
                  width: isLongFormBody ? 48 : 36,
                  height: 1,
                  color: palette.border.withValues(
                    alpha: isAssistant ? 0.12 : 0.18,
                  ),
                ),
              ),
            _BodyText(
              text: entry.body,
              color: bodyTextColor,
              useFastRendering: useFastBodyRendering,
              isUser: isUser,
            ),
          ],
          if (entry.detailBody.trim().isNotEmpty) ...[
            SizedBox(height: style.sectionGap),
            ConversationDetailSection(
              title: entry.detailTitle,
              summary: entry.detailSummary,
              body: entry.detailBody,
              expandedByDefault: entry.detailExpandedByDefault,
              palette: palette,
            ),
          ],
        ],
      ),
    );
    if (isUser) {
      return Padding(
        padding: EdgeInsets.only(left: style.bodyGap * 2),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: card,
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConversationLogGutter(
          icon: palette.icon,
          color: palette.foreground,
          dividerColor: colors.lineColor.withValues(alpha: 0.28),
        ),
        SizedBox(width: style.gap(-0.75, min: 3)),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: card,
          ),
        ),
      ],
    );
  }
}

class _ConversationLogGutter extends StatelessWidget {
  const _ConversationLogGutter({
    required this.icon,
    required this.color,
    required this.dividerColor,
  });

  final IconData icon;
  final Color color;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Column(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.07)),
            ),
            child: Icon(icon, size: 7.5, color: color.withValues(alpha: 0.9)),
          ),
          Container(
            width: 1,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            color: dividerColor,
          ),
        ],
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText({
    required this.text,
    required this.color,
    required this.useFastRendering,
    required this.isUser,
  });

  final String text;
  final Color color;
  final bool useFastRendering;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final panelStyle = ConversationPanelStyle.of(context);
    final paragraphs = text
        .split('\n\n')
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
    final style = TextStyle(
      color: color,
      fontSize: isUser
          ? panelStyle.bodyFontSize + 0.1
          : panelStyle.bodyFontSize + 0.5,
      height: isUser
          ? panelStyle.bodyLineHeight + 0.1
          : panelStyle.bodyLineHeight + 0.28,
      fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: isUser ? 0.01 : 0.01,
    );
    if (useFastRendering) {
      return Text(text, style: style);
    }
    if (paragraphs.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < paragraphs.length; index++) ...[
            SelectableText(paragraphs[index], style: style),
            if (index < paragraphs.length - 1)
              SizedBox(height: panelStyle.bodyGap + 3),
          ],
        ],
      );
    }
    return SelectableText(text, style: style);
  }
}
