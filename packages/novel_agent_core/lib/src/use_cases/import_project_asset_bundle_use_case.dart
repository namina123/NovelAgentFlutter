import '../assets/foreshadow_record_markdown_codec_service.dart';
import '../assets/foreshadow_record_normalizer_service.dart';
import '../assets/project_asset_bundle_document_service.dart';
import '../assets/style_profile_markdown_codec_service.dart';
import '../assets/style_profile_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../ports/project_tool_host_port.dart';
import '../project/project_descriptor.dart';

class ImportProjectAssetBundleUseCase {
  ImportProjectAssetBundleUseCase({
    required ProjectToolHostPort projectToolHostPort,
    ProjectAssetBundleDocumentService? bundleDocumentService,
    StyleProfileNormalizerService? styleNormalizerService,
    ForeshadowRecordNormalizerService? foreshadowNormalizerService,
    StyleProfileMarkdownCodecService? styleCodecService,
    ForeshadowRecordMarkdownCodecService? foreshadowCodecService,
  }) : _projectToolHostPort = projectToolHostPort,
       _bundleDocumentService =
           bundleDocumentService ?? ProjectAssetBundleDocumentService(),
       _styleNormalizerService =
           styleNormalizerService ?? const StyleProfileNormalizerService(),
       _foreshadowNormalizerService =
           foreshadowNormalizerService ??
           const ForeshadowRecordNormalizerService(),
       _styleCodecService =
           styleCodecService ?? StyleProfileMarkdownCodecService(),
       _foreshadowCodecService =
           foreshadowCodecService ?? ForeshadowRecordMarkdownCodecService();

  final ProjectToolHostPort _projectToolHostPort;
  final ProjectAssetBundleDocumentService _bundleDocumentService;
  final StyleProfileNormalizerService _styleNormalizerService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;
  final StyleProfileMarkdownCodecService _styleCodecService;
  final ForeshadowRecordMarkdownCodecService _foreshadowCodecService;

  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required String bundleContent,
    bool overwrite = true,
  }) async {
    // 中文注释: 资产包导入统一落成标准项目文件，后续图谱、上下文和任务策略都可直接复用这些路径。
    final bundle = _bundleDocumentService.parseBundle(bundleContent);
    if (bundle.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'summary': '资产包内容无效。',
        'changed_paths': const <Object?>[],
      };
    }
    final changedPaths = <String>[];
    for (final rawStyle in ValueReaders.mapList(bundle['styles'])) {
      final style = _styleNormalizerService.normalize(
        ValueReaders.mapValue(rawStyle),
      );
      if (style.id.trim().isEmpty) {
        continue;
      }
      final relativePath = 'assets/styles/${style.id}.style.md';
      final exists = await _projectToolHostPort.entryExists(
        project.rootPath,
        relativePath,
      );
      if (exists && !overwrite) {
        continue;
      }
      await _projectToolHostPort.writeTextFile(
        project.rootPath,
        relativePath,
        _styleCodecService.encode(style),
      );
      changedPaths.add(relativePath);
    }
    await _projectToolHostPort.createDirectory(project.rootPath, 'assets/foreshadows');
    for (final rawRecord in ValueReaders.mapList(bundle['foreshadows'])) {
      final record = _foreshadowNormalizerService.normalize(
        ValueReaders.mapValue(rawRecord),
      );
      if (record.id.trim().isEmpty) {
        continue;
      }
      final relativePath = 'assets/foreshadows/${record.id}.foreshadow.md';
      final exists = await _projectToolHostPort.entryExists(
        project.rootPath,
        relativePath,
      );
      if (exists && !overwrite) {
        continue;
      }
      await _projectToolHostPort.writeTextFile(
        project.rootPath,
        relativePath,
        _foreshadowCodecService.encode(record),
      );
      changedPaths.add(relativePath);
    }
    return <String, Object?>{
      'ok': changedPaths.isNotEmpty,
      'summary': changedPaths.isEmpty
          ? '没有导入任何资产。'
          : '已导入 ${changedPaths.length} 个资产文件。',
      'changed_paths': changedPaths,
    };
  }
}
