import 'package:novel_agent_core/novel_agent_core.dart';

import 'reference_extraction_identity_service.dart';
import 'reference_extraction_liveness_bridge.dart';
import 'reference_extraction_mount_coordinator.dart';
import 'reference_extraction_publication_service.dart';

class ReferenceExtractionRunCoordinator {
  ReferenceExtractionRunCoordinator({
    required ProjectWorkspacePort workspacePort,
    ReferenceExtractionIdentityService? identityService,
    ReferenceExtractionPublicationService? publicationService,
    ReferenceExtractionMountCoordinator? mountCoordinator,
    ReferenceExtractionLivenessBridge? livenessBridge,
  }) : identityService = identityService ?? const ReferenceExtractionIdentityService(),
       publicationService =
           publicationService ?? const ReferenceExtractionPublicationService(),
       mountCoordinator =
           mountCoordinator ??
           ReferenceExtractionMountCoordinator(workspacePort: workspacePort),
       livenessBridge = livenessBridge;

  final ReferenceExtractionIdentityService identityService;
  final ReferenceExtractionPublicationService publicationService;
  final ReferenceExtractionMountCoordinator mountCoordinator;
  final ReferenceExtractionLivenessBridge? livenessBridge;
}
