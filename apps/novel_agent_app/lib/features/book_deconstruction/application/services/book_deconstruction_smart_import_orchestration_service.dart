import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_smart_import_agent_service.dart';
import 'book_deconstruction_smart_import_rule_application_service.dart';
import 'book_deconstruction_smart_import_rule_document_service.dart';
import 'book_deconstruction_smart_import_rules.dart';
import 'book_deconstruction_smart_import_result.dart';
import 'book_deconstruction_smart_import_workspace_service.dart';

class BookDeconstructionSmartImportOrchestrationService {
  BookDeconstructionSmartImportOrchestrationService({
    required BookDeconstructionSmartImportAgentService agentService,
    BookDeconstructionSmartImportWorkspaceService? workspaceService,
    ReferenceSourceDocumentFileReaderService? sourceDocumentReaderService,
    BookDeconstructionSmartImportRuleDocumentService? ruleDocumentService,
    BookDeconstructionSmartImportRuleApplicationService? ruleApplicationService,
  }) : _agentService = agentService,
       _workspaceService =
           workspaceService ??
           const BookDeconstructionSmartImportWorkspaceService(),
       _sourceDocumentReaderService =
           sourceDocumentReaderService ??
           const ReferenceSourceDocumentFileReaderService(),
       _ruleDocumentService =
           ruleDocumentService ??
           const BookDeconstructionSmartImportRuleDocumentService(),
       _ruleApplicationService =
           ruleApplicationService ??
           const BookDeconstructionSmartImportRuleApplicationService();

  final BookDeconstructionSmartImportAgentService _agentService;
  final BookDeconstructionSmartImportWorkspaceService _workspaceService;
  final ReferenceSourceDocumentFileReaderService _sourceDocumentReaderService;
  final BookDeconstructionSmartImportRuleDocumentService _ruleDocumentService;
  final BookDeconstructionSmartImportRuleApplicationService
  _ruleApplicationService;

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
    final agentResult = await _agentService.execute(
      workspace: workspace,
      providerId: providerId,
      modelId: modelId,
    );
    final parsedRules = _ruleDocumentService.parse(agentResult.rulesContent);
    final usedFallbackRules = parsedRules == null || !parsedRules.hasAnyRule;
    final rules = _resolvedRules(
      workspace: workspace,
      parsedRules: parsedRules,
    );
    final normalizedSourceText = _ruleApplicationService.apply(
      workspace: workspace,
      rules: rules,
    );
    return agentResult.copyWith(
      applied: normalizedSourceText.trim().isNotEmpty,
      normalizedSourceText: normalizedSourceText,
      note: _mergedNote(
        baseNote: agentResult.note,
        usedFallbackRules: usedFallbackRules,
        normalizedSourceText: normalizedSourceText,
      ),
    );
  }

  BookDeconstructionSmartImportRules _resolvedRules({
    required BookDeconstructionSmartImportWorkspace workspace,
    required BookDeconstructionSmartImportRules? parsedRules,
  }) {
    if (parsedRules != null && parsedRules.hasAnyRule) {
      return parsedRules;
    }
    return _ruleApplicationService.fallbackRules(workspace: workspace);
  }

  String _mergedNote({
    required String baseNote,
    required bool usedFallbackRules,
    required String normalizedSourceText,
  }) {
    final parts = <String>[
      if (baseNote.trim().isNotEmpty) baseNote.trim(),
      if (usedFallbackRules) '规则解析失败，已回退使用内置章节/噪声规则。',
      if (normalizedSourceText.trim().isEmpty) '程序未生成有效清洗正文。',
    ];
    return parts.join(' ').trim();
  }
}
