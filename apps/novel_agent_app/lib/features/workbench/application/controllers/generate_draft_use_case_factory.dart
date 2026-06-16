import 'package:novel_agent_core/novel_agent_core.dart';

typedef GenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );

typedef HostAwareGenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings, {
      HostInformationPermissionContext? hostInformationPermissionContext,
      HostToolPermissionContext? hostToolPermissionContext,
    });
