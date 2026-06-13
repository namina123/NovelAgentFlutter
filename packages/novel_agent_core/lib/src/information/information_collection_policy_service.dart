import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/value_readers.dart';
import 'information_collection_constants.dart';
import 'information_collection_request.dart';
import 'information_policy_constants.dart';

class InformationCollectionPolicyService {
  const InformationCollectionPolicyService();

  InformationCollectionRequest normalize(InformationCollectionRequest request) {
    final informationDomain = _normalizeOpenString(
      request.informationDomain,
      InformationDomains.general,
    );
    final requestedDepth = _normalizeOpenString(
      request.requestedDepth,
      InformationResearchDepths.standard,
    );
    final rawCollectionMode = _normalizeCollectionMode(request.collectionMode);
    final collectionMode = _normalizeExecutableCollectionMode(
      request,
      rawCollectionMode,
    );
    final requiresRigorousSources =
        request.sourceRequirements.requiresRigorousSources ||
        _requiresRigorousSources(informationDomain);
    final sourceRequirements = request.sourceRequirements.copyWith(
      requiresRigorousSources: requiresRigorousSources,
      minSourceCount: _sourceCount(
        request.sourceRequirements.minSourceCount,
        requiresRigorousSources: requiresRigorousSources,
      ),
      preferredLanguages:
          request.sourceRequirements.preferredLanguages.isNotEmpty
          ? request.sourceRequirements.preferredLanguages
          : const <String>['zh-CN', 'zh', 'en'],
      networkRegionHint: _normalizeOpenString(
        request.sourceRequirements.networkRegionHint,
        InformationNetworkRegionHints.mainlandChinaPossible,
      ),
      allowLowConfidenceNotes: true,
    );
    final extractionPolicy = request.extractionPolicy.copyWith(
      collectBroadly: true,
      maxCandidateCount: _candidateCount(
        request.extractionPolicy.maxCandidateCount,
        requestedDepth: requestedDepth,
      ),
      maxFetchCount: _fetchCount(
        request.extractionPolicy.maxFetchCount,
        requestedDepth: requestedDepth,
      ),
      preserveRejectedCandidates: true,
      preserveUncertainFindings: true,
    );
    return request.copyWith(
      requestedDepth: requestedDepth,
      collectionMode: collectionMode,
      informationDomain: informationDomain,
      sourceRequirements: sourceRequirements,
      extractionPolicy: extractionPolicy,
      metadata: _normalizedMetadata(
        request.metadata,
        rawCollectionMode: rawCollectionMode,
        collectionMode: collectionMode,
      ),
    );
  }

  bool _requiresRigorousSources(String informationDomain) {
    final normalized = informationDomain.trim().toLowerCase();
    return normalized == InformationDomains.objective ||
        normalized == InformationDomains.history ||
        normalized == InformationDomains.science ||
        normalized == InformationDomains.technology ||
        normalized == InformationDomains.legal ||
        normalized == InformationDomains.medical ||
        normalized.contains('factual') ||
        normalized.contains('objective') ||
        normalized.contains('history') ||
        normalized.contains('science') ||
        normalized.contains('technology') ||
        normalized.contains('technical') ||
        normalized.contains('legal') ||
        normalized.contains('law') ||
        normalized.contains('medical') ||
        normalized.contains('medicine') ||
        normalized.contains('policy') ||
        normalized.contains('governance') ||
        normalized.contains('institution');
  }

  String _normalizeCollectionMode(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == InformationCollectionModes.import ||
        normalized == InformationCollectionModes.hybrid ||
        normalized == InformationCollectionModes.network) {
      return normalized;
    }
    return InformationCollectionModes.network;
  }

  String _normalizeExecutableCollectionMode(
    InformationCollectionRequest request,
    String normalizedMode,
  ) {
    if ((normalizedMode == InformationCollectionModes.import ||
            normalizedMode == InformationCollectionModes.hybrid) &&
        !_hasImportSource(request)) {
      return InformationCollectionModes.network;
    }
    return normalizedMode;
  }

  bool _hasImportSource(InformationCollectionRequest request) {
    return _readMetadataString(
          request.metadata,
          'import_relative_path',
        ).isNotEmpty ||
        _readMetadataString(request.metadata, 'source_text').isNotEmpty;
  }

  String _readMetadataString(JsonMap metadata, String key) {
    final direct = ValueReaders.stringValue(metadata[key]).trim();
    if (direct.isNotEmpty) {
      return direct;
    }
    final unknownFields = ValueReaders.mapValue(
      metadata[OpenJsonContractCodecService.unknownFieldsMetadataKey],
    );
    return ValueReaders.stringValue(unknownFields[key]).trim();
  }

  JsonMap _normalizedMetadata(
    JsonMap metadata, {
    required String rawCollectionMode,
    required String collectionMode,
  }) {
    final result = ValueReaders.deepCopyMap(metadata);
    if (rawCollectionMode != collectionMode) {
      result['raw_collection_mode'] = rawCollectionMode;
      result['normalized_collection_mode'] = collectionMode;
      result['collection_mode_normalization_reason'] =
          'missing_import_source_for_import_collection';
    }
    return result;
  }

  String _normalizeOpenString(String value, String fallback) {
    final normalized = value.trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  int _sourceCount(int rawValue, {required bool requiresRigorousSources}) {
    if (rawValue > 0) {
      return rawValue.clamp(1, 12);
    }
    return requiresRigorousSources ? 2 : 1;
  }

  int _candidateCount(int rawValue, {required String requestedDepth}) {
    if (rawValue > 0) {
      return rawValue.clamp(3, 24);
    }
    switch (requestedDepth) {
      case InformationResearchDepths.quick:
        return 6;
      case InformationResearchDepths.deep:
        return 16;
      case InformationResearchDepths.standard:
      default:
        return 10;
    }
  }

  int _fetchCount(int rawValue, {required String requestedDepth}) {
    if (rawValue > 0) {
      return rawValue.clamp(1, 8);
    }
    switch (requestedDepth) {
      case InformationResearchDepths.quick:
        return 2;
      case InformationResearchDepths.deep:
        return 6;
      case InformationResearchDepths.standard:
      default:
        return 4;
    }
  }
}
