import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionDraftBuilderService {
  BookDeconstructionDraftBuilderService({
    BuildBookDeconstructionDraftUseCase? buildDraftUseCase,
  }) : _buildDraftUseCase =
           buildDraftUseCase ?? BuildBookDeconstructionDraftUseCase();

  final BuildBookDeconstructionDraftUseCase _buildDraftUseCase;

  BookDeconstructionDraftBuildResult build({
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
    // 中文注释: app 层只保留薄壳转发，把正式拆书预演编排交给 core use case。
    return _buildDraftUseCase.execute(
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
  }
}
