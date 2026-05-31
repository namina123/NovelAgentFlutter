import '../common/value_readers.dart';
import '../continuity/continuation_scope_overlay.dart';
import '../continuity/continuity_asset_reference.dart';
import '../continuity/continuity_frame.dart';
import '../continuity/continuity_runtime_resolver_service.dart';
import '../continuity/project_continuity_bundle.dart';
import 'long_task_continuity_context_projection.dart';
import 'long_task_path_policy_service.dart';

class LongTaskContinuityContextProjectionService {
  LongTaskContinuityContextProjectionService({
    required LongTaskPathPolicyService pathPolicyService,
    ContinuityRuntimeResolverService? continuityRuntimeResolverService,
  }) : _pathPolicyService = pathPolicyService,
       _continuityRuntimeResolverService =
           continuityRuntimeResolverService ??
           const ContinuityRuntimeResolverService();

  final LongTaskPathPolicyService _pathPolicyService;
  final ContinuityRuntimeResolverService _continuityRuntimeResolverService;

  LongTaskContinuityContextProjection project(
    ProjectContinuityBundle bundle, {
    String frameId = '',
    String scopeId = '',
    String mechanicProfileId = '',
  }) {
    final resolution = _continuityRuntimeResolverService.resolve(
      bundle,
      frameId: frameId,
      scopeId: scopeId,
      mechanicProfileId: mechanicProfileId,
    );
    final scopeIds = resolution.scopeChain.scopeIds;
    final overlays = _matchingOverlays(bundle.scopeOverlays, scopeIds);
    final activeFrame = resolution.activeFrame.frame;
    return LongTaskContinuityContextProjection(
      scopeIds: scopeIds,
      frameId: activeFrame?.id ?? '',
      canonicalPaths: _pathPolicyService.mergePaths(
        _pathsFromBundleMetadata(bundle),
        _sourcePathsFromReferences(resolution.canonicalAssetReferences),
      ),
      overlayPaths: _overlayPaths(overlays),
      statePaths: _pathPolicyService.mergePaths(
        _pathsFromFrameMetadata(activeFrame),
        _sourcePathsFromReferences(resolution.stateAssetReferences),
      ),
      tailWindowPaths: _pathPolicyService.mergePaths(
        _tailWindowPathsFromBundleMetadata(bundle),
        _tailWindowPathsFromFrameMetadata(activeFrame),
      ),
    );
  }

  List<ContinuationScopeOverlay> _matchingOverlays(
    List<ContinuationScopeOverlay> overlays,
    List<String> scopeIds,
  ) {
    final matches = overlays
        .where((overlay) => scopeIds.contains(overlay.scopeId))
        .toList(growable: false);
    matches.sort((left, right) {
      final byScope = scopeIds
          .indexOf(left.scopeId)
          .compareTo(scopeIds.indexOf(right.scopeId));
      if (byScope != 0) {
        return byScope;
      }
      return left.priority.compareTo(right.priority);
    });
    return matches;
  }

  List<String> _overlayPaths(List<ContinuationScopeOverlay> overlays) {
    final metadataPaths = <Object?>[];
    final referencePaths = <Object?>[];
    for (final overlay in overlays) {
      metadataPaths.addAll(_pathsFromOverlayMetadata(overlay));
      referencePaths.addAll(
        _sourcePathsFromReferences(overlay.assetReferences),
      );
    }
    return _pathPolicyService.mergePaths(metadataPaths, referencePaths);
  }

  List<String> _pathsFromBundleMetadata(ProjectContinuityBundle bundle) {
    return _pathPolicyService.stringList(bundle.metadata['context_paths']);
  }

  List<String> _tailWindowPathsFromBundleMetadata(
    ProjectContinuityBundle bundle,
  ) {
    return _pathPolicyService.stringList(bundle.metadata['tail_window_paths']);
  }

  List<String> _pathsFromOverlayMetadata(ContinuationScopeOverlay overlay) {
    return _pathPolicyService.stringList(overlay.metadata['context_paths']);
  }

  List<String> _pathsFromFrameMetadata(ContinuityFrame? frame) {
    if (frame == null) {
      return const <String>[];
    }
    return _pathPolicyService.stringList(frame.metadata['context_paths']);
  }

  List<String> _tailWindowPathsFromFrameMetadata(ContinuityFrame? frame) {
    if (frame == null) {
      return const <String>[];
    }
    return _pathPolicyService.stringList(frame.metadata['tail_window_paths']);
  }

  List<String> _sourcePathsFromReferences(
    List<ContinuityAssetReference> references,
  ) {
    final result = <String>[];
    for (final reference in references) {
      final sourcePath = _sourcePathOf(reference);
      if (sourcePath.isNotEmpty && !result.contains(sourcePath)) {
        result.add(sourcePath);
      }
    }
    return result;
  }

  String _sourcePathOf(ContinuityAssetReference reference) {
    return _pathPolicyService.safeProjectPath(
      ValueReaders.stringValue(reference.sourcePath),
    );
  }
}
