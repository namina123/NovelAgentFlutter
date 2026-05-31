import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectContinuityScopeDocument {
  const ProjectContinuityScopeDocument({
    required this.scope,
    this.overlays = const <ContinuationScopeOverlay>[],
  });

  final ContinuationScope scope;
  final List<ContinuationScopeOverlay> overlays;
}
