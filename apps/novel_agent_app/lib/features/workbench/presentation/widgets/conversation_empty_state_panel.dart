import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_opening_state_view_data.dart';
import '../models/workbench_view_data.dart';
import 'conversation_opening_state_summary.dart';
import 'conversation_supplement_section.dart';
import 'primary_action_list.dart';

class ConversationEmptyStatePanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // 中文注释: 会话空态面板独立占满中区，避免空白状态下只剩几颗按钮和一大段无意义留白。
    return PanelSurface(
      role: PanelSurfaceRole.panel,
      showBorder: false,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    if (openingState != null)
                      ConversationOpeningStateSummary(
                        state: openingState!,
                        actionHandler: actionHandler,
                        eyebrow: title,
                      )
                    else
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (supplement != null) ...[
                      const SizedBox(height: 12),
                      ConversationSupplementSection(child: supplement!),
                    ],
                    if (openingState == null && actions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      PrimaryActionList(
                        actions: actions,
                        actionHandler: actionHandler,
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
}
