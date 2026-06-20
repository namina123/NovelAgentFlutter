import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/resource_entry_view_data.dart';
import 'workspace_resource_display_service.dart';

class WorkbenchResourceTreeProjectionService {
  WorkbenchResourceTreeProjectionService({
    WorkspaceResourceDisplayService resourceDisplayService =
        const WorkspaceResourceDisplayService(),
  }) : _resourceDisplayService = resourceDisplayService;

  final WorkspaceResourceDisplayService _resourceDisplayService;

  List<ResourceEntryViewData> project({
    required List<JsonMap> snapshotEntries,
    required Set<String> expandedDirectories,
    required String selectedId,
  }) {
    final snapshot = _snapshotFor(snapshotEntries);
    final normalizedExpandedDirectories = expandedDirectories
        .where(snapshot.knownDirectoryPaths.contains)
        .map(_normalizePath)
        .toSet();
    final baseEntries = _projectBase(
      snapshot: snapshot,
      expandedDirectories: normalizedExpandedDirectories,
    );
    final normalizedSelectedId = _normalizePath(selectedId);
    if (normalizedSelectedId.isEmpty) {
      return baseEntries;
    }
    final cachedSelectedEntries = _cachedSelectedEntries;
    if (identical(_cachedSelectedBaseEntries, baseEntries) &&
        _cachedSelectedId == normalizedSelectedId &&
        cachedSelectedEntries != null) {
      return cachedSelectedEntries;
    }
    final selectedEntries = _markSelection(baseEntries, normalizedSelectedId);
    _cachedSelectedBaseEntries = baseEntries;
    _cachedSelectedId = normalizedSelectedId;
    _cachedSelectedEntries = selectedEntries;
    return selectedEntries;
  }

  bool isDirectory({
    required List<JsonMap> snapshotEntries,
    required String relativePath,
  }) {
    return _snapshotFor(snapshotEntries).isDirectory(relativePath);
  }

  bool containsPath({
    required List<JsonMap> snapshotEntries,
    required String relativePath,
  }) {
    return _snapshotFor(snapshotEntries).containsPath(relativePath);
  }

  Set<String> defaultExpandedDirectories(List<JsonMap> snapshotEntries) {
    return _snapshotFor(snapshotEntries).defaultExpandedDirectories;
  }

  Set<String> knownDirectoryPaths(List<JsonMap> snapshotEntries) {
    return _snapshotFor(snapshotEntries).knownDirectoryPaths;
  }

  Set<String> mergedExpandedDirectories({
    required List<JsonMap> snapshotEntries,
    required Set<String> currentExpandedDirectories,
    required String selectedId,
  }) {
    final snapshot = _snapshotFor(snapshotEntries);
    final nextExpanded = currentExpandedDirectories
        .where(snapshot.knownDirectoryPaths.contains)
        .toSet();
    final parts = _normalizePath(selectedId).split('/');
    var current = '';
    for (var index = 0; index < parts.length - 1; index++) {
      current = current.isEmpty ? parts[index] : '$current/${parts[index]}';
      if (snapshot.knownDirectoryPaths.contains(current)) {
        nextExpanded.add(current);
      }
    }
    if (nextExpanded.isEmpty) {
      return snapshot.defaultExpandedDirectories;
    }
    return nextExpanded;
  }

  _SnapshotProjection _snapshotFor(List<JsonMap> entries) {
    final current = _cachedSnapshot;
    if (current != null && identical(current.sourceEntries, entries)) {
      return current;
    }
    final next = _SnapshotProjection(
      sourceEntries: entries,
      resourceDisplayService: _resourceDisplayService,
    );
    _cachedSnapshot = next;
    _cachedBaseEntries = null;
    _cachedExpandedSignature = '';
    _cachedSelectedBaseEntries = null;
    _cachedSelectedEntries = null;
    _cachedSelectedId = '';
    return next;
  }

  List<ResourceEntryViewData> _projectBase({
    required _SnapshotProjection snapshot,
    required Set<String> expandedDirectories,
  }) {
    final signature = _signatureOfSet(expandedDirectories);
    if (identical(_cachedSnapshot, snapshot) &&
        _cachedExpandedSignature == signature &&
        _cachedBaseEntries != null) {
      return _cachedBaseEntries!;
    }
    final projected = snapshot.project(expandedDirectories);
    _cachedSnapshot = snapshot;
    _cachedExpandedSignature = signature;
    _cachedBaseEntries = projected;
    _cachedSelectedBaseEntries = null;
    _cachedSelectedEntries = null;
    _cachedSelectedId = '';
    return projected;
  }

  List<ResourceEntryViewData> _markSelection(
    List<ResourceEntryViewData> entries,
    String selectedId,
  ) {
    final normalizedSelectedId = _normalizePath(selectedId);
    if (normalizedSelectedId.isEmpty) {
      return entries;
    }
    return entries
        .map(
          (entry) => entry.copyWith(
            isSelected: _normalizePath(entry.id) == normalizedSelectedId,
          ),
        )
        .toList(growable: false);
  }

