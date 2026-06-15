import '../imports/source_import_normalized_document.dart';

class BookDeconstructionSourceDocument {
  const BookDeconstructionSourceDocument({
    required this.id,
    required this.title,
    required this.content,
    this.mediaType = 'text/plain',
    this.relativePathHint = '',
    this.sequence = 0,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String content;
  final String mediaType;
  final String relativePathHint;
  final int sequence;
  final Map<String, Object?> metadata;

  factory BookDeconstructionSourceDocument.fromSourceImportDocument(
    SourceImportNormalizedDocument document,
  ) {
    // 中文注释: 拆书侧直接消费共享 normalized document，避免再长出一套只服务 book_deconstruction 的私有来源模型。
    return BookDeconstructionSourceDocument(
      id: document.documentId.trim(),
      title: document.title.trim().isNotEmpty
          ? document.title.trim()
          : document.sourceIdentity.displayName,
      content: document.content,
      mediaType: document.mediaType.trim().isNotEmpty
          ? document.mediaType.trim()
          : document.sourceIdentity.metadata['media_type']?.toString() ?? 'text/plain',
      relativePathHint: document.relativePathHint.trim().isNotEmpty
          ? document.relativePathHint.trim()
          : document.sourceLocator.trim(),
      sequence: document.sequence,
      metadata: <String, Object?>{
        ...document.metadata,
        'source_identity': document.sourceIdentity.toJson(),
        'source_locator': document.sourceLocator,
        'selection_id': document.selectionId,
        'selection_kind': document.selectionKind,
      },
    );
  }
}
