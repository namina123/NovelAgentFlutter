import 'dart:convert';

import '../../bundles/bundle_checksum_service.dart';
import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'builtin_writing_model_catalog_manifest.dart';
import 'builtin_writing_model_catalog_seed.dart';

class BuiltinWritingModelCatalogManifestService {
  BuiltinWritingModelCatalogManifestService({
    BundleChecksumService? checksumService,
  }) : _checksumService = checksumService ?? const BundleChecksumService();

  final BundleChecksumService _checksumService;

  BuiltinWritingModelCatalogManifest fromJsonString(String source) {
    return fromDocument(ValueReaders.mapValue(jsonDecode(source)));
  }

  BuiltinWritingModelCatalogManifest fromDocument(JsonMap document) {
    // 中文注释: manifest 解析独立于 catalog 解析，后续接热更新时可以先比对头信息，再决定是否拉正文。
    return BuiltinWritingModelCatalogManifest(
      schemaVersion: ValueReaders.intValue(document['schema_version'], 1),
      catalogId: ValueReaders.stringValue(
        document['catalog_id'],
        'builtin_writing_models',
      ),
      catalogVersion: ValueReaders.intValue(document['catalog_version'], 1),
      manifestVersion: ValueReaders.stringValue(
        document['manifest_version'],
        'seed-v1',
      ),
      updatedAt: ValueReaders.stringValue(document['updated_at']),
      catalogChecksum: ValueReaders.stringValue(document['catalog_checksum']),
      modelCount: ValueReaders.intValue(document['model_count']),
      notes: ValueReaders.stringValue(document['notes']),
    );
  }

  BuiltinWritingModelCatalogManifest seeded() {
    final catalog = ValueReaders.mapValue(
      jsonDecode(builtinWritingModelCatalogSeed),
    );
    return buildManifest(
      catalogDocument: catalog,
      catalogId: 'builtin_writing_models',
      manifestVersion: '2026-05-30.seed.1',
      updatedAt: '2026-05-30T00:00:00Z',
      notes: 'Seed manifest for bundled writing model registry.',
    );
  }

  BuiltinWritingModelCatalogManifest buildManifest({
    required JsonMap catalogDocument,
    required String catalogId,
    required String manifestVersion,
    String updatedAt = '',
    String notes = '',
  }) {
    final copied = ValueReaders.deepCopyMap(catalogDocument);
    final version = ValueReaders.intValue(copied['version'], 1);
    final modelCount = ValueReaders.mapList(copied['models']).length;
    return BuiltinWritingModelCatalogManifest(
      schemaVersion: 1,
      catalogId: catalogId.trim().isEmpty
          ? 'builtin_writing_models'
          : catalogId.trim(),
      catalogVersion: version,
      manifestVersion: manifestVersion.trim().isEmpty
          ? 'seed-v1'
          : manifestVersion.trim(),
      updatedAt: updatedAt,
      catalogChecksum: _checksumService.checksumOf(copied),
      modelCount: modelCount,
      notes: notes,
    );
  }
}
