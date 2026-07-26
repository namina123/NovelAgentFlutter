import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayFactoryResolver', () {
    test(
      'resolves provider protocol to the matching gateway implementation',
      () {
        final tempRoot = Directory.systemTemp.createTempSync(
          'novel_agent_gateway_factory',
        );
        addTearDown(() {
          if (tempRoot.existsSync()) {
            tempRoot.deleteSync(recursive: true);
          }
        });

        final bundle = AdapterBundle.standard(
          workingDirectoryPath: tempRoot.path,
          settingsRootPath: '${tempRoot.path}/settings',
          defaultProjectRootPath: '${tempRoot.path}/project',
        );

        final openAiGateway = bundle.createGateway(
          const ProviderEndpointSettings(
            id: 'openai',
            title: 'OpenAI',
            protocol: ProviderProfileConstants.kindOpenAiCompatible,
            baseUrl: 'https://example.com/v1',
            apiKey: 'test-key',
            modelId: 'gpt-test',
            description: 'openai provider',
          ),
        );
        final anthropicGateway = bundle.createGateway(
          const ProviderEndpointSettings(
            id: 'anthropic',
            title: 'Anthropic',
            protocol: ProviderProfileConstants.kindAnthropicCompatible,
            baseUrl: 'https://example.com/v1',
            apiKey: 'test-key',
            modelId: 'claude-test',
            description: 'anthropic provider',
          ),
        );
        final geminiGateway = bundle.createGateway(
          const ProviderEndpointSettings(
            id: 'google',
            title: 'Google',
            protocol: 'gemini_native',
            baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
            apiKey: 'test-key',
            modelId: 'gemini-3.5',
            description: 'gemini provider',
          ),
        );

        expect(openAiGateway, isA<OpenAiLlmGateway>());
        expect(anthropicGateway, isA<AnthropicLlmGateway>());
        expect(geminiGateway, isA<GeminiNativeLlmGateway>());
      },
    );

    test(
      'supports Gemini OpenAI-compatible and native as distinct gateways',
      () {
        final tempRoot = Directory.systemTemp.createTempSync(
          'novel_agent_gateway_factory_google',
        );
        addTearDown(() {
          if (tempRoot.existsSync()) {
            tempRoot.deleteSync(recursive: true);
          }
        });

        final bundle = AdapterBundle.standard(
          workingDirectoryPath: tempRoot.path,
          settingsRootPath: '${tempRoot.path}/settings',
          defaultProjectRootPath: '${tempRoot.path}/project',
        );

        final openAiCompatibleGateway = bundle.createGateway(
          const ProviderEndpointSettings(
            id: 'google-openai',
            title: 'Google OpenAI',
            protocol: ProviderProfileConstants.kindOpenAiCompatible,
            baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
            apiKey: 'test-key',
            modelId: 'gemini-3.5',
            description: 'google openai compatible',
          ),
        );
        final nativeGateway = bundle.createGateway(
          const ProviderEndpointSettings(
            id: 'google-native',
            title: 'Google Native',
            protocol: 'gemini_native',
            baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
            apiKey: 'test-key',
            modelId: 'gemini-3.5',
            description: 'google native',
          ),
        );

        expect(openAiCompatibleGateway, isA<OpenAiLlmGateway>());
        expect(nativeGateway, isA<GeminiNativeLlmGateway>());
        expect(
          openAiCompatibleGateway.runtimeType,
          isNot(nativeGateway.runtimeType),
        );
      },
    );
  });
}
