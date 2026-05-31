import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_attachment_draft.dart';

class ConversationAttachmentDraftService {
  const ConversationAttachmentDraftService();

  Future<List<ConversationAttachmentDraft>> createDrafts(
    List<String> selectedPaths,
  ) async {
    final drafts = <ConversationAttachmentDraft>[];
    for (final rawPath in selectedPaths) {
      final path = rawPath.trim();
      if (path.isEmpty) {
        continue;
      }
      drafts.add(await _draftFromPath(path));
    }
    return drafts;
  }

  List<ConversationAttachmentDraft> mergeDrafts({
    required List<ConversationAttachmentDraft> currentDrafts,
    required List<ConversationAttachmentDraft> incomingDrafts,
  }) {
    // 中文注释: 附件暂存按本地路径去重，避免重复选择同一文件时在草稿列表里不断堆叠。
    final byPath = <String, ConversationAttachmentDraft>{
      for (final draft in currentDrafts) draft.localPath: draft,
    };
    for (final draft in incomingDrafts) {
      byPath[draft.localPath] = draft;
    }
    return byPath.values.toList(growable: false);
  }

  List<ConversationAttachmentDraft> removeDraftById(
    List<ConversationAttachmentDraft> drafts,
    String draftId,
  ) {
    return drafts.where((draft) => draft.id != draftId).toList(growable: false);
  }

  List<ChatInputAttachment> readyInputAttachments(
    List<ConversationAttachmentDraft> drafts,
  ) {
    return drafts
        .where((draft) => draft.isReady)
        .map((draft) => draft.toInputAttachment())
        .toList(growable: false);
  }

  Future<ConversationAttachmentDraft> _draftFromPath(String path) async {
    final file = File(path);
    final fileName = _fileNameOf(path);
    final mediaKind = _mediaKindForPath(path);
    final mimeType = _mimeTypeForPath(path, mediaKind);
    try {
      final exists = await file.exists();
      if (!exists) {
        return ConversationAttachmentDraft(
          id: _draftId(path),
          fileName: fileName,
          localPath: path,
          mediaKind: mediaKind,
          mimeType: mimeType,
          sizeBytes: 0,
          isReady: false,
          failureMessage: '附件文件不存在。',
        );
      }
      final sizeBytes = await file.length();
      return ConversationAttachmentDraft(
        id: _draftId(path),
        fileName: fileName,
        localPath: path,
        mediaKind: mediaKind,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        isReady: true,
      );
    } catch (error) {
      return ConversationAttachmentDraft(
        id: _draftId(path),
        fileName: fileName,
        localPath: path,
        mediaKind: mediaKind,
        mimeType: mimeType,
        sizeBytes: 0,
        isReady: false,
        failureMessage: '附件检查失败：$error',
      );
    }
  }

  String _draftId(String path) {
    return 'attachment_${path.hashCode.abs()}';
  }

  String _fileNameOf(String path) {
    final normalized = path.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return '';
    }
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }

  AttachmentMediaKind _mediaKindForPath(String path) {
    final extension = _extensionOf(path);
    if (_imageMimeTypes.containsKey(extension)) {
      return AttachmentMediaKind.image;
    }
    return AttachmentMediaKind.file;
  }

  String _mimeTypeForPath(String path, AttachmentMediaKind mediaKind) {
    final extension = _extensionOf(path);
    if (mediaKind == AttachmentMediaKind.image) {
      return _imageMimeTypes[extension] ?? 'image/*';
    }
    return _fileMimeTypes[extension] ?? 'application/octet-stream';
  }

  String _extensionOf(String path) {
    final fileName = _fileNameOf(path).toLowerCase();
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0) {
      return '';
    }
    return fileName.substring(dotIndex);
  }

  static const Map<String, String> _imageMimeTypes = <String, String>{
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.bmp': 'image/bmp',
  };

  static const Map<String, String> _fileMimeTypes = <String, String>{
    '.txt': 'text/plain',
    '.md': 'text/markdown',
    '.markdown': 'text/markdown',
    '.json': 'application/json',
    '.pdf': 'application/pdf',
    '.csv': 'text/csv',
    '.docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };
}
