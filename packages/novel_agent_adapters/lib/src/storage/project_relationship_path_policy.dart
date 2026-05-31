import '../tools/project_tool_path_policy.dart';

class ProjectRelationshipPathPolicy {
  ProjectRelationshipPathPolicy({ProjectToolPathPolicy? toolPathPolicy})
    : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolPathPolicy _toolPathPolicy;

  String assetPath(String recordId) {
    return 'assets/relationships/${_safeId(recordId)}.relationship.md';
  }

  String _safeId(String value) {
    return _toolPathPolicy.safeFileName(value, fallback: 'relationship');
  }
}
