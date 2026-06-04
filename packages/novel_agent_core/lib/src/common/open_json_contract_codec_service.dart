import 'json_types.dart';
import 'value_readers.dart';

class OpenJsonContractCodecService {
  const OpenJsonContractCodecService();

  static const String unknownFieldsMetadataKey = '_unknown_fields';

  String readSchemaVersion(JsonMap json) {
    return ValueReaders.stringValue(json['schema_version']).trim();
  }

  JsonMap readOpenMap(Object? value) {
    return ValueReaders.deepCopyMap(ValueReaders.mapValue(value));
  }

  JsonMap readMetadataWithUnknownFields(
    JsonMap json, {
    required Set<String> knownFields,
  }) {
    final metadata = readOpenMap(json['metadata']);
    final unknownFields = captureUnknownFields(json, knownFields: knownFields);
    if (unknownFields.isNotEmpty) {
      metadata[unknownFieldsMetadataKey] = unknownFields;
    }
    return metadata;
  }

  JsonMap captureUnknownFields(
    JsonMap json, {
    required Set<String> knownFields,
  }) {
    final result = <String, Object?>{};
    for (final entry in json.entries) {
      if (!knownFields.contains(entry.key)) {
        result[entry.key] = entry.value;
      }
    }
    return ValueReaders.deepCopyMap(result);
  }

  JsonMap encodeWithUnknownFields(
    JsonMap fields, {
    JsonMap metadata = const <String, Object?>{},
  }) {
    final result = ValueReaders.deepCopyMap(fields);
    final cleanMetadata = metadataWithoutUnknownFields(metadata);
    result['metadata'] = cleanMetadata;
    final unknownFields = unknownFieldsFromMetadata(metadata);
    for (final entry in unknownFields.entries) {
      result.putIfAbsent(entry.key, () => entry.value);
    }
    return result;
  }

  JsonMap metadataWithoutUnknownFields(JsonMap metadata) {
    final clean = readOpenMap(metadata)..remove(unknownFieldsMetadataKey);
    return clean;
  }

  JsonMap unknownFieldsFromMetadata(JsonMap metadata) {
    return readOpenMap(metadata[unknownFieldsMetadataKey]);
  }
}
