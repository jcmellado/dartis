// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:io' show exit, ProcessSignal;

import 'package:dartis/dartis.dart' as redis show PubSub;

/// Starts a client in Pub/Sub mode.
///
/// In this mode the client receives messages from its subscribed channels.
///
/// Open another console, start there a Redis client and PUBLISH some
/// messages in any channel matching the pattern "news.*". The messages
/// will be displayed here.
void main() async {
  final broker =
      await redis.PubSub.connect<String, String>('redis://localhost:6379');

  // Ctrl+C handler.
  ProcessSignal.sigint.watch().listen((_) async {
    await broker.disconnect();
    exit(0);
  });

  // Outputs the data received from the server.
  broker.stream.listen(print, onError: print, onDone: () => exit(0));

  // Subscribes the client to some channels.
  broker.psubscribe(pattern: 'news.*');
}
