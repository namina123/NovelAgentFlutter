import 'package:novel_agent_core/novel_agent_core.dart';

import '../controllers/generate_draft_use_case_factory.dart';
import 'project_import_smart_analysis_agent_result.dart';

class ProjectImportSmartAnalysisAgentService {
  ProjectImportSmartAnalysisAgentService({
    required AppSettings? Function() readSettings,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    required ProjectToolHostPort projectToolHostPort,
    ModelExecutionProfileService? modelExecutionProfileService,
  }) : _readSettings = readSettings,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _projectToolHostPort = projectToolHostPort,
       _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService();

  final AppSettings? Function() _readSettings;
  final GenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final ProjectToolHostPort _projectToolHostPort;
  final ModelExecutionProfileService _modelExecutionProfileService;

  static const String reportRelativePath =
      'analysis/project_import_analysis.md';
  static const List<String> _exposedToolIds = <String>[
    'list_project_files',
    'read_project_file',
    'get_project_file_info',
    'search_project_files',
    'write_project_file',
    'edit_project_file',
    'manipulate_project_file_lines',
  ];

  Future<ProjectImportSmartAnalysisAgentResult> execute({
    required ProjectDescriptor project,
    required List<String> importedPaths,
    required String providerId,
    required String modelId,
  }) async {
    final settings = _readSettings();
    if (settings == null) {
      return const ProjectImportSmartAnalysisAgentResult(
        applied: false,
        note: '智能分析未执行：当前没有可用的应用设置。',
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
      return ProjectImportSmartAnalysisAgentResult(
        applied: false,
        note: '智能分析未执行：未找到对应的接口配置。',
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
      return const ProjectImportSmartAnalysisAgentResult(
        applied: false,
        note: '智能分析未执行：未解析到可用模型。',
      );
    }

    final useCase = _generateDraftUseCaseFactory(
      provider,
      settings.networkSettings,
    );
    await useCase.execute(
      project: project,
      userPrompt: _promptFor(importedPaths),
      modelId: resolvedModelId,
      intent: 'project_import_analysis',
      title: '导入资料智能分析',
      exposedToolIds: _exposedToolIds,
    );
    final reportContent =
        await _projectToolHostPort.readTextFile(
          project.rootPath,
          reportRelativePath,
        ) ??
        '';
    if (reportContent.trim().isEmpty) {
      return ProjectImportSmartAnalysisAgentResult(
        applied: false,
        resolvedModelId: resolvedModelId,
        note: '智能分析未按约定写出 $reportRelativePath。',
      );
    }
    return ProjectImportSmartAnalysisAgentResult(
      applied: true,
      reportPath: reportRelativePath,
      reportContent: reportContent,
      resolvedModelId: resolvedModelId,
    );
  }

  String _promptFor(List<String> importedPaths) {
    final normalizedPaths = importedPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final bulletList = normalizedPaths.map((path) => '- $path').join('\n');
    return [
      '你是内置的导入资料分析智能体。你的身份固定，不需要也不允许让用户选择 agent。',
      '你的任务只限于分析本次刚导入的资料，不要改写其他项目文件。',
      '先只读取下面这些已导入路径，必要时可用搜索工具辅助定位，但不要发散读取无关目录：',
      bulletList,
      '然后把最终结果写入 analysis/project_import_analysis.md。',
      '报告必须包含：',
      '1. 顶部说明你使用的是内置导入分析智能体。',
      '2. 每个导入文件/目录条目的类型判断。',
      '3. 每个条目的判断依据。',
      '4. 建议把它当作正文、设定、大纲、角色资料、参考资料还是语料来使用。',
      '5. 对明显混杂或需要人工确认的条目单独标注风险。',
      '除写出这份报告外，不要创建或修改别的文件。',
    ].join('\n');
  }
}
