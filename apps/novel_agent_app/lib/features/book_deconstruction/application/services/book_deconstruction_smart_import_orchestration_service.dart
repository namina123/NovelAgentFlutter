import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_smart_import_agent_service.dart';
import 'book_deconstruction_smart_import_result.dart';
import 'book_deconstruction_smart_import_workspace_service.dart';

class BookDeconstructionSmartImportOrchestrationService {
  BookDeconstructionSmartImportOrchestrationService({
    required BookDeconstructionSmartImportAgentService agentService,
    BookDeconstructionSmartImportWorkspaceService? workspaceService,
    ReferenceSourceDocumentFileReaderService? sourceDocumentReaderService,
  }) : _agentService = agentService,
       _workspaceService =
           workspaceService ?? const BookDeconstructionSmartImportWorkspaceService(),
       _sourceDocumentReaderService =
           sourceDocumentReaderService ??
           const ReferenceSourceDocumentFileReaderService();

  final BookDeconstructionSmartImportAgentService _agentService;
  final BookDeconstructionSmartImportWorkspaceService _workspaceService;
  final ReferenceSourceDocumentFileReaderService _sourceDocumentReaderService;

  Future<BookDeconstructionSmartImportResult> execute({
    required ProjectDescriptor project,
    required List<String> sourcePaths,
    required String providerId,
    required String modelId,
  }) async {
    final workspace = await _workspaceService.create(
      project: project,
      sourcePaths: sourcePaths,
      sourceDocumentReaderService: _sourceDocumentReaderService,
    );
    return _agentService.execute(
      workspace: workspace,
      providerId: providerId,
      modelId: modelId,
    );
  }
}
