import 'sqlite_project_body_text_segment.dart';
import 'sqlite_project_body_text_storage_format.dart';

class SqliteProjectBodyTextDocument {
  const SqliteProjectBodyTextDocument({
    required this.documentId,
    required this.documentKind,
    required this.title,
    required this.storageFormat,
    this.plainText = '',
    this.segments = const <SqliteProjectBodyTextSegment>[],
    this.markdownPath = '',
    this.statePath = '',
    this.status = 'draft',
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String documentId;
  final String documentKind;
  final String title;
  final SqliteProjectBodyTextStorageFormat storageFormat;
  final String plainText;
  final List<SqliteProjectBodyTextSegment> segments;
  final String markdownPath;
  final String statePath;
  final String status;
  final String createdAt;
  final String updatedAt;

  bool get isSegmented =>
      storageFormat == SqliteProjectBodyTextStorageFormat.segmentedText;

  String combinedText() {
    // 中文注释: SQLite 主正文的统一文本视图在这里收口，后续无论是全文检索还是导出都不需要重复拼接段落。
    if (!isSegmented) {
      return plainText;
    }
    final orderedSegments = List<SqliteProjectBodyTextSegment>.from(segments)
      ..sort((left, right) => left.ordinal.compareTo(right.ordinal));
    return orderedSegments.map((segment) => segment.text).join('\n\n');
  }
}
