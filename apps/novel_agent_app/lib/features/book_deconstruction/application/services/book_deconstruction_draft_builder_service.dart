import 'dart:isolate';

import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionDraftBuilderService {
  BookDeconstructionDraftBuilderService();

  Future<BookDeconstructionDraftBuildResult> build({
    required String sourceTitle,
    required String sourceContent,
    required String sourceAbsolutePath,
    required String operatorNotes,
    required String styleSummary,
    required String worldRulesText,
    required String characterLinesText,
    required String organizationLinesText,
    BookDeconstructionContinuationDirection preferredContinuationDirection =
        BookDeconstructionContinuationDirection.analysisFirst,
  }) {
    // 中文注释: 预演构建会扫描整份源文稿并生成大量结构对象，放到 isolate 里避免 UI 卡死。
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
}
