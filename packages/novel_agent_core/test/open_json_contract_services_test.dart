import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Open JSON contract services', () {
    test('codec preserves unknown top-level fields through metadata bag', () {
      const codec = OpenJsonContractCodecService();
      final raw = <String, Object?>{
        'record_id': 'record-001',
        'schema_version': 'ons-12',
        'metadata': <String, Object?>{'label': 'kept'},
        'future_extension': <String, Object?>{
          'level': 3,
          'flags': <Object?>['alpha', 'beta'],
        },
      };

      final metadata = codec.readMetadataWithUnknownFields(
        raw,
        knownFields: const <String>{'record_id', 'schema_version', 'metadata'},
      );
      final encoded = codec.encodeWithUnknownFields(<String, Object?>{
        'record_id': 'record-001',
        'schema_version': codec.readSchemaVersion(raw),
      }, metadata: metadata);

      expect((encoded['metadata'] as Map<String, Object?>)['label'], 'kept');
      expect(
        (encoded['metadata'] as Map<String, Object?>).containsKey(
          OpenJsonContractCodecService.unknownFieldsMetadataKey,
        ),
        isFalse,
      );
      expect(
        (((encoded['future_extension'] as Map<String, Object?>)['flags'])
            as List<Object?>),
        containsAll(<Object?>['alpha', 'beta']),
      );
    });

    test(
      'validator reports required-field and confidence structure errors',
      () {
        const validator = OpenJsonStructureValidatorService();
        final codes = <String>[
          ...validator.requireNonBlankString('', 'missing_id'),
          ...validator.requireNonEmptyCollection(
            const <Object?>[],
            'missing_items',
          ),
          ...validator.validateConfidence(1.2, 'invalid_confidence'),
          ...validator.validateNonNegativeInt(-1, 'invalid_budget'),
        ];

        expect(
          codes,
          containsAll(<String>[
            'missing_id',
            'missing_items',
            'invalid_confidence',
            'invalid_budget',
          ]),
        );
      },
    );
  });
}
