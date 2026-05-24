import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_tree_order_store.dart';

class ProjectTreeOrderService {
  ProjectTreeOrderService({ProjectTreeOrderStore? store})
    : _store = store ?? ProjectTreeOrderStore();

  final ProjectTreeOrderStore _store;

  bool isInternalPath(String relativePath) {
    // 中文注释: 适配器外层只关心“是否为内部条目”，具体内部布局仍由仓储类自行封装。
    return _store.isInternalPath(relativePath);
  }

  Future<List<JsonMap>> sortEntries(
    String rootPath,
    List<JsonMap> entries,
  ) async {
    // 中文注释: 目录树排序按“同级排序 + 递归展开”重建，确保 GUI/CLI 都能看到一致的项目树顺序。
    final orderDocument = await _store.load(rootPath);
    final childrenByParent = <String, List<JsonMap>>{};
    for (final entry in entries) {
      final relativePath = ValueReaders.stringValue(entry['relative_path']);
      if (relativePath.trim().isEmpty) {
        continue;
      }
      final parentPath = _parentOf(relativePath);
      childrenByParent.putIfAbsent(parentPath, () => <JsonMap>[]).add(entry);
    }
    final ordered = <JsonMap>[];
    final visited = <String>{};

    void visit(String parentPath) {
      final siblings = childrenByParent[parentPath];
      if (siblings == null || siblings.isEmpty) {
        return;
      }
      final sortedSiblings = _sortSiblings(
        siblings,
        orderDocument[parentPath] ?? const <String>[],
      );
      for (final sibling in sortedSiblings) {
        final relativePath = ValueReaders.stringValue(sibling['relative_path']);
        if (!visited.add(relativePath)) {
          continue;
        }
        ordered.add(sibling);
        if (ValueReaders.boolValue(sibling['is_dir'])) {
          visit(relativePath);
        }
      }
    }

    visit('');
    final remaining = entries
        .where(
          (entry) => !visited.contains(
            ValueReaders.stringValue(entry['relative_path']),
          ),
        )
        .toList(growable: false);
    remaining.sort(_compareByPath);
    ordered.addAll(remaining);
    return ordered;
  }

  Future<ReorderProjectEntryResult> reorderEntry({
    required String rootPath,
    required String relativePath,
    required int targetIndex,
    required List<JsonMap> existingEntries,
  }) async {
    // 中文注释: 重排只改同级顺序元数据，不触碰真实文件内容和磁盘层级，降低副作用半径。
    final cleanRelativePath = relativePath.replaceAll('\\', '/').trim();
    final matchingEntry = existingEntries.where(
      (entry) =>
          ValueReaders.stringValue(entry['relative_path']) == cleanRelativePath,
    );
    if (matchingEntry.isEmpty) {
      throw ArgumentError.value(relativePath, 'relativePath', '项目条目不存在。');
    }
    final parentPath = _parentOf(cleanRelativePath);
    final siblingEntries = existingEntries
        .where(
          (entry) =>
              _parentOf(ValueReaders.stringValue(entry['relative_path'])) ==
              parentPath,
        )
        .toList(growable: true);
    if (siblingEntries.isEmpty) {
      throw ArgumentError.value(relativePath, 'relativePath', '未找到可重排的同级条目。');
    }
    final orderDocument = await _store.load(rootPath);
    final orderedSiblings = _sortSiblings(
      siblingEntries,
      orderDocument[parentPath] ?? const <String>[],
    );
    final currentIndex = orderedSiblings.indexWhere(
      (entry) =>
          ValueReaders.stringValue(entry['relative_path']) == cleanRelativePath,
    );
    if (currentIndex < 0) {
      throw ArgumentError.value(relativePath, 'relativePath', '项目条目不存在。');
    }
    final targetEntry = orderedSiblings.removeAt(currentIndex);
    final normalizedIndex = _clampIndex(targetIndex, orderedSiblings.length);
    orderedSiblings.insert(normalizedIndex, targetEntry);
    final orderedNames = orderedSiblings
        .map(
          (entry) =>
              ValueReaders.stringValue(entry['relative_path']).split('/').last,
        )
        .toList(growable: false);
    orderDocument[parentPath] = orderedNames;
    final hasEffectiveOrder = !_matchesDefaultSiblingOrder(
      orderedSiblings,
      orderedNames,
    );
    if (!hasEffectiveOrder) {
      orderDocument.remove(parentPath);
    }
    if (orderDocument.isEmpty) {
      await _store.delete(rootPath);
    } else {
      await _store.save(rootPath, orderDocument);
    }
    return ReorderProjectEntryResult(
      orderedSiblingNames: orderedNames,
      parentPath: parentPath,
      normalizedIndex: normalizedIndex,
      metadataPath: ProjectTreeOrderStore.internalRelativePath,
    );
  }

