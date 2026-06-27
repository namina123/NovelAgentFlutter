import 'dart:isolate';

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
    final normalizedSourceText = await _applyRulesInBackground(
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

  Future<String> _applyRulesInBackground({
    required BookDeconstructionSmartImportWorkspace workspace,
    required BookDeconstructionSmartImportRules rules,
  }) async {
    // 中文注释: 规则去噪对整本书逐行跑多个正则，是 CPU 密集同步操作；放进 isolate 跑，
    // 避免拆书时卡死主线程。service 是 const 无状态纯函数，workspace/rules 是纯值对象，
    // 可安全跨 isolate 传递。
    return Isolate.run(() {
      return const BookDeconstructionSmartImportRuleApplicationService().apply(
        workspace: workspace,
        rules: rules,
      );
    });
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
