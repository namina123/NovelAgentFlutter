import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('RAG retrieval provider resolver', () {
    test('resolves supported placeholder providers and reports capability', () {
      final resolver = RagRetrievalProviderResolver();

      final localReport = resolver.capabilityReport(
        RagRetrievalProviderKinds.localPlaceholder,
      );
      final remoteReport = resolver.capabilityReport(
        RagRetrievalProviderKinds.remotePlaceholder,
      );

      expect(resolver.supportsProvider(RagRetrievalProviderKinds.localPlaceholder), isTrue);
      expect(resolver.supportsProvider(RagRetrievalProviderKinds.remotePlaceholder), isTrue);
      expect(localReport.isSupported, isTrue);
      expect(localReport.isAvailable, isTrue);
      expect(localReport.failureMessage, isEmpty);
      expect(
        localReport.capabilityProfile['supports_search'],
        isFalse,
      );
      expect(remoteReport.isSupported, isTrue);
      expect(remoteReport.isAvailable, isFalse);
      expect(remoteReport.failureMessage, isNotEmpty);
      expect(
        remoteReport.capabilityProfile['backend_mode'],
        'placeholder',
      );
    });

    test('returns unsupported report for unknown provider ids', () {
      final resolver = RagRetrievalProviderResolver();

      final report = resolver.capabilityReport('unknown-provider');

      expect(report.isSupported, isFalse);
      expect(report.isAvailable, isFalse);
      expect(report.failureMessage, 'unsupported retrieval provider');
      expect(report.capabilityProfile['supported'], isFalse);
    });

    test('host capability port exposes provider summaries', () {
      final port = DefaultRagRetrievalHostCapabilityPort();

      expect(
        port.supportsRetrievalProvider(
          RagRetrievalProviderKinds.localPlaceholder,
        ),
        isTrue,
      );
      expect(
        port.supportsRetrievalProvider('unknown-provider'),
        isFalse,
      );

      final profiles = port.retrievalProviderProfiles();
      expect(profiles, hasLength(2));
      expect(
        profiles.map((profile) => profile['provider_id']),
        containsAll(<String>[
          RagRetrievalProviderKinds.localPlaceholder,
          RagRetrievalProviderKinds.remotePlaceholder,
        ]),
      );
    });
  });
}
