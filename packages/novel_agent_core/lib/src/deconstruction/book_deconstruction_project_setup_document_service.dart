import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'book_deconstruction_continuation_direction.dart';
import 'book_deconstruction_project_setup.dart';
import 'book_deconstruction_project_setup_resolver_service.dart';

class BookDeconstructionProjectSetupDocumentService {
  BookDeconstructionProjectSetupDocumentService({
    BookDeconstructionProjectSetupResolverService? resolverService,
  }) : _resolverService =
           resolverService ?? const BookDeconstructionProjectSetupResolverService();

  static const String relativePath =
      '.novel_agent/state/book_deconstruction/project_setup.json';

  final BookDeconstructionProjectSetupResolverService _resolverService;

  BookDeconstructionProjectSetup create({
    String followupRouteId =
        BookDeconstructionProjectSetupResolverService.continuationRouteId,
  }) {
    return _resolverService.resolve(followupRouteId: followupRouteId);
  }

  BookDeconstructionProjectSetup fromJson(JsonMap json) {
    final normalizedRouteId = _resolverService.normalizeRouteId(
      ValueReaders.stringValue(
        json['followup_route_id'],
        BookDeconstructionProjectSetupResolverService.continuationRouteId,
      ),
    );
    final resolved = _resolverService.resolve(followupRouteId: normalizedRouteId);
    return resolved.copyWith(
      preferredFollowupOptionId: ValueReaders.stringValue(
        json['preferred_followup_option_id'],
        resolved.preferredFollowupOptionId,
      ),
      preferredContinuationDirection: _directionOf(
        ValueReaders.stringValue(
          json['preferred_continuation_direction'],
          resolved.preferredContinuationDirection.name,
        ),
        fallback: resolved.preferredContinuationDirection,
      ),
      schemaVersion: ValueReaders.intValue(json['schema_version'], 1),
    );
  }

  JsonMap toJson(BookDeconstructionProjectSetup setup) {
    return <String, Object?>{
      'schema_version': setup.schemaVersion,
      'followup_route_id': _resolverService.normalizeRouteId(setup.followupRouteId),
      'preferred_followup_option_id': setup.preferredFollowupOptionId,
      'preferred_continuation_direction':
          setup.preferredContinuationDirection.name,
    };
  }

  String encode(BookDeconstructionProjectSetup setup) {
    return const JsonEncoder.withIndent('  ').convert(toJson(setup));
  }

  BookDeconstructionProjectSetup parse(String source) {
    final cleanSource = source.trim();
    if (cleanSource.isEmpty) {
      return create();
    }
    try {
      final decoded = jsonDecode(cleanSource);
      if (decoded is Map<Object?, Object?>) {
        return fromJson(Map<String, Object?>.from(decoded));
      }
      return create();
    } catch (_) {
      return create();
    }
  }

  BookDeconstructionContinuationDirection _directionOf(
    String rawValue, {
    required BookDeconstructionContinuationDirection fallback,
  }) {
    switch (rawValue.trim()) {
      case 'longTaskPreferred':
        return BookDeconstructionContinuationDirection.longTaskPreferred;
      case 'analysisFirst':
        return BookDeconstructionContinuationDirection.analysisFirst;
      case 'generalNovelPreferred':
        return BookDeconstructionContinuationDirection.generalNovelPreferred;
      default:
        return fallback;
    }
  }

}
