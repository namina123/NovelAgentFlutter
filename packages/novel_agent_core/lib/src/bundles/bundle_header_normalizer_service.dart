import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'bundle_header.dart';
import 'bundle_kind.dart';

class BundleHeaderNormalizerService {
  const BundleHeaderNormalizerService();

  BundleHeader normalizeHeader(JsonMap bundle, {String fallbackKind = ''}) {
    // 中文注释: 版本头统一在这里收敛，后续不论项目包还是资产包都复用同一套字段解释。
    final kind = ValueReaders.stringValue(bundle['kind'], fallbackKind).trim();
    return BundleHeader(
      bundleKind: BundleKind.isSupported(kind) ? kind : fallbackKind.trim(),
      schemaVersion: ValueReaders.intValue(bundle['schema_version'], 1),
      bundleVersion: ValueReaders.stringValue(
        bundle['bundle_version'],
        '1.0.0',
      ).trim(),
      title: ValueReaders.stringValue(bundle['title']).trim(),
      description: ValueReaders.stringValue(bundle['description']).trim(),
      createdAt: ValueReaders.stringValue(bundle['created_at']).trim(),
      checksum: ValueReaders.stringValue(bundle['checksum']).trim(),
    );
  }

  JsonMap toDocument(BundleHeader header) {
    return <String, Object?>{
      'kind': header.bundleKind,
      'schema_version': header.schemaVersion,
      'bundle_version': header.bundleVersion,
      'title': header.title,
      'description': header.description,
      'created_at': header.createdAt,
      'checksum': header.checksum,
    };
  }
}
