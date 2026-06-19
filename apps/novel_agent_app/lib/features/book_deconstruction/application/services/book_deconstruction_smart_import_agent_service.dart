import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../workbench/application/controllers/generate_draft_use_case_factory.dart';
import 'book_deconstruction_smart_import_result.dart';
import 'book_deconstruction_smart_import_workspace_service.dart';

class BookDeconstructionSmartImportAgentService {
  BookDeconstructionSmartImportAgentService({
    required AppSettings? Function() readSettings,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    ModelExecutionProfileService? modelExecutionProfileService,
  }) : _readSettings = readSettings,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService();

  final AppSettings? Function() _readSettings;
  final GenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final ModelExecutionProfileService _modelExecutionProfileService;

  static const List<String> _exposedToolIds = <String>[
    'list_project_files',
    'read_project_file',
    'write_project_file',
    'edit_project_file',
    'manipulate_project_file_lines',
  ];

  Future<BookDeconstructionSmartImportResult> execute({
    required BookDeconstructionSmartImportWorkspace workspace,
    required String providerId,
    required String modelId,
  }) async {
    final settings = _readSettings();
    if (settings == null) {
      return const BookDeconstructionSmartImportResult(
        applied: false,
        normalizedSourceText: '',
        note: '智能拆书未执行：当前没有可用的应用设置。',
      );
    }
    ProviderEndpointSettings? provider;
    for (final item in settings.providers) {
      if (item.id == providerId) {
        provider = item;
        break;
      }
    }
    if (provider == null) {
      return BookDeconstructionSmartImportResult(
        applied: false,
        normalizedSourceText: '',
        note: '智能拆书未执行：未找到 provider `$providerId`。',
        tempWorkspaceRootPath: workspace.rootPath,
      );
    }
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      overrideModelId: modelId,
    );
    final resolvedModelId = ValueReaders.stringValue(
      executionProfile['resolved_model_id'],
    ).trim();
    if (resolvedModelId.isEmpty) {
      return BookDeconstructionSmartImportResult(
        applied: false,
        normalizedSourceText: '',
        note: '智能拆书未执行：未解析到可用模型。',
        tempWorkspaceRootPath: workspace.rootPath,
      );
    }

    final useCase = _generateDraftUseCaseFactory(
      provider,
      settings.networkSettings,
    );
    await useCase.execute(
      project: workspace.tempProject,
      userPrompt:
          '请按 task.md 的要求完成拆书导入清洗，只处理导入文件，并把产物写到 outputs/normalized_source.md 与 outputs/import_report.md。',
      modelId: resolvedModelId,
      intent: 'book_deconstruction_import',
      title: '拆书导入智能清洗',
      exposedToolIds: _exposedToolIds,
    );

    final workspacePort = LocalProjectWorkspacePort();
    final normalizedSourceText =
        await workspacePort.readTextFile(
          workspace.tempProject.rootPath,
          'outputs/normalized_source.md',
        ) ??
        '';
    final reportPath = 'outputs/import_report.md';
    final reportContent =
        await workspacePort.readTextFile(
          workspace.tempProject.rootPath,
          reportPath,
        ) ??
        '';
    if (normalizedSourceText.trim().isEmpty) {
      return BookDeconstructionSmartImportResult(
        applied: false,
        normalizedSourceText: '',
        reportPath: reportContent.trim().isEmpty ? '' : reportPath,
        reportContent: reportContent,
        tempWorkspaceRootPath: workspace.rootPath,
        note: '智能拆书未按约定写出 outputs/normalized_source.md。',
      );
    }
    return BookDeconstructionSmartImportResult(
      applied: true,
      normalizedSourceText: normalizedSourceText,
      reportPath: reportContent.trim().isEmpty ? '' : reportPath,
      reportContent: reportContent,
      tempWorkspaceRootPath: workspace.rootPath,
      note: reportContent.trim().isEmpty ? '' : '智能拆书报告已生成。',
    );
  }
}
