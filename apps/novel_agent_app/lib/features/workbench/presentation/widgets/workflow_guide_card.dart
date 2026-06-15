import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_opening_state_view_data.dart';
import '../models/primary_action_view_data.dart';
import 'conversation_opening_state_summary.dart';
import 'conversation_supplement_section.dart';
import 'primary_action_list.dart';

class WorkflowGuideCard extends StatelessWidget {
  const WorkflowGuideCard({
    super.key,
    required this.title,
    required this.description,
    this.actions = const <PrimaryActionViewData>[],
    this.openingState,
    this.actionHandler,
    this.supplement,
  });

  final String title;
  final String description;
  final List<PrimaryActionViewData> actions;
  final ConversationOpeningStateViewData? openingState;
  final ConversationActionHandler? actionHandler;
  final Widget? supplement;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工作流引导卡独立后，未来切换不同项目体验 profile 时只需替换这个信息组件。
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    return PanelSurface(
      role: PanelSurfaceRole.panel,
      showBorder: false,
      padding: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: surface.backgroundColor.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: surface.borderColor.withValues(alpha: 0.64),
            width: AppChrome.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (openingState != null && actionHandler != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConversationOpeningStateSummary(
                    state: openingState!,
                    actionHandler: actionHandler!,
                    eyebrow: title,
                    showActionButton: false,
                  ),
                  if (_shouldShowOpeningDescription()) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        color: colors.mutedTextColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (_shouldShowActionList()) ...[
                    const SizedBox(height: 10),
                    PrimaryActionList(
                      actions: actions,
                      actionHandler: actionHandler!,
                    ),
                  ],
                ],
              )
            else ...[
              Text(
                '工作流建议',
                style: TextStyle(
                  color: colors.mutedTextColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: colors.mutedTextColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
            if (supplement != null) ...[
              const SizedBox(height: 10),
              ConversationSupplementSection(child: supplement!),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowOpeningDescription() {
    if (openingState == null) {
      return false;
    }
    if (description.trim().isEmpty) {
      return false;
    }
    return !openingState!.preferSingleAction || actions.length > 1;
  }

  bool _shouldShowActionList() {
    if (openingState == null) {
      return false;
    }
    if (actionHandler == null || actions.isEmpty) {
      return false;
    }
    return !openingState!.preferSingleAction || actions.length > 1;
  }
}
