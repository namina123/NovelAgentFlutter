import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_guide_view_data.dart';
import '../../presentation/models/primary_action_view_data.dart';

class ConversationGuideViewDataService {
  ConversationGuideViewDataService({
    SessionGuideProfileService? sessionGuideProfileService,
  }) : _sessionGuideProfileService =
           sessionGuideProfileService ?? const SessionGuideProfileService();

  final SessionGuideProfileService _sessionGuideProfileService;

  ConversationGuideViewData build({
    required String projectType,
    required bool needsGoalSelection,
    required bool isGenerating,
  }) {
    // 中文注释: 会话引导到界面模型的投影收口在这里，避免控制器直接理解 core profile 结构。
    final profile = _sessionGuideProfileService.resolve(
      projectType: projectType,
      needsGoalSelection: needsGoalSelection,
      isRunning: isGenerating,
    );
    return ConversationGuideViewData(
      workflowTitle: profile.title,
      workflowDescription: profile.statusHint.trim().isEmpty
          ? profile.description
          : '${profile.description}\n\n${profile.statusHint}',
      composerHint: profile.composerHint,
      primaryActions: profile.primaryActions
          .map(
            (action) => PrimaryActionViewData(
              id: action.id,
              title: action.title,
              description: action.description,
              commandId: action.commandId,
              payload: action.payload,
            ),
          )
          .toList(growable: false),
    );
  }
}
