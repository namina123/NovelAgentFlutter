import '../project/project_storage_strategy.dart';
import '../project/project_storage_strategy_path_policy_service.dart';
import '../inspiration/inspiration_premise.dart';
import 'book_deconstruction_artifact_kind.dart';
import 'book_deconstruction_chapter_outline.dart';

class BookDeconstructionTargetPathService {
  const BookDeconstructionTargetPathService({
    ProjectStorageStrategyPathPolicyService? storageStrategyPathPolicyService,
  }) : _storageStrategyPathPolicyService =
           storageStrategyPathPolicyService ??
           const ProjectStorageStrategyPathPolicyService();

  final ProjectStorageStrategyPathPolicyService
  _storageStrategyPathPolicyService;

  String sourceArchivePath(
    String sourceAbsolutePath, {
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 原文归档路径统一收口在 sources/original/，避免拆书源文本继续散在内存或正文目录里。
    final normalized = sourceAbsolutePath.replaceAll('\\', '/').trim();
    final fileName = normalized.split('/').last;
    final separatorIndex = fileName.lastIndexOf('.');
    final stem = separatorIndex > 0
        ? fileName.substring(0, separatorIndex)
        : fileName;
    final cleanStem = _safeId(stem);
    return '${_storageStrategyPathPolicyService.directoryForContentType(storageStrategy: storageStrategy, contentType: 'source_original')}/book_deconstruction_source_$cleanStem.md';
  }

  String previewPath({
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 预演纪要统一写入 analysis/，保持它与正文层和原文层隔离。
    return '${_storageStrategyPathPolicyService.directoryForContentType(storageStrategy: storageStrategy, contentType: 'analysis')}/book_deconstruction_preview.md';
  }

  String structuredSourcePath({
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    return '${_storageStrategyPathPolicyService.directoryForContentType(storageStrategy: storageStrategy, contentType: 'analysis')}/book_deconstruction_structured_source.md';
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
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    final safeRoute = _safeId(followupOptionId);
    final safeTitle = _safeId(title);
    final normalizedTitle = safeTitle.isEmpty ? '原作片段' : safeTitle;
    final chapterNumber = sequence <= 0 ? 1 : sequence;
    final derivedRoot = safeRoute.contains('fanfic')
        ? _storageStrategyPathPolicyService.directoryForContentType(
            storageStrategy: storageStrategy,
            contentType: 'derived_fanfic_narrative',
          )
        : _storageStrategyPathPolicyService.directoryForContentType(
            storageStrategy: storageStrategy,
            contentType: 'derived_continuation_narrative',
          );
    return '$derivedRoot/$safeRoute/${chapterNumber.toString().padLeft(3, '0')}_$normalizedTitle.md';
  }

  String liveChapterPath({
    required int sequence,
    required String title,
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 续写路线把分好的正文写进正文区域（chapters/，对应 document_kind='chapter'），
    // 而不是 inherited/ 镜像目录。文件名带可解析的"第N章"，让续写上下文优先级服务
    // （ProjectChapterContinuityPriorityService）能把它识别为已存在的前情正文并给高权重。
    final chapterNumber = sequence <= 0 ? 1 : sequence;
    final root = _storageStrategyPathPolicyService.directoryForContentType(
      storageStrategy: storageStrategy,
      contentType: 'chapter',
    );
    final safeTitle = _safeId(title);
    final hasChapterMarker = RegExp(
      r'第\s*([0-9０-９零〇一二三四五六七八九十百千万两]+)\s*章',
    ).hasMatch(title);
    if (hasChapterMarker) {
      // 标题本身已含"第N章"（如"第一章 港口风暴"），直接用作文件名，可被优先级解析。
      return safeTitle.isEmpty
          ? '$root/第$chapterNumber章.md'
          : '$root/$safeTitle.md';
    }
    // 标题没有章节标记时，用序号合成可解析的"第N章"前缀。
    return safeTitle.isEmpty
        ? '$root/第$chapterNumber章.md'
        : '$root/第${chapterNumber}章_$safeTitle.md';
  }

  String resourceChapterPath({
    required int sequence,
    required String title,
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 非续写场景把分章作为参考资料写入 analysis/（与 preview/structured_source 同目录），
    // 不进正文 chapters/、也不进 inherited/ 镜像——分章只是拆书分析产物，不该污染创作正文层。
    final chapterNumber = sequence <= 0 ? 1 : sequence;
    final root = _storageStrategyPathPolicyService.directoryForContentType(
      storageStrategy: storageStrategy,
      contentType: 'analysis',
    );
    final safeTitle = _safeId(title);
    final titleSuffix = safeTitle.isEmpty ? '' : '_$safeTitle';
    return '$root/book_deconstruction_chapter_${chapterNumber.toString().padLeft(3, '0')}$titleSuffix.md';
  }

  String premisePath(
    InspirationPremise premise,
    int index, {
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 拆书前提默认回到现有 premise/ 目录，后续 UI/adapter 只需消费稳定路径提示即可。
    final suffix = index <= 0 ? 1 : index;
    final sourceStem = _safeId(
      premise.sourcePath.trim().isEmpty
          ? premise.displayName.trim()
          : premise.sourcePath.trim().split('/').last,
    );
    final cleanStem = sourceStem.isEmpty
        ? 'book_deconstruction_premise'
        : sourceStem;
    final root = _storageStrategyPathPolicyService.directoryForContentType(
      storageStrategy: storageStrategy,
      contentType: 'premise',
    );
    return '$root/book_deconstruction_premise_${suffix}_$cleanStem.md';
  }

  String storyOutlinePath({
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 总体故事结构继续落到 outlines/story/，避免拆书结果另起一套目录协议。
    return '${_storageStrategyPathPolicyService.directoryForContentType(storageStrategy: storageStrategy, contentType: 'outline')}/book_deconstruction_story_outline.md';
  }

  String chapterOutlinePath(
    BookDeconstructionChapterOutline outline,
    int index, {
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 章级骨架沿用 outlines/chapters/，让后续一般小说与长任务都能直接复用。
    final sequence = outline.sequence > 0 ? outline.sequence : index;
    return '${_storageStrategyPathPolicyService.directoryForContentType(storageStrategy: storageStrategy, contentType: 'chapter_outline')}/book_deconstruction_chapter_$sequence.md';
  }

  String assetPath(
    String artifactKind,
    String assetId, {
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 结构化资产路径统一在这里推导，后续若目录策略调整，只改这一层。
    final cleanId = _safeId(assetId);
    switch (artifactKind) {
      case BookDeconstructionArtifactKind.styleProfile:
        return '${_storageStrategyPathPolicyService.directoryForContentType(storageStrategy: storageStrategy, contentType: 'style')}/$cleanId.md';
      case BookDeconstructionArtifactKind.worldRuleSet:
        return '${_storageStrategyPathPolicyService.directoryForContentType(storageStrategy: storageStrategy, contentType: 'setting')}/$cleanId.md';
      case BookDeconstructionArtifactKind.characterProfile:
        return '${_storageStrategyPathPolicyService.directoryForContentType(storageStrategy: storageStrategy, contentType: 'character')}/$cleanId.md';
      case BookDeconstructionArtifactKind.organizationProfile:
        return storageStrategy == ProjectStorageStrategy.sqliteProjectStore
            ? 'imports/analysis/assets/organizations/$cleanId.md'
            : 'assets/organizations/$cleanId.md';
      case BookDeconstructionArtifactKind.foreshadowRecord:
        return storageStrategy == ProjectStorageStrategy.sqliteProjectStore
            ? 'imports/analysis/assets/foreshadows/$cleanId.foreshadow.md'
            : 'assets/foreshadows/$cleanId.foreshadow.md';
      case BookDeconstructionArtifactKind.timelineRecord:
        return storageStrategy == ProjectStorageStrategy.sqliteProjectStore
            ? 'imports/analysis/assets/timeline/$cleanId.timeline.md'
            : 'assets/timeline/$cleanId.timeline.md';
      case BookDeconstructionArtifactKind.relationshipRecord:
        return storageStrategy == ProjectStorageStrategy.sqliteProjectStore
            ? 'imports/analysis/assets/relationships/$cleanId.relationship.md'
            : 'assets/relationships/$cleanId.relationship.md';
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
