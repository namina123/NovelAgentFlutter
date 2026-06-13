import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskStopDiagnosisProjection {
  const LongTaskStopDiagnosisProjection({
    this.present = false,
    this.code = '',
    this.category = '',
    this.label = '',
    this.summary = '',
    this.detail = '',
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String code;
  final String category;
  final String label;
  final String summary;
  final String detail;
  final JsonMap metadata;

  factory LongTaskStopDiagnosisProjection.fromJson(JsonMap json) {
    final code = ValueReaders.stringValue(json['code']).trim();
    final category = ValueReaders.stringValue(json['category']).trim();
    final label = ValueReaders.stringValue(json['label']).trim();
    return LongTaskStopDiagnosisProjection(
      present: ValueReaders.boolValue(
        json['present'],
        code.isNotEmpty || category.isNotEmpty || label.isNotEmpty,
      ),
      code: code,
      category: category,
      label: label,
      summary: ValueReaders.stringValue(json['summary']).trim(),
      detail: ValueReaders.stringValue(json['detail']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'present': present,
      'code': code,
      'category': category,
      'label': label,
      'summary': summary,
      'detail': detail,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
