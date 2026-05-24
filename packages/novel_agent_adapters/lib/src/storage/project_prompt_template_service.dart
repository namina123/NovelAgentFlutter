import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_project_file_mutation_adapter.dart';
import 'project_json_document_service.dart';

class ProjectPromptTemplateService {
  ProjectPromptTemplateService({
    required ProjectWorkspacePort workspacePort,
    LocalProjectFileMutationAdapter? fileMutationAdapter,
    ProjectJsonDocumentService? jsonDocumentService,
    PromptTemplateNormalizerService? normalizerService,
    PromptTemplateMergeService? mergeService,
    PromptTemplatePreviewService? previewService,
    PromptTemplateCatalogService? catalogService,
  }) : _workspacePort = workspacePort,
       _fileMutationAdapter =
           fileMutationAdapter ?? LocalProjectFileMutationAdapter(),
       _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _normalizerService =
           normalizerService ?? PromptTemplateNormalizerService(),
       _mergeService = mergeService ?? PromptTemplateMergeService(),
       _previewService = previewService ?? PromptTemplatePreviewService(),
       _catalogService = catalogService ?? PromptTemplateCatalogService();

  final ProjectWorkspacePort _workspacePort;
  final LocalProjectFileMutationAdapter _fileMutationAdapter;
  final ProjectJsonDocumentService _jsonDocumentService;
  final PromptTemplateNormalizerService _normalizerService;
  final PromptTemplateMergeService _mergeService;
  final PromptTemplatePreviewService _previewService;
  final PromptTemplateCatalogService _catalogService;

  Future<List<JsonMap>> listProjectTemplates(ProjectDescriptor project) async {
    // 中文注释: 项目模板列表只扫描 prompts/，不把内置模板混进原始项目覆盖集合。
    final paths = await _jsonDocumentService.listPaths(
      project.rootPath,
      prefix: 'prompts/',
      suffix: '.json',
    );
    final result = <JsonMap>[];
    for (final path in paths) {
      final document = await _jsonDocumentService.readJsonMap(
        project.rootPath,
        path,
      );
      if (document.isEmpty) {
        continue;
      }
      final normalized = _normalizerService.normalizeTemplate(document)
        ..['relative_path'] = path;
      result.add(normalized);
    }
    result.sort((left, right) {
      return ValueReaders.stringValue(left['name']).compareTo(
        ValueReaders.stringValue(right['name']),
      );
    });
    return result;
  }

  Future<List<JsonMap>> listMergedTemplates(
    ProjectDescriptor project, {
    bool includeDefaults = true,
  }) async {
    // 中文注释: 合并视图让模板页同时看到项目覆盖与内置基线，排序和覆盖规则仍复用 core。
    final projectTemplates = await listProjectTemplates(project);
    return _mergeService.listTemplates(
      projectTemplates,
      includeDefaults: includeDefaults,
    );
  }

  Future<JsonMap> saveTemplate(ProjectDescriptor project, JsonMap template) async {
    // 中文注释: 保存模板时统一走规范化和模板路径规则，避免 UI/CLI 各自拼 prompts/ 路径。
    final normalized = _normalizerService.normalizeTemplate(template);
    final templateId = ValueReaders.stringValue(normalized['id']).trim();
    if (templateId.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Template id is required.',
        'relative_path': '',
      };
    }
    final relativePath = _normalizerService.templatePath(templateId);
    final document = ValueReaders.deepCopyMap(normalized)
      ..['relative_path'] = relativePath
      ..['updated_at'] = DateTime.now().toIso8601String();
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      relativePath,
      document,
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': relativePath,
      'template': document,
    };
  }

  Future<JsonMap> deleteProjectTemplate(
    ProjectDescriptor project,
    String templateId,
  ) async {
    // 中文注释: 删除项目覆盖只动 prompts/ 下的同名文件，不影响内置模板定义。
    final relativePath = _normalizerService.templatePath(templateId);
    if (relativePath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Template id is required.',
        'relative_path': '',
      };
    }
    final content = await _workspacePort.readTextFile(
      project.rootPath,
      relativePath,
    );
    if (content == null) {
      return <String, Object?>{
        'ok': false,
        'error': 'Template override not found.',
        'relative_path': relativePath,
      };
    }
    await _fileMutationAdapter.deleteEntry(project.rootPath, relativePath);
    return <String, Object?>{
      'ok': true,
      'relative_path': relativePath,
    };
  }

  Future<JsonMap> restoreDefaultTemplate(
    ProjectDescriptor project,
    String templateId,
  ) async {
    // 中文注释: 恢复默认的实现是把内置模板写成项目覆盖，保证用户仍可继续二次编辑。
    final template = _catalogService.defaultTemplate(templateId);
    if (template.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Builtin template not found.',
        'relative_path': '',
      };
    }
    return saveTemplate(project, template);
  }

  Future<JsonMap> preview(
    ProjectDescriptor project,
    String templateId,
    JsonMap variables,
  ) async {
    // 中文注释: 预览不依赖 UI 状态，GUI 和 CLI 都能直接给模板 id 与变量字典拿结果。
    final templates = await listProjectTemplates(project);
    return _previewService.previewById(templateId, templates, variables);
  }
}
