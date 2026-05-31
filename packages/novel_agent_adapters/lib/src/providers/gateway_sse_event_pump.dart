import 'dart:convert';
import 'dart:io';

import 'openai_gateway_cancellation_scope.dart';
import 'sse_event_text_parser.dart';

class GatewaySsePumpResult {
  const GatewaySsePumpResult({
    required this.rawBody,
    required this.sawStreamEvent,
    required this.reachedTerminalEvent,
  });

  final String rawBody;
  final bool sawStreamEvent;
  final bool reachedTerminalEvent;
}

class GatewaySseEventPump {
  const GatewaySseEventPump({this.ignoreEventFields = false});

  final bool ignoreEventFields;

  Future<GatewaySsePumpResult> pumpResponse(
    HttpClientResponse response, {
    required OpenAiGatewayCancellationScope cancellationScope,
    required bool Function(String eventData) onEventData,
  }) async {
    final rawBody = StringBuffer();
    final parser = SseEventTextParser(ignoreEventFields: ignoreEventFields);
    var sawStreamEvent = false;
    var reachedTerminalEvent = false;
    try {
      await for (final chunk in response.transform(utf8.decoder)) {
        if (cancellationScope.isCancellationRequested) {
          break;
        }
        rawBody.write(chunk);
        final result = _consumeEvents(parser.addChunk(chunk), onEventData);
        sawStreamEvent = sawStreamEvent || result.sawStreamEvent;
        reachedTerminalEvent =
            reachedTerminalEvent || result.reachedTerminalEvent;
      }
    } catch (error) {
      if (!cancellationScope.isCancellationRequested) {
        rethrow;
      }
    }
    final tail = _consumeEvents(parser.close(), onEventData);
    sawStreamEvent = sawStreamEvent || tail.sawStreamEvent;
    reachedTerminalEvent =
        reachedTerminalEvent || tail.reachedTerminalEvent;
    return GatewaySsePumpResult(
      rawBody: rawBody.toString(),
      sawStreamEvent: sawStreamEvent,
      reachedTerminalEvent: reachedTerminalEvent,
    );
  }

  GatewaySsePumpResult pumpBody(
    String body, {
    required bool Function(String eventData) onEventData,
  }) {
    final parser = SseEventTextParser(ignoreEventFields: ignoreEventFields);
    final first = _consumeEvents(parser.addChunk(body), onEventData);
    final tail = _consumeEvents(parser.close(), onEventData);
    return GatewaySsePumpResult(
      rawBody: body,
      sawStreamEvent: first.sawStreamEvent || tail.sawStreamEvent,
      reachedTerminalEvent:
          first.reachedTerminalEvent || tail.reachedTerminalEvent,
    );
  }

  GatewaySsePumpResult _consumeEvents(
    Iterable<String> events,
    bool Function(String eventData) onEventData,
  ) {
    var sawStreamEvent = false;
    var reachedTerminalEvent = false;
    for (final eventData in events) {
      sawStreamEvent = true;
      if (onEventData(eventData)) {
        reachedTerminalEvent = true;
      }
    }
    return GatewaySsePumpResult(
      rawBody: '',
      sawStreamEvent: sawStreamEvent,
      reachedTerminalEvent: reachedTerminalEvent,
    );
  }
}
