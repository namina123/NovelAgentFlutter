import 'foreshadow_record.dart';
import 'foreshadow_state_update_request.dart';
import 'foreshadow_status_catalog_service.dart';

class ForeshadowStateUpdatePlannerService {
  const ForeshadowStateUpdatePlannerService({
    ForeshadowStatusCatalogService? statusCatalogService,
  }) : _statusCatalogService =
           statusCatalogService ?? const ForeshadowStatusCatalogService();

  final ForeshadowStatusCatalogService _statusCatalogService;

  ForeshadowRecord plan({
    required ForeshadowStateUpdateRequest request,
    ForeshadowRecord? existingRecord,
  }) {
    // 中文注释: 伏笔主档合并规则保持纯领域逻辑，adapter 只负责把合并结果写到资产路径。
    final current = existingRecord;
    final title = _pickFirst(request.title, current?.title ?? '', '未命名伏笔');
    final recordId = _pickFirst(request.id, current?.id ?? '', _safeId(title), 'foreshadow');
    final status = _statusCatalogService.normalize(
      _pickFirst(
        request.status,
        current?.status ?? '',
        request.targetPayoffPath.trim().isEmpty
            ? ForeshadowStatusCatalogService.planted
            : ForeshadowStatusCatalogService.pendingPayoff,
      ),
    );
    return ForeshadowRecord(
      id: recordId,
      title: title,
      status: status,
      summary: _pickFirst(request.summary, current?.summary ?? ''),
      plantedChapterPath: _pickFirst(
        request.plantedChapterPath,
        current?.plantedChapterPath ?? '',
      ),
      targetPayoffPath: _pickFirst(
        request.targetPayoffPath,
        current?.targetPayoffPath ?? '',
      ),
      relatedEntityIds: _mergeStrings(
        current?.relatedEntityIds ?? const <String>[],
        request.relatedEntityIds,
      ),
      relatedTimelineIds: _mergeStrings(
        current?.relatedTimelineIds ?? const <String>[],
        request.relatedTimelineIds,
      ),
      relatedRelationshipIds: _mergeStrings(
        current?.relatedRelationshipIds ?? const <String>[],
        request.relatedRelationshipIds,
      ),
      relatedPaths: _mergeStrings(
        current?.relatedPaths ?? const <String>[],
        <String>[
          ...request.relatedPaths,
          if (request.plantedChapterPath.trim().isNotEmpty)
            request.plantedChapterPath.trim(),
          if (request.targetPayoffPath.trim().isNotEmpty)
            request.targetPayoffPath.trim(),
        ],
      ),
      triggerConditions: _mergeStrings(
        current?.triggerConditions ?? const <String>[],
        request.triggerConditions,
      ),
      payoffExpectations: _mergeStrings(
        current?.payoffExpectations ?? const <String>[],
        request.payoffExpectations,
      ),
      tags: _mergeStrings(current?.tags ?? const <String>[], request.tags),
      notes: _joinNotes(current?.notes ?? '', request.notes),
      sourcePath: current?.sourcePath ?? '',
      metadata: <String, Object?>{
        ...?current?.metadata,
        ...request.metadata,
      },
    );
  }

  String _pickFirst(String first, [String second = '', String third = '', String fourth = '']) {
    for (final candidate in <String>[first, second, third, fourth]) {
      if (candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return '';
  }

  List<String> _mergeStrings(List<String> left, List<String> right) {
    final result = <String>[];
    for (final value in <String>[...left, ...right]) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && !result.contains(trimmed)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  String _joinNotes(String left, String right) {
    final leftTrimmed = left.trim();
    final rightTrimmed = right.trim();
    if (leftTrimmed.isEmpty) {
      return rightTrimmed;
    }
    if (rightTrimmed.isEmpty || leftTrimmed.contains(rightTrimmed)) {
      return leftTrimmed;
    }
    return '$leftTrimmed\n\n$rightTrimmed'.trim();
  }

  String _safeId(String value) {
    var result = value.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result;
  }
}
