import '../models/opening_session_projection.dart';
import '../models/project_opening_maturity_assessment.dart';
import '../../presentation/models/primary_action_view_data.dart';

class LongTaskStartActionPolicyService {
  const LongTaskStartActionPolicyService();

  PrimaryActionViewData? build({
    required String projectType,
    required OpeningSessionProjection? openingProjection,
    ProjectOpeningMaturityAssessment? openingMaturity,
  }) {
    if (!_isLongTaskProject(
      projectType: projectType,
      openingProjection: openingProjection,
    )) {
      return null;
    }
    final projection = openingProjection;
    final description = projection == null
        ? '继续补齐当前长任务开局信息；条件收束后会直接进入正式任务链。'
        : _descriptionOf(projection, openingMaturity: openingMaturity);
    return PrimaryActionViewData(
      id: 'opening.launch_long_task',
      title: '启动长任务',
      description: description,
      commandId: 'opening.launch_long_task',
    );
  }

  bool _isLongTaskProject({
    required String projectType,
    required OpeningSessionProjection? openingProjection,
  }) {
    final normalizedProjectType =
        openingProjection?.projectTypeId.trim().isNotEmpty == true
        ? openingProjection!.projectTypeId.trim()
        : projectType.trim();
    return normalizedProjectType == 'long_novel';
  }

  String _descriptionOf(
    OpeningSessionProjection projection, {
    ProjectOpeningMaturityAssessment? openingMaturity,
  }) {
    final readiness = projection.orchestration.readiness;
    if (readiness.canStartLongTask) {
      return '当前开局信息已收束完成，点击后会直接启动正式长任务链。';
    }
    if (openingMaturity?.isContinueReady == true) {
      return '当前项目已经有可继续推进的长篇基础，点击后会继续或恢复正式长任务链。';
    }
    if (readiness.missingRequirements.isNotEmpty) {
      return '当前还缺：${readiness.missingRequirements.map((item) => item.title).join('、')}。点击后继续补齐并进入下一步。';
    }
    final targetCommandId = projection.orchestration.suggestedActions.isEmpty
        ? ''
        : projection.orchestration.suggestedActions.first.commandId.trim();
    switch (targetCommandId) {
      case 'opening.choose_agent_group':
        return '先确认当前项目使用的智能体组，再继续启动长任务。';
      case 'opening.choose_runtime_baseline':
        return '先补齐项目运行基准，再继续启动长任务。';
      case 'opening.choose_long_task_mode':
        return '先确认当前长任务模式，再继续启动正式任务链。';
      case 'opening.open_mode_guidance':
      case 'opening.continue_mode_guidance':
        return '继续补齐当前长任务开局信息；条件收束后会直接进入正式任务链。';
      default:
        return '继续补齐当前长任务开局信息；条件收束后会直接进入正式任务链。';
    }
  }
}
