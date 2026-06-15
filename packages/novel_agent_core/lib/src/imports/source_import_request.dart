import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'source_import_selection.dart';

abstract final class SourceImportSortModes {
  static const String selectionOrder = 'selection_order';
  static const String sourceIdentity = 'source_identity';
  static const String relativePath = 'relative_path';

  static const List<String> knownValues = <String>[
    selectionOrder,
    sourceIdentity,
    relativePath,
  ];
}

class SourceImportRequest {
  const SourceImportRequest({
    required this.requestId,
    required this.selections,
    this.sortMode = SourceImportSortModes.selectionOrder,
    this.metadata = const <String, Object?>{},
  });

  final String requestId;
  final List<SourceImportSelection> selections;
  final String sortMode;
  final JsonMap metadata;

  SourceImportRequest copyWith({
    String? requestId,
    List<SourceImportSelection>? selections,
    String? sortMode,
    JsonMap? metadata,
  }) {
    // 中文注释: request copyWith 只用于规范化排序和桥接，不在这里把中性合同重新变成业务编排中心。
    return SourceImportRequest(
      requestId: requestId ?? this.requestId,
      selections: selections ?? this.selections,
      sortMode: sortMode ?? this.sortMode,
      metadata: metadata ?? this.metadata,
    );
  }

  factory SourceImportRequest.fromJson(JsonMap json) {
    // 中文注释: request 反序列化让一般导入与拆书导入可以回读同一份 source contract。
    return SourceImportRequest(
      requestId: ValueReaders.stringValue(json['request_id']).trim(),
      selections: ValueReaders.mapList(json['selections'])
          .map(SourceImportSelection.fromJson)
          .toList(growable: false),
      sortMode: ValueReaders.stringValue(
        json['sort_mode'],
        SourceImportSortModes.selectionOrder,
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: request 序列化把 selections、排序模式与 metadata 一并保留，方便后续扫描和桥接使用。
    return <String, Object?>{
      'request_id': requestId,
      'selections': selections
          .map((selection) => selection.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'sort_mode': sortMode,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 这里只确认 request 的结构化边界，不替上层判断到底该走拆书还是一般导入。
    final result = <String>[];
    if (requestId.trim().isEmpty) {
      result.add('missing_source_import_request_id');
    }
    if (selections.isEmpty) {
      result.add('missing_source_import_selections');
    }
    if (!SourceImportSortModes.knownValues.contains(sortMode)) {
      result.add('invalid_source_import_sort_mode');
    }
    for (final selection in selections) {
      result.addAll(selection.validateBasics());
    }
    return result;
  }
}

