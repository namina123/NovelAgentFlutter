import '../project/project_content_path_policy_service.dart';

class LongTaskPlanningArtifactPathService {
  const LongTaskPlanningArtifactPathService({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;

  static const String projectSpecPath = 'specs/project_spec.md';

  String storyOutlinePath() {
    return '${_contentPathPolicyService.directoryForContentType('outline')}/总纲.md';
  }

  String chapterPlanPath() {
    return '${_contentPathPolicyService.directoryForContentType('chapter_outline')}/章节任务清单.md';
  }

  List<String> planningOutputPaths() {
    return <String>[projectSpecPath, storyOutlinePath(), chapterPlanPath()];
  }
}
