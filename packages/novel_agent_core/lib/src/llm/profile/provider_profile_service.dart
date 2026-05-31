import '../../ports/provider_capability_port.dart';
import '../../ports/provider_catalog_port.dart';
import 'provider_custom_parameter_service.dart';
import 'custom_model_reasoning_override_service.dart';
import 'provider_model_metadata_service.dart';
import 'provider_profile_description_service.dart';
import 'provider_profile_normalizer_service.dart';
import 'provider_protocol_service.dart';
import 'provider_runtime_profile_service.dart';
import 'provider_thinking_parameter_service.dart';
import '../catalog/legacy_provider_catalog_bridge_service.dart';
import '../catalog/provider_catalog_service.dart';
import '../catalog/provider_interface_template_service.dart';
import '../catalog/writing_model_offering_catalog_service.dart';
import '../catalog/writing_model_reasoning_profile_service.dart';

class ProviderProfileService {
  ProviderProfileService({
    required ProviderCatalogPort catalogPort,
    required ProviderCapabilityPort capabilityPort,
  }) : protocol = ProviderProtocolService(),
       thinking = ProviderThinkingParameterService(),
       customParameters = ProviderCustomParameterService(),
       offeringCatalogs = WritingModelOfferingCatalogService(),
       reasoningProfiles = WritingModelReasoningProfileService(),
       customReasoningOverrides = CustomModelReasoningOverrideService(),
       normalizer = ProviderProfileNormalizerService(
         protocolService: ProviderProtocolService(),
         thinkingService: ProviderThinkingParameterService(),
         customParameterService: ProviderCustomParameterService(),
       ),
       metadata = ProviderModelMetadataService(
         thinkingService: ProviderThinkingParameterService(),
         customParameterService: ProviderCustomParameterService(),
         writingReasoningProfileService: WritingModelReasoningProfileService(),
         customReasoningOverrideService: CustomModelReasoningOverrideService(),
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
         providerInterfaceTemplateService:
             ProviderInterfaceTemplateService.seeded(),
         legacyProviderCatalogBridgeService: _legacyBridgeForPort(catalogPort),
         writingReasoningProfileService: WritingModelReasoningProfileService(),
         customReasoningOverrideService: CustomModelReasoningOverrideService(),
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
           providerInterfaceTemplateService:
               ProviderInterfaceTemplateService.seeded(),
           legacyProviderCatalogBridgeService: _legacyBridgeForPort(
             catalogPort,
           ),
           writingModelOfferingCatalogService:
               WritingModelOfferingCatalogService(),
           writingReasoningProfileService:
               WritingModelReasoningProfileService(),
           customReasoningOverrideService:
               CustomModelReasoningOverrideService(),
         ),
         protocolService: ProviderProtocolService(),
       );

  final ProviderProtocolService protocol;
  final ProviderThinkingParameterService thinking;
  final ProviderCustomParameterService customParameters;
  final WritingModelOfferingCatalogService offeringCatalogs;
  final WritingModelReasoningProfileService reasoningProfiles;
  final CustomModelReasoningOverrideService customReasoningOverrides;
  final ProviderModelMetadataService metadata;
  final ProviderProfileNormalizerService normalizer;
  final ProviderRuntimeProfileService runtimeProfiles;
  final ProviderProfileDescriptionService descriptions;

  static LegacyProviderCatalogBridgeService? _legacyBridgeForPort(
    ProviderCatalogPort catalogPort,
  ) {
    if (catalogPort is ProviderCatalogService) {
      return LegacyProviderCatalogBridgeService(catalogService: catalogPort);
    }
    return null;
  }
}
