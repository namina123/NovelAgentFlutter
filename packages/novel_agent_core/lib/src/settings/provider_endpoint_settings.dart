class ProviderEndpointSettings {
  const ProviderEndpointSettings({
    required this.id,
    required this.title,
    required this.protocol,
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
    required this.description,
    this.isDefault = false,
  });

  final String id;
  final String title;
  final String protocol;
  final String baseUrl;
  final String apiKey;
  final String modelId;
  final String description;
  final bool isDefault;

  ProviderEndpointSettings copyWith({
    String? id,
    String? title,
    String? protocol,
    String? baseUrl,
    String? apiKey,
    String? modelId,
    String? description,
    bool? isDefault,
  }) {
    // 中文注释: provider 设置通过 copyWith 更新，避免界面层手写整条记录重组。
    return ProviderEndpointSettings(
      id: id ?? this.id,
      title: title ?? this.title,
      protocol: protocol ?? this.protocol,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      modelId: modelId ?? this.modelId,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
