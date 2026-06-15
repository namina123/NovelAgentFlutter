import '../common/json_types.dart';
import '../common/source_asset_identity.dart';
import '../common/value_readers.dart';
import 'source_import_selection.dart';
import 'source_import_selection_kind.dart';

class SourceImportNormalizedDocument {
  const SourceImportNormalizedDocument({
    required this.documentId,
    required this.selectionId,
    required this.selectionKind,
    required this.sourceIdentity,
    required this.sourceLocator,
    this.title = '',
    this.content = '',
    this.mediaType = '',
    this.relativePathHint = '',
    this.sequence = 0,
    this.metadata = const <String, Object?>{},
  });

  final String documentId;
  final String selectionId;
  final String selectionKind;
  final SourceAssetIdentity sourceIdentity;
  final String sourceLocator;
  final String title;
  final String content;
  final String mediaType;
  final String relativePathHint;
  final int sequence;
  final JsonMap metadata;

  SourceImportNormalizedDocument copyWith({
    String? documentId,
    String? selectionId,
    String? selectionKind,
    SourceAssetIdentity? sourceIdentity,
    String? sourceLocator,
    String? title,
    String? content,
    String? mediaType,
    String? relativePathHint,
    int? sequence,
    JsonMap? metadata,
  }) {
    // 中文注释: normalized document copyWith 只服务跨层桥接和排序，不在这里引入 reader 或落盘职责。
    return SourceImportNormalizedDocument(
      documentId: documentId ?? this.documentId,
      selectionId: selectionId ?? this.selectionId,
      selectionKind: selectionKind ?? this.selectionKind,
      sourceIdentity: sourceIdentity ?? this.sourceIdentity,
      sourceLocator: sourceLocator ?? this.sourceLocator,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaType: mediaType ?? this.mediaType,
      relativePathHint: relativePathHint ?? this.relativePathHint,
      sequence: sequence ?? this.sequence,
      metadata: metadata ?? this.metadata,
    );
  }

  factory SourceImportNormalizedDocument.fromJson(JsonMap json) {
    // 中文注释: normalized document 的 JSON 回读用于合同测试和中间层投影回放。
    return SourceImportNormalizedDocument(
      documentId: ValueReaders.stringValue(json['document_id']).trim(),
      selectionId: ValueReaders.stringValue(json['selection_id']).trim(),
      selectionKind: ValueReaders.stringValue(json['selection_kind']).trim(),
      sourceIdentity: SourceAssetIdentity.fromJson(
        ValueReaders.mapValue(json['source_identity']),
      ),
      sourceLocator: ValueReaders.stringValue(json['source_locator']).trim(),
      title: ValueReaders.stringValue(json['title']).trim(),
      content: ValueReaders.stringValue(json['content']),
      mediaType: ValueReaders.stringValue(json['media_type']).trim(),
      relativePathHint: ValueReaders.stringValue(
        json['relative_path_hint'],
      ).trim(),
      sequence: ValueReaders.intValue(json['sequence']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: normalized document 投影显式保留来源身份与排序，方便拆书与一般导入共用同一份中性记录。
    return <String, Object?>{
      'document_id': documentId,
      'selection_id': selectionId,
      'selection_kind': selectionKind,
      'source_identity': sourceIdentity.toJson(),
      'source_locator': sourceLocator,
      'title': title,
      'content': content,
      'media_type': mediaType,
      'relative_path_hint': relativePathHint,
      'sequence': sequence,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 这里只校验 normalized document 的稳定壳层，不在这里判断正文是否已经读入。
    final result = <String>[];
    if (documentId.trim().isEmpty) {
      result.add('missing_source_import_document_id');
    }
    if (selectionId.trim().isEmpty) {
      result.add('missing_source_import_document_selection_id');
    }
    if (!SourceImportSelectionKinds.knownValues.contains(selectionKind)) {
      result.add('invalid_source_import_document_selection_kind');
    }
    result.addAll(sourceIdentity.validateBasics());
    if (sequence < 0) {
      result.add('invalid_source_import_document_sequence');
    }
    return result;
  }

  static SourceImportNormalizedDocument fromSelection(
    SourceImportSelection selection, {
    String documentId = '',
    String title = '',
    String content = '',
    int sequence = 0,
  }) {
    // 中文注释: 这里把 selection 投影成 normalized document，后续 reader 只需补 content，不必重建身份信息。
    final cleanTitle = title.trim().isNotEmpty
        ? title.trim()
        : _fallbackTitle(selection);
    final cleanDocumentId = documentId.trim().isNotEmpty
        ? documentId.trim()
        : _fallbackDocumentId(selection);
    return SourceImportNormalizedDocument(
      documentId: cleanDocumentId,
      selectionId: selection.selectionId,
      selectionKind: selection.selectionKind,
      sourceIdentity: selection.sourceIdentity,
      sourceLocator: selection.sourceLocator,
      title: cleanTitle,
      content: content,
      mediaType: selection.mediaType.trim(),
      relativePathHint: selection.relativePathHint.trim(),
      sequence: sequence > 0 ? sequence : selection.sortOrder,
      metadata: <String, Object?>{
        ...ValueReaders.deepCopyMap(selection.metadata),
        'source_import_selection_kind': selection.selectionKind,
        'source_import_sort_order': selection.sortOrder,
      },
    );
  }

  static String _fallbackDocumentId(SourceImportSelection selection) {
    final candidate = selection.sourceIdentity.sourceAssetId.trim();
    if (candidate.isNotEmpty) {
      return candidate;
    }
    return selection.selectionId.trim();
  }

  static String _fallbackTitle(SourceImportSelection selection) {
    final identityTitle = selection.sourceIdentity.displayName.trim();
    if (identityTitle.isNotEmpty) {
      return identityTitle;
    }
    final fromPath = selection.relativePathHint.trim().isNotEmpty
        ? selection.relativePathHint.trim()
        : selection.sourceLocator.trim();
    if (fromPath.isEmpty) {
      return 'source_document';
    }
    final normalized = fromPath.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }
}
