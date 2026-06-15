import '../common/json_types.dart';
import '../common/source_asset_identity.dart';
import '../common/value_readers.dart';
import 'source_import_selection_kind.dart';

class SourceImportSelection {
  const SourceImportSelection({
    required this.selectionId,
    required this.selectionKind,
    required this.sourceIdentity,
    this.sourceLocator = '',
    this.sortOrder = 0,
    this.mediaType = '',
    this.relativePathHint = '',
    this.recursive = true,
    this.metadata = const <String, Object?>{},
  });

  final String selectionId;
  final String selectionKind;
  final SourceAssetIdentity sourceIdentity;
  final String sourceLocator;
  final int sortOrder;
  final String mediaType;
  final String relativePathHint;
  final bool recursive;
  final JsonMap metadata;

  SourceImportSelection copyWith({
    String? selectionId,
    String? selectionKind,
    SourceAssetIdentity? sourceIdentity,
    String? sourceLocator,
    int? sortOrder,
    String? mediaType,
    String? relativePathHint,
    bool? recursive,
    JsonMap? metadata,
  }) {
    // 中文注释: selection copyWith 只服务共享导入合同的规范化与桥接，不在这里偷偷做 reader 或扫描。
    return SourceImportSelection(
      selectionId: selectionId ?? this.selectionId,
      selectionKind: selectionKind ?? this.selectionKind,
      sourceIdentity: sourceIdentity ?? this.sourceIdentity,
      sourceLocator: sourceLocator ?? this.sourceLocator,
      sortOrder: sortOrder ?? this.sortOrder,
      mediaType: mediaType ?? this.mediaType,
      relativePathHint: relativePathHint ?? this.relativePathHint,
      recursive: recursive ?? this.recursive,
      metadata: metadata ?? this.metadata,
    );
  }

  factory SourceImportSelection.fromJson(JsonMap json) {
    // 中文注释: selection 允许从 JSON 回读，方便导入合同与测试用例共享同一份结构化输入。
    return SourceImportSelection(
      selectionId: ValueReaders.stringValue(json['selection_id']).trim(),
      selectionKind: ValueReaders.stringValue(json['selection_kind']).trim(),
      sourceIdentity: SourceAssetIdentity.fromJson(
        ValueReaders.mapValue(json['source_identity']),
      ),
      sourceLocator: ValueReaders.stringValue(json['source_locator']).trim(),
      sortOrder: ValueReaders.intValue(json['sort_order']),
      mediaType: ValueReaders.stringValue(json['media_type']).trim(),
      relativePathHint: ValueReaders.stringValue(
        json['relative_path_hint'],
      ).trim(),
      recursive: ValueReaders.boolValue(json['recursive'], true),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: selection 序列化显式保留 source identity、排序和相对路径提示，避免调用点再自己拼字段。
    return <String, Object?>{
      'selection_id': selectionId,
      'selection_kind': selectionKind,
      'source_identity': sourceIdentity.toJson(),
      'source_locator': sourceLocator,
      'sort_order': sortOrder,
      'media_type': mediaType,
      'relative_path_hint': relativePathHint,
      'recursive': recursive,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 这里只验证 selection 合同壳层，不替 reader 或导入执行做任何 IO 判断。
    final result = <String>[];
    if (selectionId.trim().isEmpty) {
      result.add('missing_source_import_selection_id');
    }
    if (!SourceImportSelectionKinds.knownValues.contains(selectionKind)) {
      result.add('invalid_source_import_selection_kind');
    }
    result.addAll(sourceIdentity.validateBasics());
    if (selectionKind != SourceImportSelectionKinds.collection &&
        sourceLocator.trim().isEmpty) {
      result.add('missing_source_import_selection_locator');
    }
    if (sortOrder < 0) {
      result.add('invalid_source_import_selection_sort_order');
    }
    if (_isAbsolutePath(relativePathHint)) {
      result.add('source_import_relative_path_hint_must_be_relative');
    }
    return result;
  }

  static bool _isAbsolutePath(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return false;
    }
    return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(clean) ||
        clean.startsWith('\\\\') ||
        clean.startsWith('/');
  }
}

