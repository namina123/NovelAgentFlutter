import 'dart:isolate';

import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionDraftBuilderService {
  BookDeconstructionDraftBuilderService();

  Future<BookDeconstructionDraftBuildResult> build({
    required String sourceTitle,
    required String sourceContent,
    required String sourceAbsolutePath,
    String operatorNotes = '',
    String styleSummary = '',
    String worldRulesText = '',
    String characterLinesText = '',
    String organizationLinesText = '',
    BookDeconstructionContinuationDirection preferredContinuationDirection =
        BookDeconstructionContinuationDirection.analysisFirst,
    bool extractKnowledge = true,
  }) {
    // 中文注释: 预演构建会扫描整份源文稿并生成大量结构对象，放到 isolate 里避免 UI 卡死。
    // extractKnowledge=false = 纯拆书（默认 GUI 拆书按钮走这条）；true = 可选的知识抽取。
    final request = _BookDeconstructionDraftBuildRequest(
      sourceTitle: sourceTitle,
      sourceContent: sourceContent,
      sourceAbsolutePath: sourceAbsolutePath,
      operatorNotes: operatorNotes,
      styleSummary: styleSummary,
      worldRulesText: worldRulesText,
      characterLinesText: characterLinesText,
      organizationLinesText: organizationLinesText,
      preferredContinuationDirection: preferredContinuationDirection,
      extractKnowledge: extractKnowledge,
    );
    return Isolate.run(() => _buildDraftInIsolate(request));
  }
}

BookDeconstructionDraftBuildResult _buildDraftInIsolate(
  _BookDeconstructionDraftBuildRequest request,
) {
  return BuildBookDeconstructionDraftUseCase().execute(
    sourceTitle: request.sourceTitle,
    sourceContent: request.sourceContent,
    sourceAbsolutePath: request.sourceAbsolutePath,
    operatorNotes: request.operatorNotes,
    styleSummary: request.styleSummary,
    worldRulesText: request.worldRulesText,
    characterLinesText: request.characterLinesText,
    organizationLinesText: request.organizationLinesText,
    preferredContinuationDirection: request.preferredContinuationDirection,
    extractKnowledge: request.extractKnowledge,
  );
}

class _BookDeconstructionDraftBuildRequest {
  const _BookDeconstructionDraftBuildRequest({
    required this.sourceTitle,
    required this.sourceContent,
    required this.sourceAbsolutePath,
    required this.operatorNotes,
    required this.styleSummary,
    required this.worldRulesText,
    required this.characterLinesText,
    required this.organizationLinesText,
    required this.preferredContinuationDirection,
    required this.extractKnowledge,
  });

  final String sourceTitle;
  final String sourceContent;
  final String sourceAbsolutePath;
  final String operatorNotes;
  final String styleSummary;
  final String worldRulesText;
  final String characterLinesText;
  final String organizationLinesText;
  final BookDeconstructionContinuationDirection preferredContinuationDirection;
  final bool extractKnowledge;
}
