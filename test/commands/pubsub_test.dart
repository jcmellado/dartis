// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late PubSubCommands<String?, String> commands;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('PubSubCommands', () {
    test('publish', () async {
      final key = uuid();
      expect(await commands.publish(key, 'message'), isZero);
    });

    test('pubsubChannels', () async {
      // Get all.
      await commands.pubsubChannels();

      // Get matching the given pattern.
      final pattern = uuid();
      expect(await commands.pubsubChannels(pattern: pattern), isEmpty);
    });

    test('pubsubNumsub', () async {
      // Get all.
      expect(await commands.pubsubNumsub(), isEmpty);

      // Get some channels.
      final key1 = uuid();
      final key2 = uuid();
      final results = await commands.pubsubNumsub(channels: [key1, key2]);
      expect(results, hasLength(2));
      expect(results[0].channel, equals(key1));
      expect(results[0].subscriberCount, equals(0));
      expect(results[1].channel, equals(key2));
      expect(results[1].subscriberCount, equals(0));
    });

    test('pubsubNumpat', () async {
      expect(await commands.pubsubNumpat(), greaterThanOrEqualTo(0));
    });

    group('support', () {
      group('PubsubResult', () {
        test('toString', () {
          const value = PubsubResult<String?>(null, null);
          expect(value.toString(), startsWith('PubsubResult<String?>:'));
        });
      });
    });
  });
}
