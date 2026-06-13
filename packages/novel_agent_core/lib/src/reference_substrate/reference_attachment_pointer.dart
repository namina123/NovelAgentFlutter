import '../common/json_types.dart';
import '../common/value_readers.dart';

class ReferenceAttachmentPointer {
  const ReferenceAttachmentPointer({
    required this.attachmentId,
    required this.relativePath,
    this.mediaKind = '',
    this.integrityHash = '',
    this.byteLength = 0,
    this.metadata = const <String, Object?>{},
  });

  final String attachmentId;
  final String relativePath;
  final String mediaKind;
  final String integrityHash;
  final int byteLength;
  final JsonMap metadata;

  factory ReferenceAttachmentPointer.fromJson(JsonMap json) {
    return ReferenceAttachmentPointer(
      attachmentId: ValueReaders.stringValue(json['attachment_id']).trim(),
      relativePath: ValueReaders.stringValue(json['relative_path']).trim(),
      mediaKind: ValueReaders.stringValue(json['media_kind']).trim(),
      integrityHash: ValueReaders.stringValue(json['integrity_hash']).trim(),
      byteLength: ValueReaders.intValue(json['byte_length']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'attachment_id': attachmentId,
      'relative_path': relativePath,
      'media_kind': mediaKind,
      'integrity_hash': integrityHash,
      'byte_length': byteLength,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
