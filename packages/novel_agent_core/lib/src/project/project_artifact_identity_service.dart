import 'project_artifact_identity.dart';
import 'project_content_path_policy_service.dart';
import 'project_support_document_catalog.dart';

class ProjectArtifactIdentityService {
  const ProjectArtifactIdentityService({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;

  ProjectArtifactIdentity classify({
    required String relativePath,
    bool isDirectory = false,
    String projectTypeId = '',
  }) {
    // 中文注释: 身份分类只投影正式路径合同与少量兼容入口，不在这里重建第二套规则。
    final normalized = ProjectSupportDocumentCatalog.canonicalizePath(
      relativePath,
    );
    final rawNormalized = _normalize(relativePath);
    if (normalized.isEmpty && rawNormalized.isEmpty) {
      return ProjectArtifactIdentity.unknown;
    }
    if (ProjectSupportDocumentCatalog.isProjectOverviewPath(relativePath)) {
      final isLegacyBrief = rawNormalized.endsWith('project_brief.md');
      return ProjectArtifactIdentity(
        kindId: 'project_overview',
        shortLabel: '支撑概览',
        detailLabel: isLegacyBrief
            ? '支撑概览 · 兼容入口 · 非正式前提'
            : '支撑概览 · 系统入口 · 非正式前提',
        isCompatibilityEntry: isLegacyBrief,
      );
    }
    if (_isPathUnder(normalized, _contentPathPolicyService.directoryForContentType('source_original'))) {
      return const ProjectArtifactIdentity(
        kindId: 'source_original',
        shortLabel: '原文归档',
        detailLabel: '原文归档 · 来源材料 · 非正文事实源',
      );
    }
    if (_isPathUnder(
          normalized,
          _contentPathPolicyService.directoryForContentType('derived_continuation_narrative'),
        ) ||
        _isPathUnder(
          normalized,
          _contentPathPolicyService.directoryForContentType('derived_fanfic_narrative'),
        )) {
      return ProjectArtifactIdentity(
        kindId: normalized.contains('/fanfic/')
            ? 'derived_fanfic_narrative'
            : 'derived_continuation_narrative',
        shortLabel: normalized.contains('/fanfic/') ? '派生同人' : '派生续写',
        detailLabel: normalized.contains('/fanfic/')
            ? '派生同人 · 续写分支 · 不回写原文事实源'
            : '派生续写 · 连续正文分支 · 不回写原文事实源',
      );
    }
    if (normalized == 'premise/sqlite_projection' ||
        normalized.startsWith('premise/sqlite_projection/')) {
      return ProjectArtifactIdentity(
        kindId: 'sqlite_projection',
        shortLabel: 'SQLite 投影',
        detailLabel: isDirectory || normalized == 'premise/sqlite_projection'
            ? 'SQLite 投影目录 · 只读镜像 · 非事实源'
            : 'SQLite 投影 · 只读镜像 · 非事实源',
        isProjection: true,
      );
    }
    if (normalized == 'premise') {
      return const ProjectArtifactIdentity(
        kindId: 'premise_directory',
        shortLabel: '正式前提',
        detailLabel: '前提目录 · 正式前提与长期边界',
        isFormalAsset: true,
      );
    }
    if (normalized.startsWith('premise/')) {
      return const ProjectArtifactIdentity(
        kindId: 'formal_premise',
        shortLabel: '正式前提',
        detailLabel: '正式前提 · 会参与上下文',
        isFormalAsset: true,
      );
    }
    if (normalized == 'outlines') {
      return const ProjectArtifactIdentity(
        kindId: 'outline_directory',
        shortLabel: '正式规划',
        detailLabel: '规划目录 · 故事规划与章纲',
        isFormalAsset: true,
      );
    }
    if (normalized.startsWith('outlines/')) {
      return const ProjectArtifactIdentity(
        kindId: 'formal_outline',
        shortLabel: '正式规划',
        detailLabel: '正式规划 · 会参与创作',
        isFormalAsset: true,
      );
    }
    if (normalized == 'chapters') {
      return const ProjectArtifactIdentity(
        kindId: 'chapter_directory',
        shortLabel: '正式正文',
        detailLabel: '正文目录 · 正式交付资产',
        isFormalAsset: true,
      );
    }
    if (normalized.startsWith('chapters/')) {
      return const ProjectArtifactIdentity(
        kindId: 'formal_chapter',
        shortLabel: '正式正文',
        detailLabel: '正式正文 · 正式交付资产',
        isFormalAsset: true,
      );
    }
    if (normalized == 'samples') {
      return const ProjectArtifactIdentity(
        kindId: 'sample_directory',
        shortLabel: '样章',
        detailLabel: '样章目录 · 不计入正式正文',
      );
    }
    if (normalized.startsWith('samples/')) {
      return const ProjectArtifactIdentity(
        kindId: 'sample',
        shortLabel: '样章',
        detailLabel: '样章 · 不计入正式正文',
      );
    }
    if (normalized == 'scenes') {
      return const ProjectArtifactIdentity(
        kindId: 'scene_directory',
        shortLabel: '场景片段',
        detailLabel: '场景目录 · 非正式创作素材',
      );
    }
    if (normalized.startsWith('scenes/')) {
      return const ProjectArtifactIdentity(
        kindId: 'scene',
        shortLabel: '场景片段',
        detailLabel: '场景片段 · 非正式创作素材',
      );
    }
    if (normalized == 'assets') {
      return const ProjectArtifactIdentity(
        kindId: 'asset_directory',
        shortLabel: '正式资产',
        detailLabel: '资产目录 · 项目资源',
        isFormalAsset: true,
      );
    }
    if (normalized.startsWith('assets/')) {
      return const ProjectArtifactIdentity(
        kindId: 'asset',
        shortLabel: '正式资产',
        detailLabel: '正式资产 · 项目资源',
        isFormalAsset: true,
      );
    }
    if (normalized == 'analysis' || normalized.startsWith('analysis/')) {
      return const ProjectArtifactIdentity(
        kindId: 'analysis',
        shortLabel: '分析资料',
        detailLabel: '分析资料 · 辅助参考',
      );
    }
    if (normalized == 'knowledge' || normalized.startsWith('knowledge/')) {
      return const ProjectArtifactIdentity(
        kindId: 'knowledge',
        shortLabel: '信息资料',
        detailLabel: '信息资料 · 研究/提取/知识卡等统一投影',
      );
    }
    if (normalized == 'research' || normalized.startsWith('research/')) {
      return const ProjectArtifactIdentity(
        kindId: 'research',
        shortLabel: '研究资料',
        detailLabel: '研究资料 · 资料研究与记录投影',
      );
    }
    if (normalized.startsWith('.novel_agent/information/')) {
      return const ProjectArtifactIdentity(
        kindId: 'information_workspace',
        shortLabel: '信息资料',
        detailLabel: '信息工作区 · 研究与提取投影',
      );
    }
    if (projectTypeId.trim() == 'sqlite_project_store') {
      return ProjectArtifactIdentity(
        kindId: 'sqlite_store_resource',
        shortLabel: 'SQLite 资源',
        detailLabel: isDirectory ? 'SQLite 资源目录' : 'SQLite 主事实源可读资源',
      );
    }
    return ProjectArtifactIdentity.unknown;
  }

  String formatPathWithLabel(
    String relativePath, {
    bool isDirectory = false,
    String projectTypeId = '',
  }) {
    final normalized = _normalize(relativePath);
    if (normalized.isEmpty) {
      return '';
    }
    final identity = classify(
      relativePath: relativePath,
      isDirectory: isDirectory,
      projectTypeId: projectTypeId,
    );
    if (!identity.isKnown || identity.shortLabel.isEmpty) {
      return relativePath.trim();
    }
    return '${relativePath.trim()}（${identity.shortLabel}）';
  }

  bool _isPathUnder(String path, String root) {
    final cleanPath = _normalize(path);
    final cleanRoot = _normalize(root);
    if (cleanPath.isEmpty || cleanRoot.isEmpty) {
      return false;
    }
    return cleanPath == cleanRoot || cleanPath.startsWith('$cleanRoot/');
  }

  String _normalize(String relativePath) {
    return relativePath
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'^/+|/+$'), '')
        .toLowerCase();
  }
}
