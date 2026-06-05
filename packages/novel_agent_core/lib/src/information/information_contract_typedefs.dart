import '../common/json_types.dart';

/// 共享信息对象使用的命名空间字符串。
///
/// 例如 writing / analysis / reference 等逻辑分区会在后续 session 引入。
typedef InformationNamespace = String;

/// 共享信息合同使用的 schema version 字符串。
typedef InformationSchemaVersion = String;

/// 共享信息对象的稳定记录标识。
typedef InformationRecordId = String;

/// 共享信息链路里 link 记录的稳定标识。
typedef InformationLinkId = String;

/// 共享信息链路里 event 记录的稳定标识。
typedef InformationEventId = String;

/// 共享信息对象使用的开放 payload。
///
/// 这里直接复用公共 `JsonMap`，避免为未来 card 再造一套 JSON 容器类型。
typedef InformationOpenPayload = JsonMap;

/// 共享信息对象的开放 metadata。
typedef InformationMetadata = JsonMap;
