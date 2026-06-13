import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolCapabilityFamilyCatalogService', () {
    const service = ToolCapabilityFamilyCatalogService();

    test('declares stable builtin capability families with known tool ids', () {
      final profiles = service.builtinProfiles();
      final extraction = service.profileFor(
        ToolCapabilityFamilyCatalogService.referenceExtraction,
      );
      final research = service.profileFor(
        ToolCapabilityFamilyCatalogService.research,
      );
      final mounted = service.profileFor(
        ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
      );

      expect(profiles, hasLength(7));
      expect(
        profiles.map((profile) => profile.familyId),
        containsAll(const <String>[
          ToolCapabilityFamilyCatalogService.writing,
          ToolCapabilityFamilyCatalogService.review,
          ToolCapabilityFamilyCatalogService.research,
          ToolCapabilityFamilyCatalogService.referenceExtraction,
          ToolCapabilityFamilyCatalogService.referenceMountCommit,
          ToolCapabilityFamilyCatalogService.continuousTaskControl,
        ]),
      );
      expect(extraction, isNotNull);
      expect(research, isNotNull);
      expect(mounted, isNotNull);
      expect(
        ValueReaders.boolValue(extraction!.metadata['heavy_extraction']),
        isTrue,
      );
      expect(
        research!.toolIds,
        contains(NarrativeDomainToolNames.requestExternalResearch),
      );
      expect(mounted!.toolIds, isEmpty);
      expect(
        service.unknownToolIds(const <String>[
          ToolCapabilityFamilyCatalogService.writing,
          ToolCapabilityFamilyCatalogService.review,
          ToolCapabilityFamilyCatalogService.research,
          ToolCapabilityFamilyCatalogService.referenceExtraction,
          ToolCapabilityFamilyCatalogService.continuousTaskControl,
        ]),
        isEmpty,
      );
    });

    test('round-trips capability family profile as json contract', () {
      final original = service.profileFor(
        ToolCapabilityFamilyCatalogService.referenceExtraction,
      )!;

      final restored = ToolCapabilityFamilyProfile.fromJson(original.toJson());

      expect(restored.validateBasics(), isEmpty);
      expect(restored.familyId, original.familyId);
      expect(restored.toolIds, orderedEquals(original.toolIds));
      expect(
        ValueReaders.boolValue(restored.metadata['heavy_extraction']),
        isTrue,
      );
    });
  });
}
