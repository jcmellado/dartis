// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:io' show exit, stdout, ProcessSignal;

import 'package:dartis/dartis.dart' as redis show Monitor;

/// Starts a Redis client in Monitor mode.
///
/// In this mode the client receives all the commands processed by the
/// Redis server.
///
/// Open another console, start there a Redis client and type some commands.
/// The typed commands there will be displayed here.
void main() async {
  final monitor = await redis.Monitor.connect('redis://localhost:6379');

  // Ctrl+C handler.
  ProcessSignal.sigint.watch().listen((_) async {
    await monitor.disconnect();
    exit(0);
  });

  // Outputs the data received from the server.
  monitor.stream.listen(stdout.add, onDone: () => exit(0));

  // Starts the monitor mode.
  monitor.start();
}
