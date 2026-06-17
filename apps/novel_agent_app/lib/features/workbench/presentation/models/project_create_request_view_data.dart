import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectCreateRequestViewData {
  const ProjectCreateRequestViewData({
    required this.title,
    required this.projectTypeId,
    required this.storageStrategyId,
    this.runtimeBaselineId = '',
    this.bookDeconstructionFollowupRouteId = 'continuation',
    this.continuityInput = const ProjectContinuityInputProfile(),
  });

  final String title;
  final String projectTypeId;
  final String storageStrategyId;
  final String runtimeBaselineId;
  final String bookDeconstructionFollowupRouteId;
  final ProjectContinuityInputProfile continuityInput;
}
