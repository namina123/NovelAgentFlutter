import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'bundle_checksum_service.dart';
import 'bundle_header_normalizer_service.dart';
import 'bundle_kind.dart';
import 'bundle_validation_issue.dart';
import 'bundle_validation_result.dart';

class BundleValidationService {
  BundleValidationService({
    BundleHeaderNormalizerService? headerNormalizerService,
    BundleChecksumService? checksumService,
  }) : _headerNormalizerService =
           headerNormalizerService ?? const BundleHeaderNormalizerService(),
       _checksumService = checksumService ?? const BundleChecksumService();

  final BundleHeaderNormalizerService _headerNormalizerService;
  final BundleChecksumService _checksumService;

  BundleValidationResult validateBundle(
    JsonMap bundle, {
    String expectedKind = '',
  }) {
    // 中文注释: 校验层只关心版本头、kind 和 checksum 等 bundle 合同，不提前侵入具体导入写盘逻辑。
    final issues = <BundleValidationIssue>[];
    final header = _headerNormalizerService.normalizeHeader(
      bundle,
      fallbackKind: expectedKind,
    );
    if (header.bundleKind.isEmpty) {
      issues.add(
        const BundleValidationIssue(
          code: 'missing_kind',
          message: 'Bundle kind is required.',
          fieldPath: 'kind',
        ),
      );
    } else if (!BundleKind.isSupported(header.bundleKind)) {
      issues.add(
        BundleValidationIssue(
          code: 'unsupported_kind',
          message: 'Unsupported bundle kind: ${header.bundleKind}.',
          fieldPath: 'kind',
        ),
      );
    }
    if (expectedKind.trim().isNotEmpty &&
        header.bundleKind.trim() != expectedKind.trim()) {
      issues.add(
        BundleValidationIssue(
          code: 'unexpected_kind',
          message: 'Expected bundle kind $expectedKind.',
          fieldPath: 'kind',
        ),
      );
    }
    if (header.title.trim().isEmpty) {
      issues.add(
        const BundleValidationIssue(
          code: 'missing_title',
          message: 'Bundle title is required.',
          fieldPath: 'title',
        ),
      );
    }
    if (header.bundleVersion.trim().isEmpty) {
      issues.add(
        const BundleValidationIssue(
          code: 'missing_bundle_version',
          message: 'Bundle version is required.',
          fieldPath: 'bundle_version',
        ),
      );
    }
    if (header.schemaVersion <= 0) {
      issues.add(
        const BundleValidationIssue(
          code: 'invalid_schema_version',
          message: 'Schema version must be positive.',
          fieldPath: 'schema_version',
        ),
      );
    }
    final checksum = ValueReaders.stringValue(bundle['checksum']).trim();
    if (checksum.isEmpty) {
      issues.add(
        const BundleValidationIssue(
          code: 'missing_checksum',
          message: 'Bundle checksum is required.',
          fieldPath: 'checksum',
        ),
      );
    } else {
      final bundleWithoutChecksum = ValueReaders.deepCopyMap(bundle)
        ..remove('checksum');
      final expectedChecksum = _checksumService.checksumOf(
        bundleWithoutChecksum,
      );
      if (expectedChecksum != checksum) {
        issues.add(
          BundleValidationIssue(
            code: 'checksum_mismatch',
            message:
                'Bundle checksum mismatch. Expected $expectedChecksum but got $checksum.',
            fieldPath: 'checksum',
          ),
        );
      }
    }
    return BundleValidationResult(ok: issues.isEmpty, issues: issues);
  }
}
