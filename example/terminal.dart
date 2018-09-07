// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:io' show exit, stdin, stdout, ProcessSignal;

import 'package:dartis/dartis.dart' show Terminal;

/// Starts a Redis client in Terminal mode.
///
/// Type some Redis commands and press "Enter" to send them to the server.
///
/// The server replies will be displayed "as is", without any processing.
///
/// IMPORTANT: This example only works fine in Windows because the operating
/// system automatically appends a carriage return (ASCII 13) and line
/// feed (ASCII 10) to each line. In others enviroments could be necessary to
/// add that trailing characters manually to each line.
void main() async {
  final terminal = await Terminal.connect('redis://localhost:6379');

  // Ctrl+C handler.
  ProcessSignal.sigint.watch().listen((_) async {
    await terminal.disconnect();
    exit(0);
  });

  // Outputs the data received from the server.
  terminal.stream.listen(stdout.add, onDone: () => exit(0));

  // Send to the sever each typed command line.
  stdin.listen(terminal.run);
}
