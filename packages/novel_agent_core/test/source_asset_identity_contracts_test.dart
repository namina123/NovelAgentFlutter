import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SourceAssetIdentity contracts', () {
    test('canonical identity falls back from legacy source ref fields', () {
      final sourceRef = NarrativeSourceRef.fromJson(<String, Object?>{
        'source_type': 'source_document_file',
        'source_id': 'imports/reference/hp1.txt',
        'label': 'Harry Potter Volume 1',
      });
      final encoded = sourceRef.toJson();
      final sourceIdentity = SourceAssetIdentity.fromJson(encoded);

      expect(sourceIdentity.validateBasics(), isEmpty);
      expect(sourceRef.sourceKind, 'source_document_file');
      expect(sourceRef.sourceAssetId, 'imports/reference/hp1.txt');
      expect(sourceRef.displayName, 'Harry Potter Volume 1');
      expect(encoded['source_asset_id'], 'imports/reference/hp1.txt');
      expect(encoded['display_name'], 'Harry Potter Volume 1');
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(encoded['source_identity'])['source_kind'],
        ),
        'source_document_file',
      );
    });

    test('absolute local paths are downgraded into debug metadata', () {
      final identity = SourceAssetIdentity.fromJson(<String, Object?>{
        'source_kind': 'source_document_file',
        'display_name': '哈利波特原文',
        'local_hint_path': r'D:\books\Harry Potter - Volume 1 Raw.txt',
      });

      expect(identity.validateBasics(), isEmpty);
      expect(identity.localHintPath, 'Harry Potter - Volume 1 Raw.txt');
      expect(
        ValueReaders.stringValue(
          identity.metadata['debug_local_absolute_path'],
        ),
        r'D:\books\Harry Potter - Volume 1 Raw.txt',
      );
      expect(
        identity.sourceAssetId,
        'local_hint:Harry Potter - Volume 1 Raw.txt',
      );
    });

    test('canonical identity preserves resolver uri and source asset id', () {
      final identity = SourceAssetIdentity.fromJson(<String, Object?>{
        'source_identity': <String, Object?>{
          'source_asset_id': 'pkg-hp:v1:entry-hat',
          'display_name': '哈利波特第一卷',
          'source_kind': 'reference_substrate_entry',
          'resolver_uri': 'reference-entry://pkg-hp/v1/entry-hat',
          'local_hint_path': 'reference/hp/v1.json',
        },
      });

      expect(identity.validateBasics(), isEmpty);
      expect(identity.sourceAssetId, 'pkg-hp:v1:entry-hat');
      expect(identity.resolverUri, 'reference-entry://pkg-hp/v1/entry-hat');
      expect(identity.localHintPath, 'reference/hp/v1.json');
    });
  });
}
