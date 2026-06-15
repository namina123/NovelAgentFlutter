import '../common/source_asset_identity.dart';
import 'source_import_normalized_document.dart';
import 'source_import_request.dart';
import 'source_import_selection.dart';
import 'source_import_selection_kind.dart';

class SourceImportNormalizationService {
  const SourceImportNormalizationService();

  SourceImportRequest normalizeRequest(SourceImportRequest request) {
    // 中文注释: 这里先做 selection 的稳定排序与字段清洗，后续 reader 再负责真正的内容解析。
    return request.copyWith(
      selections: normalizeSelections(request),
      metadata: {
        ...request.metadata,
        'normalized_source_import_request': true,
        'selection_count': request.selections.length,
      },
    );
  }

  List<SourceImportSelection> normalizeSelections(SourceImportRequest request) {
    // 中文注释: selection 规范化只负责顺序、路径提示和媒体类型，不把目录扫描或文件读取塞进这里。
    final ordered = request.selections.map(_normalizeSelection).toList();
    ordered.sort(_compareSelections);
    return List<SourceImportSelection>.unmodifiable(ordered);
  }

  List<SourceImportNormalizedDocument> buildDocuments(
    SourceImportRequest request, {
    String content = '',
  }) {
    // 中文注释: normalized document 由 selection 投影而来，内容体可由后续 reader 再填充，不在这里读取磁盘。
    final selections = normalizeSelections(request);
    return List<SourceImportNormalizedDocument>.unmodifiable(
      selections.asMap().entries.map((entry) {
        return SourceImportNormalizedDocument.fromSelection(
          entry.value,
          sequence: entry.key + 1,
          content: content,
        );
      }),
    );
  }

  SourceImportSelection _normalizeSelection(SourceImportSelection selection) {
    final cleanSourceLocator = _cleanPath(selection.sourceLocator);
    final cleanRelativePathHint = _cleanPath(selection.relativePathHint);
    final normalizedMediaType = selection.mediaType.trim().isNotEmpty
        ? selection.mediaType.trim()
        : _guessMediaType(
            selectionKind: selection.selectionKind,
            sourceLocator: cleanSourceLocator,
          );
    final sourceIdentity = selection.sourceIdentity.copyWith(
      displayName: selection.sourceIdentity.displayName.trim().isNotEmpty
          ? selection.sourceIdentity.displayName.trim()
          : _fallbackDisplayName(cleanRelativePathHint, cleanSourceLocator),
      sourceKind: selection.sourceIdentity.sourceKind.trim().isNotEmpty
          ? selection.sourceIdentity.sourceKind.trim()
          : _fallbackSourceKind(selection.selectionKind),
      resolverUri: selection.sourceIdentity.resolverUri.trim().isNotEmpty
          ? selection.sourceIdentity.resolverUri.trim()
          : cleanSourceLocator,
      localHintPath: selection.sourceIdentity.localHintPath.trim().isNotEmpty
          ? SourceAssetIdentity.normalizeLocalHintPath(
              selection.sourceIdentity.localHintPath,
            )
          : SourceAssetIdentity.normalizeLocalHintPath(
              cleanRelativePathHint.isNotEmpty
                  ? cleanRelativePathHint
                  : cleanSourceLocator,
            ),
    );
    return selection.copyWith(
      sourceIdentity: sourceIdentity,
      sourceLocator: cleanSourceLocator,
      mediaType: normalizedMediaType,
      relativePathHint: cleanRelativePathHint,
    );
  }

  int _compareSelections(
    SourceImportSelection left,
    SourceImportSelection right,
  ) {
    // 中文注释: 排序只依据稳定字段，不依赖读取结果，避免导入合同在无 reader 场景下产生漂移。
    final orderCompare = left.sortOrder.compareTo(right.sortOrder);
    if (orderCompare != 0) {
      return orderCompare;
    }
    final kindCompare = left.selectionKind.compareTo(right.selectionKind);
    if (kindCompare != 0) {
      return kindCompare;
    }
    final leftIdentity = left.sourceIdentity.sourceAssetId.trim();
    final rightIdentity = right.sourceIdentity.sourceAssetId.trim();
    final identityCompare = leftIdentity.compareTo(rightIdentity);
    if (identityCompare != 0) {
      return identityCompare;
    }
    return left.selectionId.compareTo(right.selectionId);
  }

  String _cleanPath(String value) {
    final normalized = value.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.replaceAll(RegExp(r'/+'), '/');
  }

  String _guessMediaType({
    required String selectionKind,
    required String sourceLocator,
  }) {
    final clean = sourceLocator.trim().toLowerCase();
    if (selectionKind == SourceImportSelectionKinds.directory) {
      return 'inode/directory';
    }
    if (clean.endsWith('.md') || clean.endsWith('.markdown')) {
      return 'text/markdown';
    }
    if (clean.endsWith('.txt')) {
      return 'text/plain';
    }
    if (clean.endsWith('.epub')) {
      return 'application/epub+zip';
    }
    return 'text/plain';
  }

  String _fallbackDisplayName(String relativePathHint, String sourceLocator) {
    final candidate = relativePathHint.isNotEmpty ? relativePathHint : sourceLocator;
    if (candidate.isEmpty) {
      return 'source_document';
    }
    final normalized = candidate.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }

  String _fallbackSourceKind(String selectionKind) {
    switch (selectionKind) {
      case SourceImportSelectionKinds.directory:
        return 'directory';
      case SourceImportSelectionKinds.collection:
        return 'collection';
      case SourceImportSelectionKinds.singleFile:
      default:
        return 'file';
    }
  }
}

