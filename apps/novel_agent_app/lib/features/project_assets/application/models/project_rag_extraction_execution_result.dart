import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_rag_mount_summary.dart';
import 'project_rag_analysis_summary.dart';

class ProjectRagExtractionExecutionResult {
  const ProjectRagExtractionExecutionResult({
    required this.ok,
    required this.didMutateProject,
    required this.statusMessage,
    this.corpusPackage,
    this.mountSummary,
    this.analysisSummary,
    this.normalizationNote = '',
  });

  final bool ok;
  final bool didMutateProject;
  final String statusMessage;
  final RagCorpusPackage? corpusPackage;
  final ProjectRagMountSummary? mountSummary;
  final ProjectRagAnalysisSummary? analysisSummary;
  final String normalizationNote;
}
