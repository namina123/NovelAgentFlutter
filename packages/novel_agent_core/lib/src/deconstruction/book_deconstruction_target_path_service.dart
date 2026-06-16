import '../inspiration/inspiration_premise.dart';
import 'book_deconstruction_artifact_kind.dart';
import 'book_deconstruction_chapter_outline.dart';

class BookDeconstructionTargetPathService {
  const BookDeconstructionTargetPathService();

  String sourceArchivePath(String sourceAbsolutePath) {
    // 中文注释: 原文归档路径统一收口在 sources/original/，避免拆书源文本继续散在内存或正文目录里。
    final normalized = sourceAbsolutePath.replaceAll('\\', '/').trim();
    final fileName = normalized.split('/').last;
    final separatorIndex = fileName.lastIndexOf('.');
    final stem = separatorIndex > 0
        ? fileName.substring(0, separatorIndex)
        : fileName;
    final cleanStem = _safeId(stem);
    return 'sources/original/book_deconstruction_source_$cleanStem.md';
  }

  String previewPath() {
    // 中文注释: 预演纪要统一写入 analysis/，保持它与正文层和原文层隔离。
    return 'analysis/book_deconstruction_preview.md';
  }

  String followupPlanPath(String followupOptionId) {
    final cleanId = _safeId(followupOptionId);
    return '.novel_agent/state/book_deconstruction/followups/$cleanId.plan.json';
  }

  String followupGuidePath(String followupOptionId) {
    final cleanId = _safeId(followupOptionId);
    return 'tasks/plans/book_deconstruction_followups/$cleanId.md';
  }

  String inheritedChapterPath({
    required String followupOptionId,
    required int sequence,
    required String title,
  }) {
    final safeRoute = _safeId(followupOptionId);
    final safeTitle = _safeId(title);
    final normalizedTitle = safeTitle.isEmpty ? '原作片段' : safeTitle;
    final chapterNumber = sequence <= 0 ? 1 : sequence;
    return 'chapters/inherited/$safeRoute/${chapterNumber.toString().padLeft(3, '0')}_$normalizedTitle.md';
  }

  String premisePath(InspirationPremise premise, int index) {
    // 中文注释: 拆书前提默认回到现有 premise/ 目录，后续 UI/adapter 只需消费稳定路径提示即可。
    final suffix = index <= 0 ? 1 : index;
    return 'premise/book_deconstruction_premise_$suffix.md';
  }

  String storyOutlinePath() {
    // 中文注释: 总体故事结构继续落到 outlines/story/，避免拆书结果另起一套目录协议。
    return 'outlines/story/book_deconstruction_story_outline.md';
  }

  String chapterOutlinePath(
    BookDeconstructionChapterOutline outline,
    int index,
  ) {
    // 中文注释: 章级骨架沿用 outlines/chapters/，让后续一般小说与长任务都能直接复用。
    final sequence = outline.sequence > 0 ? outline.sequence : index;
    return 'outlines/chapters/book_deconstruction_chapter_$sequence.md';
  }

  String assetPath(String artifactKind, String assetId) {
    // 中文注释: 结构化资产路径统一在这里推导，后续若目录策略调整，只改这一层。
    final cleanId = _safeId(assetId);
    switch (artifactKind) {
      case BookDeconstructionArtifactKind.styleProfile:
        return 'assets/styles/$cleanId.md';
      case BookDeconstructionArtifactKind.worldRuleSet:
        return 'assets/world/$cleanId.md';
      case BookDeconstructionArtifactKind.characterProfile:
        return 'assets/characters/$cleanId.md';
      case BookDeconstructionArtifactKind.organizationProfile:
        return 'assets/organizations/$cleanId.md';
      case BookDeconstructionArtifactKind.foreshadowRecord:
        return 'assets/foreshadows/$cleanId.foreshadow.md';
      case BookDeconstructionArtifactKind.timelineRecord:
        return 'assets/timeline/$cleanId.timeline.md';
      case BookDeconstructionArtifactKind.relationshipRecord:
        return 'assets/relationships/$cleanId.relationship.md';
      default:
        return '';
    }
  }

  String _safeId(String value) {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) {
      return 'book_deconstruction_asset';
    }
    // 中文注释: 这里保留中文等可读字符，仅清理路径危险字符与连续空白，避免显示名映射的资产路径失真。
    return cleanValue
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
