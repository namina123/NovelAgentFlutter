import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectContinuityInputDocumentCodecService {
  const ProjectContinuityInputDocumentCodecService();

  ProjectContinuityInputProfile parseDocument(JsonMap document) {
    return ProjectContinuityInputProfile(
      displayName: ValueReaders.stringValue(document['display_name']).trim(),
      usesMultipleWorlds: ValueReaders.boolValue(
        document['uses_multiple_worlds'],
      ),
      usesBranchingRoutes: ValueReaders.boolValue(
        document['uses_branching_routes'],
      ),
      usesReplayResets: ValueReaders.boolValue(document['uses_replay_resets']),
      requiresScopedIdentityOverlays: ValueReaders.boolValue(
        document['requires_scoped_identity_overlays'],
      ),
      worldLabels: ValueReaders.stringList(document['world_labels']),
      identityModeOverride: _enumByName(
        ContinuityIdentityMode.values,
        ValueReaders.stringValue(document['identity_mode_override']),
      ),
      memoryModeOverride: _enumByName(
        ContinuityMemoryMode.values,
        ValueReaders.stringValue(document['memory_mode_override']),
      ),
      stateModeOverride: _enumByName(
        ContinuityStateMode.values,
        ValueReaders.stringValue(document['state_mode_override']),
      ),
      causalModeOverride: _enumByName(
        ContinuityCausalMode.values,
        ValueReaders.stringValue(document['causal_mode_override']),
      ),
      branchModeOverride: _enumByName(
        ContinuityBranchMode.values,
        ValueReaders.stringValue(document['branch_mode_override']),
      ),
      visibilityModeOverride: _enumByName(
        ContinuityVisibilityMode.values,
        ValueReaders.stringValue(document['visibility_mode_override']),
      ),
      notes: ValueReaders.stringValue(document['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['metadata']),
      ),
    );
  }

  JsonMap toDocument(ProjectContinuityInputProfile profile) {
    return <String, Object?>{
      'schema_version': 1,
      'display_name': profile.displayName,
      'uses_multiple_worlds': profile.usesMultipleWorlds,
      'uses_branching_routes': profile.usesBranchingRoutes,
      'uses_replay_resets': profile.usesReplayResets,
      'requires_scoped_identity_overlays':
          profile.requiresScopedIdentityOverlays,
      'world_labels': profile.worldLabels,
      'identity_mode_override': profile.identityModeOverride?.name ?? '',
      'memory_mode_override': profile.memoryModeOverride?.name ?? '',
      'state_mode_override': profile.stateModeOverride?.name ?? '',
      'causal_mode_override': profile.causalModeOverride?.name ?? '',
      'branch_mode_override': profile.branchModeOverride?.name ?? '',
      'visibility_mode_override': profile.visibilityModeOverride?.name ?? '',
      'notes': profile.notes,
      'metadata': ValueReaders.deepCopyMap(profile.metadata),
    };
  }

  T? _enumByName<T extends Enum>(Iterable<T> values, String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return null;
    }
    for (final value in values) {
      if (value.name == clean) {
        return value;
      }
    }
    return null;
  }
}
