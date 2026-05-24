import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../customization/customization_market_index_document_service.dart';
import '../ports/project_tool_host_port.dart';
import '../project/project_descriptor.dart';
import 'write_project_text_file_use_case.dart';

class SaveCustomizationMarketIndexUseCase {
  SaveCustomizationMarketIndexUseCase({
    required ProjectToolHostPort projectToolHostPort,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    CustomizationMarketIndexDocumentService? marketIndexDocumentService,
  }) : _projectToolHostPort = projectToolHostPort,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _marketIndexDocumentService =
           marketIndexDocumentService ??
           const CustomizationMarketIndexDocumentService();

  final ProjectToolHostPort _projectToolHostPort;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final CustomizationMarketIndexDocumentService _marketIndexDocumentService;

  Future<JsonMap> execute(ProjectDescriptor project) async {
    // 中文注释: 市场索引只扫描 exports/ 下的生态包文件，供后续分享与浏览使用。
    final entries = await _projectToolHostPort.listEntries(
      project.rootPath,
      recursive: true,
    );
    final bundles = <JsonMap>[];
    for (final entry in entries) {
      final relativePath = ValueReaders.stringValue(
        entry['relative_path'],
      ).trim();
      final isDirectory = ValueReaders.boolValue(entry['is_dir']);
      if (isDirectory ||
          !relativePath.startsWith('exports/') ||
          !relativePath.endsWith('.customization.json')) {
        continue;
      }
      final content = await _projectToolHostPort.readTextFile(
        project.rootPath,
        relativePath,
      );
      if ((content ?? '').trim().isEmpty) {
        continue;
      }
      try {
        final bundle = ValueReaders.mapValue(jsonDecode(content!));
        if (ValueReaders.stringValue(bundle['kind']) !=
            'novel_agent_customization_bundle') {
          continue;
        }
        bundles.add(<String, Object?>{
          ...bundle,
          'relative_path': relativePath,
        });
      } catch (_) {
        continue;
      }
    }
    final index = _marketIndexDocumentService.buildLocalIndex(bundles);
    const jsonPath = 'exports/market_index.json';
    const markdownPath = 'exports/market_index.md';
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: jsonPath,
      content: _marketIndexDocumentService.encodeIndex(index),
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: markdownPath,
      content: _marketIndexDocumentService.renderMarkdown(index),
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': jsonPath,
      'markdown_path': markdownPath,
      'index': index,
      'changed_paths': const <String>[jsonPath, markdownPath],
    };
  }
}
