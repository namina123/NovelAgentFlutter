import '../models/project_open_snapshot.dart';
import '../services/project_open_scan_runtime.dart';

class ProjectOpenController {
  ProjectOpenController({ProjectOpenScanRuntime? projectOpenScanRuntime})
    : _projectOpenScanRuntime =
          projectOpenScanRuntime ?? ProjectOpenScanRuntime();

  final ProjectOpenScanRuntime _projectOpenScanRuntime;
  ProjectOpenSnapshot _cachedSnapshot = ProjectOpenSnapshot.initial();
  String _cacheKey = '';
  bool _hasCache = false;
  Future<ProjectOpenSnapshot>? _inFlightRefresh;
  String _inFlightKey = '';
  int _selectionRevision = 0;
  int _inFlightSelectionRevision = 0;

  ProjectOpenSnapshot get snapshot => _cachedSnapshot;

  Future<ProjectOpenSnapshot> refreshSnapshot({
    required String projectsRootPath,
    required String recentProjectPath,
    required String currentProjectPath,
    required bool allowImportLocal,
    String selectedEntryId = '',
    String status = '',
    bool forceRefresh = false,
  }) async {
    final key = _keyOf(
      projectsRootPath: projectsRootPath,
      recentProjectPath: recentProjectPath,
      currentProjectPath: currentProjectPath,
      allowImportLocal: allowImportLocal,
    );
    // Discovery scans share one cache. Serialize them so an older isolate
    // result cannot overwrite a newer library context after a root switch.
    while (_inFlightRefresh != null) {
      if (!forceRefresh && _inFlightKey == key) {
        return _preserveNewerSelection(
          await _inFlightRefresh!,
          _inFlightSelectionRevision,
        );
      }
      await _inFlightRefresh!;
    }
    if (!forceRefresh && _hasCache && key == _cacheKey) {
      final nextSelectedEntryId = _resolveSelectedEntryId(
        selectedEntryId: selectedEntryId,
        fallbackSelectedEntryId: _cachedSnapshot.selectedEntryId,
      );
      // Status text is transient feedback. Keeping an old open failure after
      // a later ordinary navigation makes the project library look broken.
      final nextStatus = status.trim();
      if (_cachedSnapshot.projectsRootPath.trim() == projectsRootPath.trim() &&
          _cachedSnapshot.recentProjectPath.trim() ==
              recentProjectPath.trim() &&
          _cachedSnapshot.currentProjectPath.trim() ==
              currentProjectPath.trim() &&
          _cachedSnapshot.allowImportLocal == allowImportLocal &&
          _cachedSnapshot.selectedEntryId == nextSelectedEntryId &&
          _cachedSnapshot.status == nextStatus) {
        return _cachedSnapshot;
      }
      final nextSnapshot = _cachedSnapshot.copyWith(
        projectsRootPath: projectsRootPath.trim(),
        recentProjectPath: recentProjectPath.trim(),
        currentProjectPath: currentProjectPath.trim(),
        allowImportLocal: allowImportLocal,
        selectedEntryId: nextSelectedEntryId,
        status: nextStatus,
      );
      _cachedSnapshot = nextSnapshot;
      return nextSnapshot;
    }
    final selectionRevisionAtRefreshStart = _selectionRevision;
    final refreshFuture = _scanWithRecovery(
      key: key,
      projectsRootPath: projectsRootPath,
      recentProjectPath: recentProjectPath,
      currentProjectPath: currentProjectPath,
      allowImportLocal: allowImportLocal,
      selectedEntryId: selectedEntryId,
      status: status,
    );
    _inFlightRefresh = refreshFuture;
    _inFlightKey = key;
    _inFlightSelectionRevision = selectionRevisionAtRefreshStart;
    final snapshot = _preserveNewerSelection(
      await refreshFuture,
      selectionRevisionAtRefreshStart,
    );
    try {
      _cachedSnapshot = snapshot;
      _cacheKey = key;
      _hasCache = true;
      return snapshot;
    } finally {
      if (identical(_inFlightRefresh, refreshFuture)) {
        _inFlightRefresh = null;
        _inFlightKey = '';
        _inFlightSelectionRevision = 0;
      }
    }
  }

  ProjectOpenSnapshot selectEntry(String entryId) {
    _selectionRevision += 1;
    _cachedSnapshot = _cachedSnapshot.selectEntry(entryId);
    return _cachedSnapshot;
  }

  void clearCache() {
    _cachedSnapshot = ProjectOpenSnapshot.initial();
    _cacheKey = '';
    _hasCache = false;
  }

  Future<ProjectOpenSnapshot> _scanWithRecovery({
    required String key,
    required String projectsRootPath,
    required String recentProjectPath,
    required String currentProjectPath,
    required bool allowImportLocal,
    required String selectedEntryId,
    required String status,
  }) async {
    try {
      return await _projectOpenScanRuntime.scan(
        projectsRootPath: projectsRootPath,
        recentProjectPath: recentProjectPath,
        currentProjectPath: currentProjectPath,
        allowImportLocal: allowImportLocal,
        selectedEntryId: selectedEntryId,
        status: status,
      );
    } catch (_) {
      // A temporary filesystem failure must leave the library usable. Retain
      // the last matching discovery result and expose actionable feedback.
      final cachedSnapshot = _hasCache && _cacheKey == key
          ? _cachedSnapshot
          : ProjectOpenSnapshot.initial();
      return ProjectOpenSnapshot(
        projectsRootPath: projectsRootPath.trim(),
        recentProjectPath: recentProjectPath.trim(),
        currentProjectPath: currentProjectPath.trim(),
        allowImportLocal: allowImportLocal,
        records: cachedSnapshot.records,
        selectedEntryId: _resolveSelectedEntryId(
          selectedEntryId: selectedEntryId,
          fallbackSelectedEntryId: cachedSnapshot.selectedEntryId,
        ),
        status: status.trim().isNotEmpty
            ? status.trim()
            : '无法刷新作品库，请检查项目目录是否可访问。',
      );
    }
  }

  ProjectOpenSnapshot _preserveNewerSelection(
    ProjectOpenSnapshot snapshot,
    int selectionRevisionAtRefreshStart,
  ) {
    if (_selectionRevision == selectionRevisionAtRefreshStart) {
      return snapshot;
    }
    final currentSelectionId = _cachedSnapshot.selectedEntryId.trim();
    if (currentSelectionId.isEmpty ||
        !snapshot.records.any((record) => record.id == currentSelectionId)) {
      return snapshot;
    }
    return snapshot.copyWith(selectedEntryId: currentSelectionId);
  }

  String _keyOf({
    required String projectsRootPath,
    required String recentProjectPath,
    required String currentProjectPath,
    required bool allowImportLocal,
  }) {
    return [
      projectsRootPath.trim().replaceAll('\\', '/'),
      recentProjectPath.trim().replaceAll('\\', '/'),
      currentProjectPath.trim().replaceAll('\\', '/'),
      allowImportLocal ? '1' : '0',
    ].join('|');
  }

  String _resolveSelectedEntryId({
    required String selectedEntryId,
    required String fallbackSelectedEntryId,
  }) {
    final cleanSelectedEntryId = selectedEntryId.trim();
    if (cleanSelectedEntryId.isNotEmpty) {
      return cleanSelectedEntryId;
    }
    return fallbackSelectedEntryId.trim();
  }
}
