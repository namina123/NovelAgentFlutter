import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../models/conversation_entry_view_data.dart';

class ConversationEntryTile extends StatefulWidget {
  const ConversationEntryTile({super.key, required this.entry});

  final ConversationEntryViewData entry;

  @override
  State<ConversationEntryTile> createState() => _ConversationEntryTileState();
}

class _ConversationEntryTileState extends State<ConversationEntryTile> {
  late bool _detailsExpanded;

  @override
  void initState() {
    super.initState();
    _detailsExpanded = widget.entry.detailExpandedByDefault;
  }

  @override
  void didUpdateWidget(covariant ConversationEntryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _detailsExpanded = widget.entry.detailExpandedByDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 单条会话记录只负责展示一种时间线条目，不处理列表排序和会话状态切换。
    final entry = widget.entry;
    final palette = _paletteFor(entry);
    final hasDetails = entry.detailBody.trim().isNotEmpty;
    if (entry.kind == ConversationEntryKind.tool) {
      return _ToolConversationEntryTile(
        entry: entry,
        palette: palette,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: palette.border, width: AppChrome.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(palette.icon, size: 16, color: palette.foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title,
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (entry.body.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              entry.body,
              style: TextStyle(
                color: entry.isError
                    ? const Color(0xFF8A2E24)
                    : AppPalette.text,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (hasDetails) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _detailsExpanded = !_detailsExpanded;
                });
              },
              child: Row(
                children: [
                  Icon(
                    _detailsExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: palette.foreground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _detailToggleLabel(entry, expanded: _detailsExpanded),
                    style: TextStyle(
                      color: palette.foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (_detailsExpanded) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  border: Border.all(color: palette.border, width: 1),
                ),
                child: SelectableText(
                  entry.detailBody,
                  style: const TextStyle(
                    color: AppPalette.mutedText,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _detailToggleLabel(
    ConversationEntryViewData entry, {
    required bool expanded,
  }) {
    // 中文注释: 折叠态带一小段摘要，展开后恢复成纯标题，减少思考条目对列表高度的占用。
    final title = entry.detailTitle.trim().isEmpty ? '查看细节' : entry.detailTitle;
    if (expanded || entry.detailSummary.trim().isEmpty) {
      return title;
    }
    return '$title · ${entry.detailSummary.trim()}';
  }

  _EntryPalette _paletteFor(ConversationEntryViewData entry) {
    // 中文注释: 不同来源的消息使用统一颜色语义，方便用户一眼区分用户、助手和工具轨迹。
    if (entry.isError) {
      return const _EntryPalette(
        background: AppPalette.dangerSoft,
        border: Color(0xFFE2A39B),
        foreground: Color(0xFF9C3C30),
        icon: Icons.error_outline_rounded,
      );
    }
    switch (entry.kind) {
      case ConversationEntryKind.user:
        return const _EntryPalette(
          background: AppPalette.accentSoft,
          border: AppPalette.line,
          foreground: AppPalette.lineStrong,
          icon: Icons.person_outline_rounded,
        );
      case ConversationEntryKind.assistant:
        return const _EntryPalette(
          background: Color(0xFFF4EFD9),
          border: Color(0xFFD8C790),
          foreground: AppPalette.text,
          icon: Icons.auto_awesome_rounded,
        );
      case ConversationEntryKind.tool:
        return const _EntryPalette(
          background: Color(0xFFF7F7F2),
          border: Color(0xFFC5D4D9),
          foreground: AppPalette.mutedText,
          icon: Icons.build_circle_outlined,
        );
      case ConversationEntryKind.system:
        return const _EntryPalette(
          background: Color(0xFFF2F3F6),
          border: Color(0xFFC5CDD4),
          foreground: AppPalette.mutedText,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _ToolConversationEntryTile extends StatelessWidget {
  const _ToolConversationEntryTile({
    required this.entry,
    required this.palette,
  });

  final ConversationEntryViewData entry;
  final _EntryPalette palette;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工具条目刻意做轻，作为助手回合中间的执行痕迹，而不是与正文争抢视觉主位。
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                palette.icon,
                size: 12,
                color: entry.isError
                    ? const Color(0xFFB14A3C)
                    : palette.foreground,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: entry.title,
                        style: TextStyle(
                          color: entry.isError
                              ? const Color(0xFFB14A3C)
                              : palette.foreground,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (entry.body.trim().isNotEmpty)
                        TextSpan(
                          text: ' · ${entry.body.trim()}',
                          style: TextStyle(
                            color: entry.isError
                                ? const Color(0xFFA4483B)
                                : AppPalette.mutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryPalette {
  const _EntryPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
