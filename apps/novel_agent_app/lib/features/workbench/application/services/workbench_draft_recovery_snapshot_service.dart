import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/open_document_state.dart';

class WorkbenchDraftRecoverySnapshotService {
  const WorkbenchDraftRecoverySnapshotService();

  List<JsonMap> captureRecoveries(Iterable<OpenDocumentState> documents) {
    // 中文注释: 恢复快照只保留正文类文档的未保存内容，避免把正式项目产物和工作台临时态混在一起。
    final recoveries = <JsonMap>[];
    final seenPaths = <String>{};
    for (final document in documents) {
      if (!document.isDirty) {
        continue;
      }
      final relativePath = normalizeRelativePath(document.relativePath);
      if (!_isRecoverableContentPath(relativePath)) {
        continue;
      }
      final content = document.content;
      if (content.trim().isEmpty || !seenPaths.add(relativePath)) {
        continue;
      }
      recoveries.add(<String, Object?>{
        'relative_path': relativePath,
        'title': document.title.trim(),
        'content': content,
      });
    }
    return recoveries;
  }

  List<JsonMap> parseRecoveries(Object? value) {
    final result = <JsonMap>[];
    final seenPaths = <String>{};
    for (final raw in ValueReaders.mapList(value)) {
      final relativePath = normalizeRelativePath(
        ValueReaders.stringValue(raw['relative_path']),
      );
      final content = ValueReaders.stringValue(raw['content']);
      if (!_isRecoverableContentPath(relativePath) ||
          content.trim().isEmpty ||
          !seenPaths.add(relativePath)) {
        continue;
      }
      result.add(<String, Object?>{
        'relative_path': relativePath,
        'title': ValueReaders.stringValue(raw['title']),
        'content': content,
      });
    }
    return result;
  }

  JsonMap? recoveryForPath(Object? value, String relativePath) {
    final normalizedPath = normalizeRelativePath(relativePath);
    if (normalizedPath.isEmpty) {
      return null;
    }
    for (final recovery in parseRecoveries(value)) {
      if (_comparisonKey(
            normalizeRelativePath(
              ValueReaders.stringValue(recovery['relative_path']),
            ),
          ) ==
          _comparisonKey(normalizedPath)) {
        return recovery;
      }
    }
    return null;
  }

  String normalizeRelativePath(String relativePath) {
    return relativePath.trim().replaceAll('\\', '/');
  }

  bool _isRecoverableContentPath(String relativePath) {
    final normalized = _comparisonKey(relativePath);
    return normalized.startsWith('chapters/') ||
        normalized.startsWith('samples/') ||
        normalized.startsWith('scenes/');
  }

  String _comparisonKey(String relativePath) {
    return relativePath.toLowerCase();
  }
}