  List<JsonMap> _sortSiblings(List<JsonMap> siblings, List<String> order) {
    // 中文注释: 指定顺序只在同级生效，未出现在元数据中的条目回退到稳定字典序。
    final orderIndexByName = <String, int>{};
    for (var index = 0; index < order.length; index++) {
      orderIndexByName[order[index]] = index;
    }
    final sorted = siblings.toList(growable: true);
    sorted.sort((left, right) {
      final leftName = ValueReaders.stringValue(
        left['relative_path'],
      ).split('/').last;
      final rightName = ValueReaders.stringValue(
        right['relative_path'],
      ).split('/').last;
      final leftOrder = orderIndexByName[leftName];
      final rightOrder = orderIndexByName[rightName];
      if (leftOrder != null && rightOrder != null) {
        final compareOrder = leftOrder.compareTo(rightOrder);
        if (compareOrder != 0) {
          return compareOrder;
        }
      } else if (leftOrder != null) {
        return -1;
      } else if (rightOrder != null) {
        return 1;
      }
      return _compareByPath(left, right);
    });
    return sorted;
  }

  bool _matchesDefaultSiblingOrder(
    List<JsonMap> orderedSiblings,
    List<String> orderedNames,
  ) {
    // 中文注释: 如果顺序已经等于默认字典序，就不必继续保留显式元数据。
    final defaultSorted = orderedSiblings.toList(growable: true)
      ..sort(_compareByPath);
    final defaultNames = defaultSorted
        .map(
          (entry) =>
              ValueReaders.stringValue(entry['relative_path']).split('/').last,
        )
        .toList(growable: false);
    if (defaultNames.length != orderedNames.length) {
      return false;
    }
    for (var index = 0; index < defaultNames.length; index++) {
      if (defaultNames[index] != orderedNames[index]) {
        return false;
      }
    }
    return true;
  }

  int _compareByPath(JsonMap left, JsonMap right) {
    final leftPath = ValueReaders.stringValue(left['relative_path']);
    final rightPath = ValueReaders.stringValue(right['relative_path']);
    return leftPath.compareTo(rightPath);
  }

  int _clampIndex(int targetIndex, int siblingCountWithoutTarget) {
    // 中文注释: 工具层允许模型给出越界索引，这里统一夹紧到可落地范围，避免无意义报错打断链路。
    if (targetIndex <= 0) {
      return 0;
    }
    if (targetIndex >= siblingCountWithoutTarget) {
      return siblingCountWithoutTarget;
    }
    return targetIndex;
  }

  String _parentOf(String relativePath) {
    final clean = relativePath.replaceAll('\\', '/').trim();
    final slashIndex = clean.lastIndexOf('/');
    if (slashIndex <= 0) {
      return '';
    }
    return clean.substring(0, slashIndex);
  }
}

class ReorderProjectEntryResult {
  const ReorderProjectEntryResult({
    required this.orderedSiblingNames,
    required this.parentPath,
    required this.normalizedIndex,
    required this.metadataPath,
  });

  final List<String> orderedSiblingNames;
  final String parentPath;
  final int normalizedIndex;
  final String metadataPath;
}