  String _normalizePath(String value) {
    return value.trim().replaceAll('\\', '/');
  }

  String _signatureOfSet(Set<String> values) {
    final items = values.map(_normalizePath).toList(growable: true)..sort();
    return items.join('\u0000');
  }

  _SnapshotProjection? _cachedSnapshot;
  String _cachedExpandedSignature = '';
  List<ResourceEntryViewData>? _cachedBaseEntries;
  List<ResourceEntryViewData>? _cachedSelectedBaseEntries;
  List<ResourceEntryViewData>? _cachedSelectedEntries;
  String _cachedSelectedId = '';
}

class _SnapshotProjection {
  _SnapshotProjection({
    required this.sourceEntries,
    required WorkspaceResourceDisplayService resourceDisplayService,
  }) : _resourceDisplayService = resourceDisplayService {
    final visibleEntries = sourceEntries
        .where(
          (entry) => !_resourceDisplayService.shouldHidePath(
            _stringValue(entry['relative_path']),
          ),
        )
        .toList(growable: false);
    for (final entry in visibleEntries) {
      final relativePath = _normalizePath(_stringValue(entry['relative_path']));
      if (relativePath.isEmpty) {
        continue;
      }
      final isDirectory = entry['is_dir'] == true;
      final node = _SnapshotNode(
        entry: entry,
        relativePath: relativePath,
        isDirectory: isDirectory,
      );
      _entriesByPath[relativePath] = node;
      final parentPath = _parentPathOf(relativePath);
      _childrenByParent
          .putIfAbsent(parentPath, () => <_SnapshotNode>[])
          .add(node);
      if (isDirectory) {
        _knownDirectoryPaths.add(relativePath);
      }
    }

    for (final nodes in _childrenByParent.values) {
      nodes.sort((left, right) {
        return _resourceDisplayService.compareEntries(left.entry, right.entry);
      });
    }

    _defaultExpandedDirectories = _knownDirectoryPaths
        .where((path) => path.isNotEmpty && !path.contains('/'))
        .toSet();
  }

  final List<JsonMap> sourceEntries;
  final WorkspaceResourceDisplayService _resourceDisplayService;
  final Map<String, _SnapshotNode> _entriesByPath = <String, _SnapshotNode>{};
  final Map<String, List<_SnapshotNode>> _childrenByParent =
      <String, List<_SnapshotNode>>{};
  final Set<String> _knownDirectoryPaths = <String>{};
  late final Set<String> _defaultExpandedDirectories;

  Set<String> get knownDirectoryPaths =>
      Set<String>.unmodifiable(_knownDirectoryPaths);

  Set<String> get defaultExpandedDirectories =>
      Set<String>.unmodifiable(_defaultExpandedDirectories);

  bool isDirectory(String relativePath) {
    return _entriesByPath[_normalizePath(relativePath)]?.isDirectory ?? false;
  }

  bool containsPath(String relativePath) {
    return _entriesByPath.containsKey(_normalizePath(relativePath));
  }

  List<ResourceEntryViewData> project(Set<String> expandedDirectories) {
    final normalizedExpandedDirectories = expandedDirectories
        .where(_knownDirectoryPaths.contains)
        .toSet();
    final result = <ResourceEntryViewData>[];

    void visit(String parentPath, int depth) {
      final siblings = _childrenByParent[parentPath];
      if (siblings == null || siblings.isEmpty) {
        return;
      }
      for (final node in siblings) {
        final childCount = _childrenByParent[node.relativePath]?.length ?? 0;
        final isExpanded =
            !node.isDirectory ||
            normalizedExpandedDirectories.contains(node.relativePath);
        result.add(
          ResourceEntryViewData(
            id: node.relativePath,
            title: _resourceDisplayService.titleOf(
              node.relativePath,
              isDirectory: node.isDirectory,
            ),
            relativePath: node.relativePath,
            depth: depth,
            isDirectory: node.isDirectory,
            childCount: childCount,
            hasChildren: childCount > 0,
            isExpanded: isExpanded,
          ),
        );
        if (node.isDirectory && isExpanded) {
          visit(node.relativePath, depth + 1);
        }
      }
    }

    visit('', 0);
    return result;
  }

  String _normalizePath(String value) {
    return value.trim().replaceAll('\\', '/');
  }

  String _parentPathOf(String relativePath) {
    final slashIndex = relativePath.lastIndexOf('/');
    if (slashIndex <= 0) {
      return '';
    }
    return relativePath.substring(0, slashIndex);
  }

  String _stringValue(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }
}

class _SnapshotNode {
  _SnapshotNode({
    required this.entry,
    required this.relativePath,
    required this.isDirectory,
  });

  final JsonMap entry;
  final String relativePath;
  final bool isDirectory;
}
