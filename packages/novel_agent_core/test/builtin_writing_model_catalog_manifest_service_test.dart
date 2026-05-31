import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('BuiltinWritingModelCatalogManifestService', () {
    test('builds seeded manifest for bundled writing model catalog', () {
      final service = BuiltinWritingModelCatalogManifestService();

      final manifest = service.seeded();

      expect(manifest.schemaVersion, 1);
      expect(manifest.catalogId, 'builtin_writing_models');
      expect(manifest.catalogVersion, 1);
      expect(manifest.manifestVersion, '2026-05-30.seed.1');
      expect(manifest.updatedAt, '2026-05-30T00:00:00Z');
      expect(manifest.modelCount, greaterThanOrEqualTo(10));
      expect(manifest.catalogChecksum, isNotEmpty);
    });

    test('round-trips manifest document without touching catalog payload', () {
      final service = BuiltinWritingModelCatalogManifestService();
      final catalog = <String, Object?>{
        'version': 3,
        'models': <Object?>[
          <String, Object?>{'canonical_model_id': 'vendor:model-a'},
          <String, Object?>{'canonical_model_id': 'vendor:model-b'},
        ],
      };

      final manifest = service.buildManifest(
        catalogDocument: catalog,
        catalogId: 'writing_models_test',
        manifestVersion: 'test-v2',
        updatedAt: '2026-05-30T08:00:00Z',
        notes: 'local test manifest',
      );
      final restored = service.fromDocument(manifest.toDocument());

      expect(restored.catalogId, 'writing_models_test');
      expect(restored.catalogVersion, 3);
      expect(restored.manifestVersion, 'test-v2');
      expect(restored.updatedAt, '2026-05-30T08:00:00Z');
      expect(restored.catalogChecksum, manifest.catalogChecksum);
      expect(restored.modelCount, 2);
      expect(restored.notes, 'local test manifest');
    });

    test('parses incomplete manifest documents with stable fallback defaults', () {
      final service = BuiltinWritingModelCatalogManifestService();

      final manifest = service.fromDocument(const <String, Object?>{
        'catalog_checksum': 'abc123',
      });

      expect(manifest.schemaVersion, 1);
      expect(manifest.catalogId, 'builtin_writing_models');
      expect(manifest.catalogVersion, 1);
      expect(manifest.manifestVersion, 'seed-v1');
      expect(manifest.updatedAt, isEmpty);
      expect(manifest.catalogChecksum, 'abc123');
      expect(manifest.modelCount, 0);
      expect(manifest.notes, isEmpty);
    });

    test('buildManifest applies stable fallback defaults for blank header inputs', () {
      final service = BuiltinWritingModelCatalogManifestService();
      final catalog = <String, Object?>{
        'models': <Object?>[
          <String, Object?>{'canonical_model_id': 'vendor:model-a'},
        ],
      };

      final manifest = service.buildManifest(
        catalogDocument: catalog,
        catalogId: '   ',
        manifestVersion: '   ',
      );

      expect(manifest.schemaVersion, 1);
      expect(manifest.catalogId, 'builtin_writing_models');
      expect(manifest.catalogVersion, 1);
      expect(manifest.manifestVersion, 'seed-v1');
      expect(manifest.updatedAt, isEmpty);
      expect(manifest.modelCount, 1);
      expect(manifest.catalogChecksum, isNotEmpty);
      expect(manifest.notes, isEmpty);
    });
  });
}
