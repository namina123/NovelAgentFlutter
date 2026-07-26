class ReferenceExtractionIdentityService {
  const ReferenceExtractionIdentityService();

  String resolveRunId({
    required String requestedRunId,
    required DateTime now,
    required String fallbackPrefix,
  }) {
    final trimmed = requestedRunId.trim();
    return trimmed.isEmpty
        ? '${fallbackPrefix}_${now.microsecondsSinceEpoch}'
        : trimmed;
  }

  String resolvePackageId({
    required String sourceTitle,
    required String explicitValue,
    required DateTime now,
    String? stagedValue,
  }) {
    final trimmed = explicitValue.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    final staged = (stagedValue ?? '').trim();
    if (staged.isNotEmpty) {
      return staged;
    }
    final dotIndex = sourceTitle.lastIndexOf('.');
    final baseName = dotIndex > 0
        ? sourceTitle.substring(0, dotIndex)
        : sourceTitle;
    final safeBaseName = _safeFileName(baseName, fallback: 'reference_source');
    return 'ref_${safeBaseName}_${now.microsecondsSinceEpoch}';
  }

  String resolvePackageVersionId({
    required String explicitValue,
    required DateTime now,
    String? stagedValue,
  }) {
    final trimmed = explicitValue.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    final staged = (stagedValue ?? '').trim();
    if (staged.isNotEmpty) {
      return staged;
    }
    final compact = now
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '');
    return 'v_$compact';
  }

  String resolveVersionLabel({
    required String packageVersionId,
    String? stagedValue,
  }) {
    final trimmed = (stagedValue ?? '').trim();
    return trimmed.isEmpty ? packageVersionId : trimmed;
  }

  String resolveDisplayName({
    required String sourceTitle,
    String? stagedValue,
  }) {
    final trimmed = (stagedValue ?? '').trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return '参考资产提取：$sourceTitle';
  }

  String resolveCreatedBy({String? stagedValue}) {
    final trimmed = (stagedValue ?? '').trim();
    return trimmed.isEmpty
        ? 'project_reference_extraction_runtime_service'
        : trimmed;
  }

  String _safeFileName(String input, {required String fallback}) {
    var result = input.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? fallback : result;
  }
}
