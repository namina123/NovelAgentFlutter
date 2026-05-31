import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/user_option_view_data.dart';

class ExpandableOptionTile extends StatefulWidget {
  const ExpandableOptionTile({
    super.key,
    required this.option,
    required this.onSelected,
  });

  final UserOptionViewData option;
  final ValueChanged<UserOptionViewData> onSelected;

  @override
  State<ExpandableOptionTile> createState() => _ExpandableOptionTileState();
}

class _ExpandableOptionTileState extends State<ExpandableOptionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final surface = context.novelThemeSurfaces.optionTile;
    final canExpand =
        option.description.trim().isNotEmpty || option.prompt.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: surface.backgroundColor,
        border: Border.all(
          color: surface.borderColor,
          width: surface.borderWidth,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => widget.onSelected(option),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: surface.highlightForegroundColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (option.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _collapsedSummary(option.description),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: surface.foregroundColor,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canExpand)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        splashRadius: 16,
                        tooltip: _expanded ? '收起细节' : '展开细节',
                        onPressed: () {
                          setState(() {
                            _expanded = !_expanded;
                          });
                        },
                        icon: Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 18,
                          color: surface.highlightForegroundColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded && canExpand)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: surface.borderColor.withValues(alpha: 0.8),
                    width: AppChrome.borderWidth,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (option.description.trim().isNotEmpty)
                    Text(
                      option.description.trim(),
                      style: TextStyle(
                        color: surface.foregroundColor,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  if (option.prompt.trim().isNotEmpty) ...[
                    if (option.description.trim().isNotEmpty)
                      const SizedBox(height: 8),
                    Text(
                      option.prompt.trim(),
                      style: TextStyle(
                        color: surface.mutedForegroundColor,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _collapsedSummary(String text) {
    final singleLine = text.replaceAll('\r', ' ').replaceAll('\n', ' ').trim();
    if (singleLine.length <= 40) {
      return singleLine;
    }
    return '${singleLine.substring(0, 40)}...';
  }
}
