import '../project/project_content_path_policy_service.dart';

class LongTaskPlanningArtifactPathService {
  const LongTaskPlanningArtifactPathService({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;

  static const String projectSpecPath = 'specs/project_spec.md';

  String styleContextPath() {
    return _contentPathPolicyService.directoryForContentType('style');
  }

  String styleGuidePath() {
    return '${styleContextPath()}/全书风格指南.md';
  }

  String storyOutlinePath() {
    return '${_contentPathPolicyService.directoryForContentType('outline')}/总纲.md';
  }

  String chapterPlanPath() {
    return '${_contentPathPolicyService.directoryForContentType('chapter_outline')}/章节任务清单.md';
  }

  String volumeOutlineDirectoryPath() {
    return _contentPathPolicyService.directoryForContentType('volume_outline');
  }

  List<String> sampleReadinessRequiredPaths() {
    return <String>[
      projectSpecPath,
      styleGuidePath(),
      storyOutlinePath(),
      chapterPlanPath(),
    ];
  }

  List<String> sampleReadinessOptionalPaths() {
    return <String>[volumeOutlineDirectoryPath()];
  }

  List<String> planningOutputPaths() {
    return <String>[projectSpecPath, storyOutlinePath(), chapterPlanPath()];
  }
}
