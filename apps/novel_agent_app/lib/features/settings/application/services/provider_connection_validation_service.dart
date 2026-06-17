export 'package:novel_agent_core/novel_agent_core.dart'
    show ProviderConnectionValidationResult;

import 'package:novel_agent_core/novel_agent_core.dart' as core;

class ProviderConnectionValidationService
    extends core.ProviderConnectionValidationService {
  ProviderConnectionValidationService({
    super.connectionContractService,
    super.runtimeRouteContract,
  });
}
