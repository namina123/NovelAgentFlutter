import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_opening_state_view_data.dart';
import '../models/workbench_view_data.dart';
import 'conversation_opening_state_summary.dart';
import 'conversation_supplement_section.dart';
import 'primary_action_list.dart';

class ConversationEmptyStatePanel extends StatefulWidget {
  const ConversationEmptyStatePanel({
    super.key,
    required this.title,
    required this.description,
    required this.actions,
    required this.actionHandler,
    this.openingState,
    this.supplement,
  });

  final String title;
  final String description;
  final List<PrimaryActionViewData> actions;
  final ConversationActionHandler actionHandler;
  final ConversationOpeningStateViewData? openingState;
  final Widget? supplement;

  @override
  State<ConversationEmptyStatePanel> createState() =>
      _ConversationEmptyStatePanelState();
}

class _ConversationEmptyStatePanelState
    extends State<ConversationEmptyStatePanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // 中文注释: 空态面板拥有自己的滚动条控制器，确保 Scrollbar 与 ScrollView 绑定同一个位置。
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 会话空态继续朝“启动面板”而不是“说明页”收口，减少无意义大留白。
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    return PanelSurface(
      role: PanelSurfaceRole.panel,
      showBorder: false,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: surface.backgroundColor.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: surface.borderColor.withValues(alpha: 0.68),
                width: AppChrome.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: colors.accentColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                primary: false,
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    if (widget.openingState != null)
                      ConversationOpeningStateSummary(
                        state: widget.openingState!,
                        actionHandler: widget.actionHandler,
                        eyebrow: widget.title,
                      )
                    else
                      Text(
                        widget.description,
                        style: TextStyle(
                          color: colors.mutedTextColor,
                          fontSize: 11.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (_shouldShowOpeningDescription()) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.description,
                        style: TextStyle(
                          color: colors.mutedTextColor,
                          fontSize: 11.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (widget.supplement != null) ...[
                      const SizedBox(height: 12),
                      ConversationSupplementSection(child: widget.supplement!),
                    ],
                    if (_shouldShowActionList()) ...[
                      const SizedBox(height: 12),
                      PrimaryActionList(
                        actions: widget.actions,
                        actionHandler: widget.actionHandler,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowOpeningDescription() {
    if (widget.openingState == null) {
      return false;
    }
    if (widget.description.trim().isEmpty) {
      return false;
    }
    return !widget.openingState!.preferSingleAction ||
        widget.actions.length > 1;
  }

  bool _shouldShowActionList() {
    if (widget.actions.isEmpty) {
      return false;
    }
    if (widget.openingState == null) {
      return true;
    }
    return !widget.openingState!.preferSingleAction ||
        widget.actions.length > 1;
  }
}
