import '../common/json_types.dart';
import 'bundle_checksum_service.dart';

class BundleHeaderBuilderService {
  BundleHeaderBuilderService({BundleChecksumService? checksumService})
    : _checksumService = checksumService ?? const BundleChecksumService();

  final BundleChecksumService _checksumService;

  JsonMap attachHeader({
    required String bundleKind,
    required String title,
    required String description,
    required String bundleVersion,
    required String createdAt,
    required JsonMap payload,
    int schemaVersion = 1,
  }) {
    // 中文注释: 这里统一补版本头并计算 checksum，让不同 bundle 文档服务只关心自己的 payload。
    final document = <String, Object?>{
      'kind': bundleKind.trim(),
      'schema_version': schemaVersion,
      'bundle_version': bundleVersion.trim().isEmpty
          ? '1.0.0'
          : bundleVersion.trim(),
      'title': title.trim(),
      'description': description.trim(),
      'created_at': createdAt.trim(),
      ...payload,
    };
    final checksum = _checksumService.checksumOf(document);
    document['checksum'] = checksum;
    return document;
  }
}
