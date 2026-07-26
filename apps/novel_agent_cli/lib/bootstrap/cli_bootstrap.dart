import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../commands/approval/approval_command.dart';
import '../commands/config/config_command.dart';
import '../commands/doctor/doctor_command.dart';
import '../commands/project/project_command.dart';
import '../commands/rag/rag_command.dart';
import '../commands/shared/cli_project_context_loader.dart';
import '../commands/shared/cli_settings_context_loader.dart';
import '../commands/shared/cli_help_contract.dart';
import '../commands/review/review_command.dart';
import '../commands/session/session_command.dart';
import '../commands/asset/asset_command.dart';
import '../commands/template/template_command.dart';
import '../commands/workflow/workflow_command.dart';
import '../commands/shared/cli_automation_input_service.dart';
import '../commands/shared/cli_exit_codes.dart';
import '../output/cli_output_settings.dart';
import '../output/terminal_printer.dart';

class CliBootstrap {
  Future<int> run(List<String> args) async {
    // 中文注释: CLI bootstrap 是唯一允许组装适配器和命令对象的地方，命令本身只消费依赖。
    final outputSettings = CliOutputSettings.fromArgs(args);
    final commandArgs = CliOutputSettings.stripGlobalFlags(args);
    final hostPlatform = _currentHostPlatform();
    final desktopPaths = DesktopAppPathsProvider().resolve(
      workingDirectoryPath: Directory.current.path,
    );
    final bundle = AdapterBundle.standard(
      workingDirectoryPath: Directory.current.path,
      settingsRootPath: desktopPaths.settingsRootPath,
      settingsSearchRoots: desktopPaths.settingsSearchRoots,
      defaultProjectRootPath: desktopPaths.defaultProjectRootPath,
    );
    final printer = TerminalPrinter(settings: outputSettings);
    final settingsContextLoader = CliSettingsContextLoader(
      settingsRepository: bundle.settingsRepository,
    );
    final commandContext = await settingsContextLoader.load();
    final automationInputService = const CliAutomationInputService();
    final projectContextLoader = CliProjectContextLoader(
      commandContext: commandContext,
      projectRepository: bundle.projectRepository,
      printer: printer,
    );
    final contextAssemblerService = ContextAssemblerService(
      budgetService: ContextBudgetService(),
      staticSectionService: ContextStaticSectionService(
        projectPromptContract: ProjectPromptContract(),
      ),
      projectFileSectionService: ContextProjectFileSectionService(),
    );
    final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
      projectWorkspacePort: bundle.projectWorkspacePort,
    );
    final modeGuidanceRepository = ProjectModeGuidanceRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    final generateCustomizationIndexesUseCase =
        GenerateCustomizationIndexesUseCase(
          writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        );
    final projectTaskRepository = ProjectTaskRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    final promptTemplateService = ProjectPromptTemplateService(
      workspacePort: bundle.projectWorkspacePort,
    );
    final projectAssetLibraryService = ProjectAssetLibraryService(
      workspacePort: bundle.projectWorkspacePort,
      projectToolHostPort: bundle.projectToolHostPort,
    );
    final characterRepository = ProjectCharacterProfileRepository(
      hostPort: bundle.projectToolHostPort,
    );
    final organizationRepository = ProjectOrganizationProfileRepository(
      hostPort: bundle.projectToolHostPort,
    );
    final relationshipRepository = ProjectRelationshipRepository(
      hostPort: bundle.projectToolHostPort,
    );
    final timelineRepository = ProjectTimelineRepository(
      hostPort: bundle.projectToolHostPort,
    );
    final runtimeProfileRepository = ProjectRuntimeProfileRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    final bundleFileAccessService = ProjectBundleFileAccessService(
      hostPort: bundle.projectToolHostPort,
    );
    final bundleApplyService = ProjectBundleApplyService(
      hostPort: bundle.projectToolHostPort,
    );
    final styleBundleLibraryService = ProjectStyleBundleLibraryService(
      assetLibraryService: projectAssetLibraryService,
      fileAccessService: bundleFileAccessService,
      applyService: bundleApplyService,
    );
    final characterBundleLibraryService = ProjectCharacterBundleLibraryService(
      characterRepository: characterRepository,
      organizationRepository: organizationRepository,
      fileAccessService: bundleFileAccessService,
      applyService: bundleApplyService,
    );
    final assetBundleLibraryService = ProjectAssetBundleLibraryService(
      assetLibraryService: projectAssetLibraryService,
      fileAccessService: bundleFileAccessService,
      applyService: bundleApplyService,
    );
    final projectPackageLibraryService = ProjectPackageLibraryService(
      workspacePort: bundle.projectWorkspacePort,
      runtimeProfileRepository: runtimeProfileRepository,
      promptTemplateService: promptTemplateService,
      characterRepository: characterRepository,
      organizationRepository: organizationRepository,
      assetLibraryService: projectAssetLibraryService,
      relationshipRepository: relationshipRepository,
      timelineRepository: timelineRepository,
      fileAccessService: bundleFileAccessService,
      applyService: bundleApplyService,
    );
    final reviewReportService = ProjectReviewReportService(
      workspacePort: bundle.projectWorkspacePort,
      taskRepository: projectTaskRepository,
    );
    final projectSessionWorkspaceService = ProjectSessionWorkspaceService(
      hostPort: bundle.projectToolHostPort,
    );
    final projectSessionShellService = ProjectSessionShellService(
      sessionWorkspaceService: projectSessionWorkspaceService,
    );
    final continuousTaskSupervisorBridgeService =
        ContinuousTaskSupervisorBridgeService(
          supervisor: bundle.longTaskSupervisor,
        );
    final referenceExtractionRuntimeService =
        ProjectReferenceExtractionRuntimeService(
          workspacePort: bundle.projectWorkspacePort,
          loadAvailableAgents: (project) =>
              bundle.agentPackageCatalog.loadAgentPackages(project),
          loadAvailableGroups: (project) =>
              bundle.agentGroupCatalog.loadAgentGroups(project),
          groupBindingRepository: bundle.projectAgentGroupBindingRepository,
          continuousTaskSyncService:
              ReferenceExtractionContinuousTaskSyncService(
                supervisorBridgeService: continuousTaskSupervisorBridgeService,
              ),
        );
    final workflowRuntimeService = ProjectWorkflowRuntimeService(
      taskRepository: projectTaskRepository,
      promptTemplateService: promptTemplateService,
      longTaskWatchdog: bundle.longTaskWatchdog,
      loadProjectAgentGroupSelections: (project) =>
          bundle.projectAgentGroupBindingRepository.loadSelections(project),
      hostAwareGenerateDraftUseCaseFactory:
          (
            provider,
            networkSettings, {
            hostInformationPermissionContext,
            hostToolPermissionContext,
          }) {
            final basePort = bundle.projectToolExecutionPort;
            final scopedToolExecutionPort = basePort is ProjectToolDispatcher
                ? basePort.scopedWithHostPermissionContexts(
                    hostInformationPermissionContext:
                        hostInformationPermissionContext,
                    hostToolPermissionContext: hostToolPermissionContext,
                  )
                : basePort;
            return GenerateDraftUseCase(
              projectWorkspacePort: bundle.projectWorkspacePort,
              llmGateway: bundle.createGateway(
                provider,
                networkSettings: networkSettings,
              ),
              toolExecutionPort: scopedToolExecutionPort,
              contextAssemblerService: contextAssemblerService,
              projectPromptContract: ProjectPromptContract(),
              hostToolPermissionContext: hostToolPermissionContext,
              hostPlatform: hostPlatform,
              loadAvailableAgents: (project) =>
                  bundle.agentPackageCatalog.loadAgentPackages(project),
              loadAvailableAgentGroups: (project) =>
                  bundle.agentGroupCatalog.loadAgentGroups(project),
            );
          },
      generateDraftUseCaseFactory: (provider, networkSettings) {
        return GenerateDraftUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
          llmGateway: bundle.createGateway(
            provider,
            networkSettings: networkSettings,
          ),
          toolExecutionPort: bundle.projectToolExecutionPort,
          contextAssemblerService: contextAssemblerService,
          projectPromptContract: ProjectPromptContract(),
          hostPlatform: hostPlatform,
          loadAvailableAgents: (project) =>
              bundle.agentPackageCatalog.loadAgentPackages(project),
          loadAvailableAgentGroups: (project) =>
              bundle.agentGroupCatalog.loadAgentGroups(project),
        );
      },
    );
    final approvalCommand = ApprovalCommand(
      pendingResearchActionService: ProjectPendingResearchActionService(
        workspacePort: bundle.projectWorkspacePort,
      ),
      projectContextLoader: projectContextLoader,
      printer: printer,
      automationInputService: automationInputService,
    );
    final configCommand = ConfigCommand(
      settingsRepository: bundle.settingsRepository,
      printer: printer,
    );
    final doctorCommand = DoctorCommand(
      settingsRepository: bundle.settingsRepository,
      projectRepository: bundle.projectRepository,
      printer: printer,
    );
    final workflowCommand = WorkflowCommand(
      settingsRepository: bundle.settingsRepository,
      projectRepository: bundle.projectRepository,
      buildModeGuidancePlanInputUseCase: BuildModeGuidancePlanInputUseCase(
        statePort: modeGuidanceRepository,
      ),
      loadModeGuidanceStateUseCase: LoadModeGuidanceStateUseCase(
        statePort: modeGuidanceRepository,
      ),
      llmGatewayFactory: (provider, networkSettings) {
        return bundle.createGateway(provider, networkSettings: networkSettings);
      },
      generateDraftUseCaseFactory: (provider, networkSettings) {
        // 中文注释: CLI 与 GUI 共用同一套生成用例装配，只在输入输出壳层上保持差异。
        return GenerateDraftUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
          llmGateway: bundle.createGateway(
            provider,
            networkSettings: networkSettings,
          ),
          toolExecutionPort: bundle.projectToolExecutionPort,
          contextAssemblerService: contextAssemblerService,
          projectPromptContract: ProjectPromptContract(),
          hostPlatform: hostPlatform,
          loadAvailableAgents: (project) =>
              bundle.agentPackageCatalog.loadAgentPackages(project),
          loadAvailableAgentGroups: (project) =>
              bundle.agentGroupCatalog.loadAgentGroups(project),
        );
      },
      workflowRuntimeService: workflowRuntimeService,
      referenceExtractionRuntimeService: referenceExtractionRuntimeService,
      approvalCommand: approvalCommand,
      printer: printer,
      automationInputService: automationInputService,
    );
    final projectCommand = ProjectCommand(
      loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
        projectRepository: bundle.projectRepository,
        projectWorkspacePort: bundle.projectWorkspacePort,
      ),
      createProjectEntryUseCase: CreateProjectEntryUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
      ),
      importProjectFilesUseCase: ImportProjectFilesUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
        sourceImportDiscoveryPort: const SourceImportDiscoveryService(),
      ),
      updateProjectManifestUseCase: UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        readProjectFileUseCase: ReadProjectFileUseCase(
          bundle.projectWorkspacePort,
        ),
      ),
      projectToolHostPort: bundle.projectToolHostPort,
      previewCustomizationBundleImportUseCase:
          PreviewCustomizationBundleImportUseCase(),
      importCustomizationBundleUseCase: ImportCustomizationBundleUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
        generateCustomizationIndexesUseCase:
            generateCustomizationIndexesUseCase,
      ),
      generateCustomizationIndexesUseCase: generateCustomizationIndexesUseCase,
      saveCustomizationMarketIndexUseCase: SaveCustomizationMarketIndexUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      ),
      saveCustomizationBundleUseCase: SaveCustomizationBundleUseCase(
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      ),
      loadAgentPackages: (project) =>
          bundle.agentPackageCatalog.loadAgentPackages(project),
      loadAgentGroups: (project) =>
          bundle.agentGroupCatalog.loadAgentGroups(project),
      loadSkillPackages: (project) =>
          bundle.skillPackageCatalog.loadSkillPackages(project),
      loadSkillGroups: (project) =>
          bundle.skillGroupCatalog.loadSkillGroups(project),
      projectPackageLibraryService: projectPackageLibraryService,
      projectContextLoader: projectContextLoader,
      printer: printer,
      structuredContentBridgeService: ProjectStructuredContentBridgeService(),
    );
    final ragCommand = RagCommand(
      projectRepository: bundle.projectRepository,
      printer: printer,
    );
    final sessionCommand = SessionCommand(
      sessionShellService: projectSessionShellService,
      projectContextLoader: projectContextLoader,
      printer: printer,
      automationInputService: automationInputService,
    );
    final reviewCommand = ReviewCommand(
      reviewReportService: reviewReportService,
      projectContextLoader: projectContextLoader,
      printer: printer,
    );
    final assetCommand = AssetCommand(
      assetLibraryService: projectAssetLibraryService,
      styleBundleLibraryService: styleBundleLibraryService,
      characterBundleLibraryService: characterBundleLibraryService,
      assetBundleLibraryService: assetBundleLibraryService,
      projectContextLoader: projectContextLoader,
      printer: printer,
    );
    final templateCommand = TemplateCommand(
      promptTemplateService: promptTemplateService,
      projectContextLoader: projectContextLoader,
      printer: printer,
    );
    if (commandArgs.isEmpty) {
      _printRootHelp(printer);
      return 0;
    }
    switch (commandArgs.first) {
      case 'workflow':
        return _runWithProjectManifestRecovery(
          () =>
              workflowCommand.run(commandArgs.skip(1).toList(growable: false)),
          printer,
        );
      case 'project':
        return _runWithProjectManifestRecovery(
          () => projectCommand.run(
            commandArgs.skip(1).toList(growable: false),
            defaultProjectPath: commandContext.defaultProjectPath,
          ),
          printer,
        );
      case 'rag':
        return _runWithProjectManifestRecovery(
          () => ragCommand.run(commandArgs.skip(1).toList(growable: false)),
          printer,
        );
      case 'session':
        return sessionCommand.run(
          commandArgs.skip(1).toList(growable: false),
          defaultProjectPath: commandContext.defaultProjectPath,
        );
      case 'review':
        return reviewCommand.run(commandArgs.skip(1).toList(growable: false));
      case 'asset':
        return assetCommand.run(commandArgs.skip(1).toList(growable: false));
      case 'template':
        return templateCommand.run(commandArgs.skip(1).toList(growable: false));
      case 'approval':
        return approvalCommand.run(commandArgs.skip(1).toList(growable: false));
      case 'config':
        return configCommand.run(commandArgs.skip(1).toList(growable: false));
      case 'doctor':
        return _runWithProjectManifestRecovery(
          () => doctorCommand.run(commandArgs.skip(1).toList(growable: false)),
          printer,
        );
      case 'help':
      case '--help':
      case '-h':
        _printRootHelp(printer);
        return 0;
      default:
        printer.error('未知命令: ${commandArgs.first}');
        _printRootHelp(printer);
        return 2;
    }
  }

  Future<int> _runWithProjectManifestRecovery(
    Future<int> Function() command,
    TerminalPrinter printer,
  ) async {
    try {
      return await command();
    } on ProjectManifestCorruptionException {
      printer.error(CliProjectContextLoader.projectManifestCorruptionMessage);
      return CliExitCodes.invalidInput;
    }
  }

  void _printRootHelp(TerminalPrinter printer) {
    // 中文注释: 根帮助只展示当前已经可用的入口，减少用户在迁移期踩到空命令。
    CliHelpContract.printHelpBlock(printer, 'novel_agent help', [
      'workflow draft --prompt "写第一章开场"',
      'project --project D:\\YourNovel',
      'rag build --source D:\\book.txt --project D:\\YourNovel',
      'review list --project D:\\YourNovel',
      'asset list --project D:\\YourNovel',
      'template list --project D:\\YourNovel',
      'approval list --project D:\\YourNovel',
      'config show',
      'doctor',
      'session',
    ]);
  }

  HostPlatform _currentHostPlatform() {
    // 中文注释: CLI 平台识别集中在 bootstrap，后续若引入能力探测也只需在这里替换来源。
    if (Platform.isWindows) {
      return HostPlatform.windows;
    }
    if (Platform.isLinux) {
      return HostPlatform.linux;
    }
    if (Platform.isMacOS) {
      return HostPlatform.macos;
    }
    if (Platform.isAndroid) {
      return HostPlatform.android;
    }
    if (Platform.isIOS) {
      return HostPlatform.ios;
    }
    return HostPlatform.unknown;
  }
}
