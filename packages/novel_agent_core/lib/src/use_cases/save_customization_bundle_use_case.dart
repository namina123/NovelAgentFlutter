import '../common/json_types.dart';
import '../customization/customization_bundle_document_service.dart';
import '../project/project_descriptor.dart';
import 'write_project_text_file_use_case.dart';

class SaveCustomizationBundleUseCase {
  SaveCustomizationBundleUseCase({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    CustomizationBundleDocumentService? bundleDocumentService,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _bundleDocumentService =
           bundleDocumentService ?? const CustomizationBundleDocumentService();

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final CustomizationBundleDocumentService _bundleDocumentService;

  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required List<JsonMap> agents,
    required List<JsonMap> skills,
    required List<JsonMap> skillGroups,
    required List<JsonMap> agentGroups,
    String title = '',
    String description = '',
  }) async {
    // 中文注释: 导出用例只依赖共享 bundle 文档和项目写盘，不在外层重复实现文件名规则。
    final bundle = _bundleDocumentService.buildBundle(
      agents: agents,
      skills: skills,
      skillGroups: skillGroups,
      agentGroups: agentGroups,
      title: title,
      description: description,
    );
    final bundleTitle = (bundle['title'] ?? '').toString();
    final relativePath = 'exports/${_safeFileStem(bundleTitle)}.customization.json';
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: relativePath,
      content: _bundleDocumentService.encodeBundle(bundle),
    );
    return <String, Object?>{
      'ok': true,
      'bundle': bundle,
      'relative_path': relativePath,
      'changed_paths': <String>[relativePath],
    };
  }

  String _safeFileStem(String value) {
    var result = value.trim();
    result = result.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t ]'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    if (result.isEmpty) {
      return 'customization_bundle';
    }
    return result.length <= 96 ? result : result.substring(0, 96);
  }
}
