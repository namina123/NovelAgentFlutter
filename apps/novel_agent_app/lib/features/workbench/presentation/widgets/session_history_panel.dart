import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/session_history_entry_view_data.dart';
import 'session_history_entry_tile.dart';
import 'workbench_visual_style.dart';

class SessionHistoryPanel extends StatefulWidget {
  const SessionHistoryPanel({
    super.key,
    required this.entries,
    required this.onSelected,
    this.onDismiss,
    this.floating = false,
  });

  final List<SessionHistoryEntryViewData> entries;
  final ValueChanged<String> onSelected;
  final VoidCallback? onDismiss;
  final bool floating;

  @override
  State<SessionHistoryPanel> createState() => _SessionHistoryPanelState();
}

class _SessionHistoryPanelState extends State<SessionHistoryPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SessionHistoryEntryViewData> get _filteredEntries {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.entries;
    }
    return widget.entries
        .where((entry) => entry.title.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 会话历史视觉上也收成更像 IDE 侧栏列表，而不是一组独立信息卡片。
    if (widget.entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    final filtered = _filteredEntries;
    return Container(
      padding: widget.floating
          ? const EdgeInsets.fromLTRB(10, 10, 10, 10)
          : const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: widget.floating
            ? surface.backgroundColor.withValues(alpha: 0.98)
            : surface.backgroundColor.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(
            color: surface.borderColor.withValues(
              alpha: widget.floating ? 0.64 : 0.32,
            ),
            width: AppChrome.borderWidth,
          ),
        ),
        boxShadow: widget.floating
            ? [
                BoxShadow(
                  color: colors.lineStrongColor.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 14, color: colors.accentColor),
              const SizedBox(width: 6),
              Text(
                '会话记录',
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: visual.metaFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              if (widget.floating && widget.onDismiss != null)
                IconButton(
                  onPressed: widget.onDismiss,
                  tooltip: '收起会话历史',
                  splashRadius: 16,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: colors.mutedTextColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // 中文注释: 会话越积越多后靠滚动很难找——给一个标题搜索框，实时过滤。
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            style: TextStyle(fontSize: 12.5, color: colors.textColor),
            decoration: InputDecoration(
              isDense: true,
              hintText: '搜索会话标题',
              hintStyle: TextStyle(
                fontSize: 12.5,
                color: colors.mutedTextColor,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 14,
                color: colors.mutedTextColor,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 26,
                minHeight: 26,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              filled: true,
              fillColor: colors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.lineColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: colors.lineColor.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.accentColor),
              ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 6),
          Container(
            height: AppChrome.borderWidth,
            color: surface.borderColor.withValues(alpha: 0.32),
          ),
          const SizedBox(height: 6),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '没有匹配的会话',
                  style: TextStyle(fontSize: 12, color: colors.mutedTextColor),
                ),
              ),
            )
          else if (widget.floating)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: Scrollbar(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) => SessionHistoryEntryTile(
                    entry: filtered[index],
                    onSelected: widget.onSelected,
                  ),
                ),
              ),
            )
          else
            ...filtered.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              final isLast = index == filtered.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
                child: SessionHistoryEntryTile(
                  entry: value,
                  onSelected: widget.onSelected,
                ),
              );
            }),
        ],
      ),
    );
  }
}
