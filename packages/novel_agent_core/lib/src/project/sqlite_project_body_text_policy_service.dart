import 'sqlite_project_body_text_document.dart';
import 'sqlite_project_body_text_storage_format.dart';

class SqliteProjectBodyTextPolicyService {
  const SqliteProjectBodyTextPolicyService();

  String? violationOf(SqliteProjectBodyTextDocument document) {
    // 中文注释: 这里集中表达 SQLite 正文主存储规则，避免后续不同仓储、导入器和编辑入口各自发明一套判断。
    if (document.documentId.trim().isEmpty) {
      return '正文文档必须有稳定 document_id。';
    }
    if (document.documentKind.trim().isEmpty) {
      return '正文文档必须声明 document_kind。';
    }
    if (document.title.trim().isEmpty) {
      return '正文文档必须声明标题。';
    }
    if (document.storageFormat ==
        SqliteProjectBodyTextStorageFormat.plainText) {
      if (document.segments.isNotEmpty) {
        return '纯文本正文不能同时携带 segments。';
      }
      if (_looksLikeMarkdownBlob(document.plainText)) {
        return 'SQLite 主正文禁止直接存整篇 Markdown blob；请改为纯文本或分段文本。';
      }
      return null;
    }
    if (document.plainText.trim().isNotEmpty) {
      return '分段正文不能同时携带 plain_text。';
    }
    if (document.segments.isEmpty) {
      return '分段正文至少需要一个 segment。';
    }
    for (final segment in document.segments) {
      if (segment.segmentId.trim().isEmpty) {
        return '每个正文分段都必须有稳定 segment_id。';
      }
      if (segment.text.trim().isEmpty) {
        return '正文分段不能为空文本。';
      }
      if (_looksLikeMarkdownBlob(segment.text)) {
        return '正文分段不能直接存 Markdown 结构片段。';
      }
    }
    return null;
  }

  bool _looksLikeMarkdownBlob(String text) {
    // 中文注释: 这里只拦截明显的 Markdown 结构标记，减少对普通小说换行文本的误判。
    final clean = text.trim();
    if (clean.isEmpty) {
      return false;
    }
    final patterns = <RegExp>[
      RegExp(r'^#{1,6}\s', multiLine: true),
      RegExp(r'^```', multiLine: true),
      RegExp(r'^\s*[-*+]\s', multiLine: true),
      RegExp(r'^\s*\d+\.\s', multiLine: true),
      RegExp(r'^\s*>\s', multiLine: true),
      RegExp(r'\[[^\]]+\]\([^)]+\)'),
      RegExp(r'^\|.+\|$', multiLine: true),
    ];
    for (final pattern in patterns) {
      if (pattern.hasMatch(clean)) {
        return true;
      }
    }
    return false;
  }
}
