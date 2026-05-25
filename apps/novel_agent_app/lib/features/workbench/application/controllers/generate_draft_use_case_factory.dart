import 'package:novel_agent_core/novel_agent_core.dart';

typedef GenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );
