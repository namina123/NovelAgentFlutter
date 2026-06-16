import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../approval/approval_command.dart';
import '../shared/cli_automation_input_service.dart';
import '../shared/cli_arguments.dart';
import '../shared/cli_help_contract.dart';
import '../shared/cli_project_artifact_label_service.dart';
import '../../output/terminal_printer.dart';
import 'workflow_output_summary_service.dart';

part 'workflow_command_dispatch.dart';
part 'workflow_command_parsing.dart';
part 'workflow_command_output.dart';
part 'workflow_command_user.dart';
part 'workflow_command_debug.dart';
part 'workflow_command_draft.dart';
part 'workflow_command_reference_extraction.dart';
part 'workflow_command_long_task.dart';
part 'workflow_command_checkpoint_revision.dart';

typedef CliGenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );
typedef CliLlmGatewayFactory =
    LlmGateway Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );

class WorkflowCommand {
  WorkflowCommand({
    required SettingsRepository settingsRepository,
    required ProjectRepository projectRepository,
    required BuildModeGuidancePlanInputUseCase
    buildModeGuidancePlanInputUseCase,
    required LoadModeGuidanceStateUseCase loadModeGuidanceStateUseCase,
    required CliGenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    required CliLlmGatewayFactory llmGatewayFactory,
    required ProjectWorkflowRuntimeService workflowRuntimeService,
    required ProjectReferenceExtractionRuntimeService
    referenceExtractionRuntimeService,
    required ApprovalCommand approvalCommand,
    required TerminalPrinter printer,
    CliAutomationInputService? automationInputService,
    ModelExecutionProfileService? modelExecutionProfileService,
    WorkflowOutputSummaryService? workflowOutputSummaryService,
    CliProjectArtifactLabelService? projectArtifactLabelService,
    ProjectReferenceExtractionRequestBuilderService?
    referenceExtractionRequestBuilderService,
    ReferenceExtractionStrategyProfileOptionService?
    referenceExtractionStrategyProfileOptionService,
  }) : _settingsRepository = settingsRepository,
       _projectRepository = projectRepository,
       _buildModeGuidancePlanInputUseCase = buildModeGuidancePlanInputUseCase,
       _loadModeGuidanceStateUseCase = loadModeGuidanceStateUseCase,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _llmGatewayFactory = llmGatewayFactory,
       _workflowRuntimeService = workflowRuntimeService,
       _referenceExtractionRuntimeService = referenceExtractionRuntimeService,
       _approvalCommand = approvalCommand,
       _printer = printer,
       _automationInputService =
           automationInputService ?? const CliAutomationInputService(),
       _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _projectArtifactLabelService =
           projectArtifactLabelService ?? const CliProjectArtifactLabelService(),
       _referenceExtractionRequestBuilderService =
           referenceExtractionRequestBuilderService ??
           const ProjectReferenceExtractionRequestBuilderService(),
       _referenceExtractionStrategyProfileOptionService =
           referenceExtractionStrategyProfileOptionService ??
           const ReferenceExtractionStrategyProfileOptionService(),
       _workflowOutputSummaryService =
           workflowOutputSummaryService ?? WorkflowOutputSummaryService();

  final SettingsRepository _settingsRepository;
  final ProjectRepository _projectRepository;
  final BuildModeGuidancePlanInputUseCase _buildModeGuidancePlanInputUseCase;
  final LoadModeGuidanceStateUseCase _loadModeGuidanceStateUseCase;
  final CliGenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final CliLlmGatewayFactory _llmGatewayFactory;
  final ProjectWorkflowRuntimeService _workflowRuntimeService;
  final ProjectReferenceExtractionRuntimeService
  _referenceExtractionRuntimeService;
  final ApprovalCommand _approvalCommand;
  final TerminalPrinter _printer;
  final CliAutomationInputService _automationInputService;
  final ModelExecutionProfileService _modelExecutionProfileService;
  final CliProjectArtifactLabelService _projectArtifactLabelService;
  final ProjectReferenceExtractionRequestBuilderService
  _referenceExtractionRequestBuilderService;
  final ReferenceExtractionStrategyProfileOptionService
  _referenceExtractionStrategyProfileOptionService;
  final WorkflowOutputSummaryService _workflowOutputSummaryService;

  Future<int> run(List<String> args) async {
    // 中文注释: workflow 根入口只保留壳层方法，所有命令分发交给拆分后的 dispatcher。
    return workflowCommandDispatch(this, args);
  }
}
