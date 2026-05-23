import '../common/json_types.dart';
import '../project/project_descriptor.dart';

class DraftGenerationResult {
  const DraftGenerationResult({
    required this.project,
    required this.projectInfo,
    required this.userPrompt,
    required this.prompt,
    required this.modelId,
    required this.draftMarkdown,
    required this.contextPack,
    required this.selectedPaths,
    required this.executedTools,
    required this.writtenPaths,
    required this.changedPaths,
    required this.transcriptMessages,
    required this.waitingForUserChoice,
  });

  final ProjectDescriptor project;
  final JsonMap projectInfo;
  final String userPrompt;
  final String prompt;
  final String modelId;
  final String draftMarkdown;
  final JsonMap contextPack;
  final List<String> selectedPaths;
  final List<Object?> executedTools;
  final List<String> writtenPaths;
  final List<String> changedPaths;
  final List<JsonMap> transcriptMessages;
  final bool waitingForUserChoice;
}
