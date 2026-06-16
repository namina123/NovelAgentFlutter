import 'project_artifact_identity.dart';
import 'project_support_document_catalog.dart';

class ProjectArtifactIdentityService {
  const ProjectArtifactIdentityService();

  ProjectArtifactIdentity classify({
    required String relativePath,
    bool isDirectory = false,
    String projectTypeId = '',
  }) {
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
    if (normalized == 'analysis') {
      return const ProjectArtifactIdentity(
        kindId: 'analysis_directory',
        shortLabel: '分析资料',
        detailLabel: '分析目录 · 辅助参考资料',
      );
    }
    if (normalized.startsWith('analysis/')) {
      return const ProjectArtifactIdentity(
        kindId: 'analysis',
        shortLabel: '分析资料',
        detailLabel: '分析资料 · 辅助参考',
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

  String _normalize(String relativePath) {
    return relativePath
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'^/+|/+$'), '')
        .toLowerCase();
  }
}
