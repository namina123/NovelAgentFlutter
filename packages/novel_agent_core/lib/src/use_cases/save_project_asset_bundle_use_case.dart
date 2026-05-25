import '../assets/foreshadow_record.dart';
import '../assets/project_asset_bundle_document_service.dart';
import '../assets/style_profile.dart';
import '../common/json_types.dart';
import '../project/project_descriptor.dart';
import 'write_project_text_file_use_case.dart';

class SaveProjectAssetBundleUseCase {
  SaveProjectAssetBundleUseCase({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    ProjectAssetBundleDocumentService? bundleDocumentService,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _bundleDocumentService =
           bundleDocumentService ?? ProjectAssetBundleDocumentService();

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final ProjectAssetBundleDocumentService _bundleDocumentService;

  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required List<StyleProfile> styles,
    required List<ForeshadowRecord> foreshadows,
    String title = '',
    String description = '',
  }) async {
    // 中文注释: 资产导出用例只处理 bundle 与写盘，保持给 GUI/CLI 的调用面统一。
    final bundle = _bundleDocumentService.buildBundle(
      styles: styles,
      foreshadows: foreshadows,
      title: title,
      description: description,
    );
    final relativePath =
        'exports/${_safeFileStem('${bundle['title'] ?? ''}')}.asset_bundle.json';
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: relativePath,
      content: _bundleDocumentService.encodeBundle(bundle),
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': relativePath,
      'bundle': bundle,
      'changed_paths': <String>[relativePath],
    };
  }

  String _safeFileStem(String value) {
    var result = value.trim();
    result = result.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t ]'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'project_assets' : result;
  }
}
