import 'package:novel_agent_core/novel_agent_core.dart';

class WorkbenchDocumentIdentityService {
  const WorkbenchDocumentIdentityService({
    ProjectArtifactIdentityService? artifactIdentityService,
  }) : _artifactIdentityService =
           artifactIdentityService ?? const ProjectArtifactIdentityService();

  final ProjectArtifactIdentityService _artifactIdentityService;

  String identityLabel({
    required String relativePath,
    bool isBufferedDraft = false,
  }) {
    final normalized = _normalize(relativePath);
    if (normalized.isEmpty) {
      return isBufferedDraft ? '草稿缓存' : '';
    }
    if (isBufferedDraft) {
      return '草稿缓存';
    }
    return _artifactIdentityService
        .classify(relativePath: normalized)
        .shortLabel;
  }

  String statusLabel({
    required String relativePath,
    required bool isDirty,
    required bool isBufferedDraft,
    required String fallbackStatus,
    required bool isRenderMode,
    required bool isStructureMode,
  }) {
    final identity = identityLabel(
      relativePath: relativePath,
      isBufferedDraft: isBufferedDraft,
    );
    final state = stateLabel(
      isDirty: isDirty,
      isBufferedDraft: isBufferedDraft,
      fallbackStatus: fallbackStatus,
      isRenderMode: isRenderMode,
      isStructureMode: isStructureMode,
    );
    if (identity.isEmpty) {
      return state;
    }
    if (state.isEmpty) {
      return identity;
    }
    return '$identity · $state';
  }

  String tooltipLabel({
    required String relativePath,
    required String title,
    required bool isDirty,
    required bool isBufferedDraft,
  }) {
    final lines = <String>[];
    final trimmedPath = relativePath.trim();
    if (trimmedPath.isNotEmpty) {
      lines.add(trimmedPath);
    } else if (title.trim().isNotEmpty) {
      lines.add(title.trim());
    }
    final identity = identityLabel(
      relativePath: relativePath,
      isBufferedDraft: isBufferedDraft,
    );
    if (identity.isNotEmpty) {
      lines.add(identity);
    }
    if (isBufferedDraft) {
      lines.add('尚未正式保存');
    } else if (isDirty) {
      lines.add('存在未保存修改');
    }
    return lines.join('\n');
  }

  String stateLabel({
    required bool isDirty,
    required bool isBufferedDraft,
    required String fallbackStatus,
    required bool isRenderMode,
    required bool isStructureMode,
  }) {
    if (isStructureMode) {
      return '结构视图';
    }
    if (isRenderMode) {
      if (isBufferedDraft) {
        return '渲染中，来自草稿缓存';
      }
      return isDirty ? '渲染中，存在未保存修改' : '渲染视图';
    }
    if (isBufferedDraft) {
      return '未正式保存';
    }
    if (isDirty) {
      return '未保存修改';
    }
    return fallbackStatus.trim();
  }

  String _normalize(String relativePath) {
    return relativePath.trim().replaceAll('\\', '/').toLowerCase();
  }
}
