// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late HyperLogLogCommands<String, String> commands;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('HyperLogLogCommands', () {
    test('pfadd', () async {
      // Add one element.
      final key1 = uuid();
      expect(await commands.pfadd(key1, element: 'one'), equals(1));
      expect(await commands.pfadd(key1, element: 'one'), equals(0));

      // Add some elements.
      expect(await commands.pfadd(key1, elements: ['two', 'three']), equals(1));
      expect(await commands.pfadd(key1, elements: ['two', 'three']), equals(0));

      // Add none.
      final key2 = uuid();
      expect(await commands.pfadd(key2), equals(1));
    });

    test('pfcount', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.pfadd(key1, elements: ['one', 'two', 'three']);

      final key2 = uuid();
      await commands.pfadd(key2, elements: ['one', 'four']);

      // Count from one HyperLogLog.
      expect(await commands.pfcount(key: key1), equals(3));

      // Count from some HyperLogLogs.
      expect(await commands.pfcount(keys: [key1, key2]), equals(4));

      // Count from an empty or non existing HyperLogLog.
      final key3 = uuid();
      expect(await commands.pfcount(key: key3), equals(0));
    });

    test('pfmerge', () async {
      // Add some elements.
      final key1 = uuid();
      await commands.pfadd(key1, elements: ['one', 'two', 'three']);

      final key2 = uuid();
      await commands.pfadd(key2, elements: ['one', 'four']);

      // Merge one HyperLogLog.
      final key3 = uuid();
      await commands.pfmerge(key3, sourcekey: key1);
      expect(await commands.pfcount(key: key3), equals(3));

      // Merge some HyperLogLogs.
      final key4 = uuid();
      await commands.pfmerge(key4, sourcekeys: [key1, key2]);
      expect(await commands.pfcount(key: key4), equals(4));
    });
  });
}
