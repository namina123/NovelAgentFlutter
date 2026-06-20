import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_smart_import_contract.dart';
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
    final result = await useCase.execute(
      project: workspace.tempProject,
      userPrompt:
          '请按 ${BookDeconstructionSmartImportContract.taskRelativePath} 的要求完成拆书导入分析，只处理导入文件，并把规则写到 ${BookDeconstructionSmartImportContract.rulesPath}，说明写到 ${BookDeconstructionSmartImportContract.reportPath}。',
      modelId: resolvedModelId,
      intent: 'book_deconstruction_import',
      title: '拆书导入规则分析',
      exposedToolIds: _exposedToolIds,
    );

    final workspacePort = LocalProjectWorkspacePort();
    const rulesPath = BookDeconstructionSmartImportContract.rulesPath;
    var rulesContent =
        await workspacePort.readTextFile(
          workspace.tempProject.rootPath,
          rulesPath,
        ) ??
        '';
    var normalizedSourceText =
        await workspacePort.readTextFile(
          workspace.tempProject.rootPath,
          BookDeconstructionSmartImportContract.normalizedSourcePath,
        ) ??
        '';
    const reportPath = BookDeconstructionSmartImportContract.reportPath;
    var reportContent =
        await workspacePort.readTextFile(
          workspace.tempProject.rootPath,
          reportPath,
        ) ??
        '';
    final noteParts = <String>[];
    if (result.stoppedByToolError &&
        result.toolErrorSummary.trim().isNotEmpty) {
      noteParts.add('智能拆书工具调用未完全成功：${result.toolErrorSummary.trim()}');
    }
    if (rulesContent.trim().isEmpty) {
      final fallbackText = _fallbackRulesContent(result);
      if (fallbackText.isNotEmpty) {
        rulesContent = fallbackText;
        noteParts.add('智能拆书未按约定落盘规则文件，已回退使用模型返回内容解析规则。');
      }
    }
    if (reportContent.trim().isEmpty) {
      reportContent = _fallbackReportContent(
        result: result,
        providerId: providerId,
        resolvedModelId: resolvedModelId,
        usedDraftFallback: noteParts.any(
          (part) => part.contains('回退使用模型返回内容解析规则'),
        ),
      );
    }
    if (rulesContent.trim().isEmpty) {
      return BookDeconstructionSmartImportResult(
        applied: false,
        normalizedSourceText: normalizedSourceText,
        rulesPath: '',
        rulesContent: '',
        reportPath: reportContent.trim().isEmpty ? '' : reportPath,
        reportContent: reportContent,
        tempWorkspaceRootPath: workspace.rootPath,
        note: noteParts.isEmpty
            ? '智能拆书未按约定写出 ${BookDeconstructionSmartImportContract.rulesPath}。'
            : noteParts.join(' '),
      );
    }
    if (reportContent.trim().isNotEmpty) {
      noteParts.add('智能拆书报告已生成。');
    }
    return BookDeconstructionSmartImportResult(
      applied: true,
      normalizedSourceText: normalizedSourceText,
      rulesPath: rulesPath,
      rulesContent: rulesContent,
      reportPath: reportContent.trim().isEmpty ? '' : reportPath,
      reportContent: reportContent,
      tempWorkspaceRootPath: workspace.rootPath,
      note: noteParts.join(' '),
    );
  }

  String _fallbackRulesContent(DraftGenerationResult result) {
    final draftText = result.draftMarkdown.trim();
    if (draftText.isEmpty || result.waitingForUserChoice) {
      return '';
    }
    return draftText;
  }

  String _fallbackReportContent({
    required DraftGenerationResult result,
    required String providerId,
    required String resolvedModelId,
    required bool usedDraftFallback,
  }) {
    final changedPaths = <String>{
      ...result.writtenPaths
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty),
      ...result.changedPaths
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty),
    }.toList(growable: false);
    if (changedPaths.isEmpty &&
        result.toolErrorSummary.trim().isEmpty &&
        !usedDraftFallback) {
      return '';
    }
    final buffer = StringBuffer()
      ..writeln('# 智能拆书执行报告')
      ..writeln()
      ..writeln('- provider: $providerId')
      ..writeln('- model: $resolvedModelId')
      ..writeln('- 等待用户选择: ${result.waitingForUserChoice ? '是' : '否'}')
      ..writeln('- 工具错误停止: ${result.stoppedByToolError ? '是' : '否'}')
      ..writeln('- 使用正文兜底: ${usedDraftFallback ? '是' : '否'}');
    final toolErrorSummary = result.toolErrorSummary.trim();
    if (toolErrorSummary.isNotEmpty) {
      buffer.writeln('- 工具错误摘要: $toolErrorSummary');
    }
    if (changedPaths.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## 变更路径');
      for (final path in changedPaths) {
        buffer.writeln('- $path');
      }
    }
    return buffer.toString().trimRight();
  }
}
