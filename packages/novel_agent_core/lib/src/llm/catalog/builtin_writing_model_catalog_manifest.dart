import '../../common/json_types.dart';

class BuiltinWritingModelCatalogManifest {
  const BuiltinWritingModelCatalogManifest({
    required this.schemaVersion,
    required this.catalogId,
    required this.catalogVersion,
    required this.manifestVersion,
    this.updatedAt = '',
    this.catalogChecksum = '',
    this.modelCount = 0,
    this.notes = '',
  });

  final int schemaVersion;
  final String catalogId;
  final int catalogVersion;
  final String manifestVersion;
  final String updatedAt;
  final String catalogChecksum;
  final int modelCount;
  final String notes;

  JsonMap toDocument() {
    return <String, Object?>{
      'schema_version': schemaVersion,
      'catalog_id': catalogId,
      'catalog_version': catalogVersion,
      'manifest_version': manifestVersion,
      'updated_at': updatedAt,
      'catalog_checksum': catalogChecksum,
      'model_count': modelCount,
      'notes': notes,
    };
  }
}
