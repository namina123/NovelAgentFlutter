import '../tools/project_tool_path_policy.dart';

class ProjectContinuityPathPolicy {
  ProjectContinuityPathPolicy({ProjectToolPathPolicy? toolPathPolicy})
    : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolPathPolicy _toolPathPolicy;

  String bundlePath() => 'tracking/continuity/bundle.json';

  String scopePrefix() => 'tracking/continuity/scopes/';

  String scopePath(String scopeId) {
    return '${scopePrefix()}${_safeId(scopeId, fallback: 'scope')}.json';
  }

  String framePrefix() => 'tracking/continuity/frames/';

  String framePath(String frameId) {
    return '${framePrefix()}${_safeId(frameId, fallback: 'frame')}.json';
  }

  String buildSpecIndexPath() => 'tracking/continuity/build_specs/index.json';

  String buildSpecPrefix() => 'tracking/continuity/build_specs/';

  String buildSpecPath(String specId) {
    return '${buildSpecPrefix()}${_safeId(specId, fallback: 'build_spec')}.json';
  }

  String analysisSummaryPath(String name) {
    return 'analysis/continuity/${_safeId(name, fallback: 'summary')}.md';
  }

  String _safeId(String value, {required String fallback}) {
    return _toolPathPolicy.safeFileName(value, fallback: fallback);
  }
}
