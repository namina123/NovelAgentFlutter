import 'package:flutter/widgets.dart';

import 'document_resource_render_request.dart';

abstract class DocumentResourceRenderer {
  String get id;

  Widget build(BuildContext context, DocumentResourceRenderRequest request);
}
