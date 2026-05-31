import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/workbench_primary_action_plan.dart';
import '../../presentation/models/primary_action_view_data.dart';

class WorkbenchPrimaryActionService {
  WorkbenchPrimaryActionService({
    SessionGoalPromptBuilderService? sessionGoalPromptBuilderService,
    LongTaskEntryPromptBuilderService? longTaskEntryPromptBuilderService,
  }) : _sessionGoalPromptBuilderService =
           sessionGoalPromptBuilderService ??
           const SessionGoalPromptBuilderService(),
       _longTaskEntryPromptBuilderService =
           longTaskEntryPromptBuilderService ??
           const LongTaskEntryPromptBuilderService();

  final SessionGoalPromptBuilderService _sessionGoalPromptBuilderService;
  final LongTaskEntryPromptBuilderService _longTaskEntryPromptBuilderService;

  WorkbenchPrimaryActionPlan build({
    required PrimaryActionViewData action,
    required JsonMap project,
    required String activeDocumentPath,
    required String activeDocumentBody,
  }) {
    // 中文注释: 主动作执行计划在这里统一解析，控制器只负责按计划落地，不直接分支每个按钮文案。
    switch (action.commandId.trim()) {
      case 'refresh_project':
        return const WorkbenchPrimaryActionPlan(
          kind: WorkbenchPrimaryActionPlanKind.refreshProject,
        );
      case 'draft_again':
        return const WorkbenchPrimaryActionPlan(
          kind: WorkbenchPrimaryActionPlanKind.announce,
          message: '继续在输入框描述下一段需求即可发起新一轮内容生成。',
        );
      case 'session.goal':
        final mode = ValueReaders.stringValue(
          action.payload['mode'],
          SessionRecordConstants.modeSmartOpening,
        );
        return WorkbenchPrimaryActionPlan(
          kind: WorkbenchPrimaryActionPlanKind.sendPrompt,
          sessionMode: mode,
          message: '',
          prompt: _sessionGoalPromptBuilderService.build(
            mode: mode,
            project: project,
            activeDocumentPath: activeDocumentPath,
            activeDocumentExcerpt: activeDocumentBody,
          ),
        );
      case 'long_task.create_queue':
      case 'long_task.run_next':
      case 'long_task.run_controlled':
      case 'long_task.open_detail':
        return WorkbenchPrimaryActionPlan(
          kind: WorkbenchPrimaryActionPlanKind.sendPrompt,
          message: '',
          prompt: _longTaskEntryPromptBuilderService.build(
            actionId: action.commandId,
            project: project,
            payload: action.payload,
            activeDocumentPath: activeDocumentPath,
            activeDocumentExcerpt: activeDocumentBody,
          ),
        );
      default:
        return const WorkbenchPrimaryActionPlan(
          kind: WorkbenchPrimaryActionPlanKind.announce,
          message: '这个入口还没有接上执行计划，请先直接描述你的需求。',
        );
    }
  }
}
