import '../customization/customization_index_document_service.dart';
import '../customization/customization_root_catalog_service.dart';
import '../project/project_descriptor.dart';
import 'write_project_text_file_use_case.dart';

class GenerateCustomizationIndexesUseCase {
  GenerateCustomizationIndexesUseCase({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    CustomizationRootCatalogService? rootCatalogService,
    CustomizationIndexDocumentService? indexDocumentService,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _rootCatalogService =
           rootCatalogService ?? const CustomizationRootCatalogService(),
       _indexDocumentService =
           indexDocumentService ??
           CustomizationIndexDocumentService(
             rootCatalogService:
                 rootCatalogService ?? const CustomizationRootCatalogService(),
           );

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final CustomizationRootCatalogService _rootCatalogService;
  final CustomizationIndexDocumentService _indexDocumentService;

  Future<List<String>> execute(ProjectDescriptor project) async {
    // 中文注释: 索引生成只负责写四个根目录的 index.json，不混入包导入或 UI 提示逻辑。
    final writtenPaths = <String>[];
    for (final descriptor in _rootCatalogService.roots()) {
      final root = descriptor['root'] ?? '';
      if (root.trim().isEmpty) {
        continue;
      }
      final relativePath = '$root/index.json';
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: relativePath,
        content: _indexDocumentService.buildIndexDocument(root),
      );
      writtenPaths.add(relativePath);
    }
    return writtenPaths;
  }
}
