import '../models/project_open_snapshot.dart';
import '../services/project_open_scan_runtime.dart';

class ProjectOpenController {
  ProjectOpenController({
    ProjectOpenScanRuntime? projectOpenScanRuntime,
  }) : _projectOpenScanRuntime =
           projectOpenScanRuntime ?? ProjectOpenScanRuntime();

  final ProjectOpenScanRuntime _projectOpenScanRuntime;
  ProjectOpenSnapshot _cachedSnapshot = ProjectOpenSnapshot.initial();
  String _cacheKey = '';
  bool _hasCache = false;
  Future<ProjectOpenSnapshot>? _inFlightRefresh;
  String _inFlightKey = '';

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
    if (!forceRefresh && _hasCache && key == _cacheKey) {
      final nextSelectedEntryId = _resolveSelectedEntryId(
        selectedEntryId: selectedEntryId,
        fallbackSelectedEntryId: _cachedSnapshot.selectedEntryId,
      );
      final nextStatus =
          status.trim().isNotEmpty ? status.trim() : _cachedSnapshot.status;
      if (_cachedSnapshot.projectsRootPath.trim() ==
              projectsRootPath.trim() &&
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
    if (!forceRefresh &&
        _inFlightRefresh != null &&
        _inFlightKey == key) {
      return _inFlightRefresh!;
    }
    final refreshFuture = _projectOpenScanRuntime.scan(
      projectsRootPath: projectsRootPath,
      recentProjectPath: recentProjectPath,
      currentProjectPath: currentProjectPath,
      allowImportLocal: allowImportLocal,
      selectedEntryId: selectedEntryId,
      status: status,
    );
    _inFlightRefresh = refreshFuture;
    _inFlightKey = key;
    final snapshot = await refreshFuture;
    try {
      _cachedSnapshot = snapshot;
      _cacheKey = key;
      _hasCache = true;
      return snapshot;
    } finally {
      if (identical(_inFlightRefresh, refreshFuture)) {
        _inFlightRefresh = null;
        _inFlightKey = '';
      }
    }
  }

  ProjectOpenSnapshot selectEntry(String entryId) {
    _cachedSnapshot = _cachedSnapshot.selectEntry(entryId);
    return _cachedSnapshot;
  }

  void clearCache() {
    _cachedSnapshot = ProjectOpenSnapshot.initial();
    _cacheKey = '';
    _hasCache = false;
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
