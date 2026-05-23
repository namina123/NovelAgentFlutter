import '../../ports/provider_capability_port.dart';
import '../../ports/provider_catalog_port.dart';
import 'provider_custom_parameter_service.dart';
import 'provider_profile_description_service.dart';
import 'provider_profile_normalizer_service.dart';
import 'provider_protocol_service.dart';
import 'provider_runtime_profile_service.dart';
import 'provider_thinking_parameter_service.dart';

class ProviderProfileService {
  ProviderProfileService({
    required ProviderCatalogPort catalogPort,
    required ProviderCapabilityPort capabilityPort,
  }) : protocol = ProviderProtocolService(),
       thinking = ProviderThinkingParameterService(),
       customParameters = ProviderCustomParameterService(),
       normalizer = ProviderProfileNormalizerService(
         protocolService: ProviderProtocolService(),
         thinkingService: ProviderThinkingParameterService(),
         customParameterService: ProviderCustomParameterService(),
       ),
       runtimeProfiles = ProviderRuntimeProfileService(
         catalogPort: catalogPort,
         capabilityPort: capabilityPort,
         normalizerService: ProviderProfileNormalizerService(
           protocolService: ProviderProtocolService(),
           thinkingService: ProviderThinkingParameterService(),
           customParameterService: ProviderCustomParameterService(),
         ),
         protocolService: ProviderProtocolService(),
         thinkingService: ProviderThinkingParameterService(),
         customParameterService: ProviderCustomParameterService(),
       ),
       descriptions = ProviderProfileDescriptionService(
         runtimeProfileService: ProviderRuntimeProfileService(
           catalogPort: catalogPort,
           capabilityPort: capabilityPort,
           normalizerService: ProviderProfileNormalizerService(
             protocolService: ProviderProtocolService(),
             thinkingService: ProviderThinkingParameterService(),
             customParameterService: ProviderCustomParameterService(),
           ),
           protocolService: ProviderProtocolService(),
           thinkingService: ProviderThinkingParameterService(),
           customParameterService: ProviderCustomParameterService(),
         ),
         protocolService: ProviderProtocolService(),
       );

  final ProviderProtocolService protocol;
  final ProviderThinkingParameterService thinking;
  final ProviderCustomParameterService customParameters;
  final ProviderProfileNormalizerService normalizer;
  final ProviderRuntimeProfileService runtimeProfiles;
  final ProviderProfileDescriptionService descriptions;
}
