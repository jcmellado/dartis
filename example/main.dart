// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:dartis/dartis.dart' as redis;

void main() async {
  // Connects.
  final client = await redis.Client.connect('redis://localhost:6379');

  // Runs some commands.
  final commands = client.asCommands<String, String>();

  // SET key value
  await commands.set('key', 'value');

  // GET key
  final value = await commands.get('key');
  print(value);

  // Disconnects.
  await client.disconnect();
}
