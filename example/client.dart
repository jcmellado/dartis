// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:dartis/dartis.dart' show Client, ReplyMode;

/// A Redis client that runs some commands in normal mode, in the
/// pipelined mode, and in the fire and forget mode.
void main() async {
  // Connects.
  final client = await Client.connect('redis://localhost:6379');

  // Runs some commands.
  final commands = client.asCommands<String, String>();

  await commands.ping().then(print); // PONG
  await commands.ping().then(print); // PONG
  await commands.ping().then(print); // PONG

  // Pipeline.
  client.pipeline();

  commands
    // ignore: unawaited_futures
    ..ping()
    // ignore: unawaited_futures
    ..ping()
    // ignore: unawaited_futures
    ..ping();

  final futures = client.flush();

  await Future.wait(futures).then(print); // ['PONG', 'PONG', 'PONG']

  // Fire and forget.
  await commands.clientReply(ReplyMode.off);

  await commands.ping().then(print); // null
  await commands.ping().then(print); // null
  await commands.ping().then(print); // null

  await commands.clientReply(ReplyMode.on);

  // Disconnects.
  await client.disconnect();
}
