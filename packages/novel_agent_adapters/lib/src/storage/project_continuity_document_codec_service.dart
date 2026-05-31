import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_continuity_json_codec_support.dart';

class ProjectContinuityDocumentCodecService {
  ProjectContinuityDocumentCodecService({
    ProjectContinuityJsonCodecSupport? codecSupport,
  }) : _codecSupport =
           codecSupport ?? const ProjectContinuityJsonCodecSupport();

  final ProjectContinuityJsonCodecSupport _codecSupport;

  ProjectContinuityBundle parseDocument(
    JsonMap document, {
    required List<ContinuationScope> scopes,
    required List<ContinuationScopeOverlay> scopeOverlays,
    required List<ContinuityFrame> frames,
  }) {
    return ProjectContinuityBundle(
      id: ValueReaders.stringValue(document['id']).trim(),
      displayName: ValueReaders.stringValue(document['display_name']).trim(),
      coverage: _codecSupport.parseCoverage(
        ValueReaders.mapValue(document['coverage']),
      ),
      canonicalAssetReferences:
          ValueReaders.objectList(document['canonical_asset_references'])
              .map(
                (item) => _codecSupport.parseAssetReference(
                  ValueReaders.mapValue(item),
                ),
              )
              .where((item) => item.assetId.isNotEmpty)
              .toList(growable: false),
      scopes: scopes,
      scopeOverlays: scopeOverlays,
      mechanicProfiles: ValueReaders.objectList(document['mechanic_profiles'])
          .map(
            (item) =>
                _codecSupport.parseMechanicProfile(ValueReaders.mapValue(item)),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false),
      frames: frames,
      defaultMechanicProfileId: ValueReaders.stringValue(
        document['default_mechanic_profile_id'],
      ).trim(),
      defaultFrameId: ValueReaders.stringValue(
        document['default_frame_id'],
      ).trim(),
      notes: ValueReaders.stringValue(document['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['metadata']),
      ),
    );
  }

  JsonMap toDocument(ProjectContinuityBundle bundle) {
    return <String, Object?>{
      'schema_version': 1,
      'id': bundle.id,
      'display_name': bundle.displayName,
      'coverage': _codecSupport.coverageToDocument(bundle.coverage),
      'canonical_asset_references': bundle.canonicalAssetReferences
          .map(_codecSupport.assetReferenceToDocument)
          .cast<Object?>()
          .toList(growable: false),
      'mechanic_profiles': bundle.mechanicProfiles
          .map(_codecSupport.mechanicProfileToDocument)
          .cast<Object?>()
          .toList(growable: false),
      'scope_ids': bundle.scopes
          .map((item) => item.id)
          .cast<Object?>()
          .toList(growable: false),
      'frame_ids': bundle.frames
          .map((item) => item.id)
          .cast<Object?>()
          .toList(growable: false),
      'default_mechanic_profile_id': bundle.defaultMechanicProfileId,
      'default_frame_id': bundle.defaultFrameId,
      'notes': bundle.notes,
      'metadata': ValueReaders.deepCopyMap(bundle.metadata),
    };
  }

  List<String> scopeIds(JsonMap document) {
    return ValueReaders.stringList(document['scope_ids']);
  }

  List<String> frameIds(JsonMap document) {
    return ValueReaders.stringList(document['frame_ids']);
  }
}
