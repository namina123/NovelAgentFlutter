import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolSchemaBuilderService', () {
    test('exposes domain and low-level tools in one schema build call', () {
      final service = ToolSchemaBuilderService();

      final schemas = service.buildOpenAiSchemas(<String>[
        'write_project_file',
        'submit_chapter_delivery',
        'request_profile_clarification',
      ]);

      expect(schemas, hasLength(3));
      final names = schemas
          .map(
            (schema) => ValueReaders.stringValue(
              ValueReaders.mapValue(schema['function'])['name'],
            ),
          )
          .toList(growable: false);
      expect(names, <String>[
        'write_project_file',
        'submit_chapter_delivery',
        'request_profile_clarification',
      ]);

      final chapterSchema = schemas[1];
      final clarificationSchema = schemas[2];
      expect(
        ValueReaders.mapValue(
          ValueReaders.mapValue(chapterSchema['function'])['parameters'],
        ),
        isNotEmpty,
      );
      expect(
        ValueReaders.mapValue(
          ValueReaders.mapValue(clarificationSchema['function'])['parameters'],
        ),
        isNotEmpty,
      );
    });

    test(
      'keeps information tool schemas aligned with narrative domain catalog',
      () {
        final service = ToolSchemaBuilderService();
        final domainCatalog = NarrativeDomainToolCatalog();

        final builtSchemas = service.buildOpenAiSchemas(<String>[
          NarrativeDomainToolNames.requestExternalResearch,
          NarrativeDomainToolNames.proposeDesignElement,
        ]);
        final domainSchemas = domainCatalog.buildOpenAiSchemas(<String>[
          NarrativeDomainToolNames.requestExternalResearch,
          NarrativeDomainToolNames.proposeDesignElement,
        ]);

        expect(builtSchemas, hasLength(2));
        expect(builtSchemas, domainSchemas);
      },
    );
  });
}
