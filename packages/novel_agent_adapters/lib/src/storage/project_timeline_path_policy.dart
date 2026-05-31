import '../tools/project_tool_path_policy.dart';

class ProjectTimelinePathPolicy {
  ProjectTimelinePathPolicy({ProjectToolPathPolicy? toolPathPolicy})
    : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolPathPolicy _toolPathPolicy;

  String assetPath(String recordId) {
    return 'assets/timeline/${_safeId(recordId)}.timeline.md';
  }

  String _safeId(String value) {
    return _toolPathPolicy.safeFileName(value, fallback: 'timeline');
  }
}
