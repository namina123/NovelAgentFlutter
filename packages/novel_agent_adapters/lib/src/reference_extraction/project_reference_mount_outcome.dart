import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectReferenceMountOutcome {
  const ProjectReferenceMountOutcome({
    required this.status,
    this.warningCodes = const <String>[],
    this.projectionResult,
  });

  final String status;
  final List<String> warningCodes;
  final ReferenceProjectionResult? projectionResult;

  List<String> get knowledgeCardIds =>
      projectionResult?.knowledgeCardIds ?? const <String>[];

  List<String> get designElementIds =>
      projectionResult?.designElementIds ?? const <String>[];

  List<String> get researchNoteIds =>
      projectionResult?.researchNoteIds ?? const <String>[];

  List<String> get referenceWorkIds =>
      projectionResult?.referenceWorkIds ?? const <String>[];

  List<String> get generatedProjectionPaths =>
      projectionResult?.generatedProjectionPaths ?? const <String>[];
}
