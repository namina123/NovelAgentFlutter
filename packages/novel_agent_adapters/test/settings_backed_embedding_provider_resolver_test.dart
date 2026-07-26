import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

// 中文注释: 覆盖 settings→embedding provider 解析：未配置 embedding 模型 / 缺凭据时返回 null
// （检索与入库据此诚实降级到词法），配置齐全时返回 remote provider。不触网（provider 内部不发请求）。
void main() {
  group('SettingsBackedEmbeddingProviderResolver', () {
    const resolver = SettingsBackedEmbeddingProviderResolver();

    AppSettings settingsWith({
      String defaultProviderId = 'prov-1',
      List<ProviderEndpointSettings> providers =
          const <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'prov-1',
              title: '测试接口',
              protocol: 'openai_compatible',
              baseUrl: 'https://embed.example.com/v1',
              apiKey: 'sk-test',
              modelId: 'chat-model',
              description: '',
              isDefault: true,
            ),
          ],
      Object? embeddingModelId,
    }) {
      return AppSettings(
        defaultProviderId: defaultProviderId,
        defaultAgentId: '',
        defaultModelId: 'chat-model',
        defaultProjectPath: '',
        autoSaveDrafts: false,
        providers: providers,
        extraSettings: embeddingModelId == null
            ? const <String, Object?>{}
            : <String, Object?>{'embedding_model_id': embeddingModelId},
      );
    }

    test('returns null when no embedding model id is configured', () {
      final provider = resolver.resolve(settingsWith(embeddingModelId: null));
      expect(provider, isNull);
    });

    test('returns null when no provider is configured', () {
      final provider = resolver.resolve(
        settingsWith(
          providers: const <ProviderEndpointSettings>[],
          embeddingModelId: 'text-embedding-3-small',
        ),
      );
      expect(provider, isNull);
    });

    test('returns null when the default provider lacks credentials', () {
      final provider = resolver.resolve(
        AppSettings(
          defaultProviderId: 'prov-1',
          defaultAgentId: '',
          defaultModelId: 'chat-model',
          defaultProjectPath: '',
          autoSaveDrafts: false,
          providers: const <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'prov-1',
              title: '本地无 key',
              protocol: 'openai_compatible',
              baseUrl: 'https://embed.example.com/v1',
              apiKey: '',
              modelId: 'chat-model',
              description: '',
            ),
          ],
          extraSettings: const <String, Object?>{
            'embedding_model_id': 'text-embedding-3-small',
          },
        ),
      );
      expect(provider, isNull);
    });

    test(
      'builds a remote embedding provider from the default provider + embedding model id',
      () {
        final provider = resolver.resolve(
          settingsWith(embeddingModelId: 'text-embedding-3-small'),
        );
        expect(provider, isNotNull);
        expect(
          provider!.providerKind,
          RagRetrievalProviderKinds.remoteOpenAiCompatible,
        );
        expect(provider.isRemote, isTrue);
        final capabilities = provider.describeCapabilities();
        expect(
          ValueReaders.stringValue(capabilities['model_id']),
          'text-embedding-3-small',
        );
        expect(
          ValueReaders.stringValue(capabilities['base_url']),
          'https://embed.example.com/v1',
        );
      },
    );

    test(
      'falls back to the first provider when defaultProviderId is absent',
      () {
        final provider = resolver.resolve(
          AppSettings(
            defaultProviderId: '',
            defaultAgentId: '',
            defaultModelId: '',
            defaultProjectPath: '',
            autoSaveDrafts: false,
            providers: const <ProviderEndpointSettings>[
              ProviderEndpointSettings(
                id: 'only-prov',
                title: '唯一接口',
                protocol: 'openai_compatible',
                baseUrl: 'https://embed.example.com/v1',
                apiKey: 'sk-only',
                modelId: 'chat-model',
                description: '',
              ),
            ],
            extraSettings: const <String, Object?>{
              'embedding_model_id': 'bge-large-zh',
            },
          ),
        );
        expect(provider, isNotNull);
        expect(provider!.providerId, 'only-prov');
      },
    );
  });
}
