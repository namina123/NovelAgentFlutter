import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project information namespace scaffolding', () {
    test('top-level package export exposes PIS-02 lightweight types', () {
      const InformationNamespace namespace = 'writing.main';
      const InformationSchemaVersion schemaVersion = 'pis-02-smoke';
      const InformationRecordId recordId = 'info-001';
      const InformationLinkId linkId = 'link-001';
      const InformationEventId eventId = 'event-001';

      final InformationOpenPayload payload = <String, Object?>{
        'title': 'shared fact',
        'metadata': <String, Object?>{'retained': true},
      };
      final encoded = const OpenJsonContractCodecService()
          .encodeWithUnknownFields(
            <String, Object?>{
              'record_id': recordId,
              'namespace': namespace,
              'schema_version': schemaVersion,
              'payload': payload,
            },
            metadata: <String, Object?>{
              'source': 'smoke_test',
              OpenJsonContractCodecService.unknownFieldsMetadataKey:
                  <String, Object?>{'future_flag': true},
            },
          );

      expect(namespace, 'writing.main');
      expect(schemaVersion, 'pis-02-smoke');
      expect(recordId, 'info-001');
      expect(linkId, 'link-001');
      expect(eventId, 'event-001');
      expect(
        InformationValidationCodes.missingInformationNamespace,
        'missing_information_namespace',
      );
      expect(ValueReaders.stringValue(encoded['record_id']), 'info-001');
      expect(ValueReaders.boolValue(encoded['future_flag']), isTrue);
      expect(
        ValueReaders.mapValue(
          encoded['metadata'],
        ).containsKey(OpenJsonContractCodecService.unknownFieldsMetadataKey),
        isFalse,
      );
    });
  });
}
