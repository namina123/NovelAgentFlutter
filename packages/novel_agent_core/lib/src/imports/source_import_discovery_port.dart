import 'source_import_discovery_result.dart';
import 'source_import_request.dart';

abstract interface class SourceImportDiscoveryPort {
  Future<SourceImportDiscoveryResult> discover(SourceImportRequest request);
}
