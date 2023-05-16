// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late PubSub<String, String> pubsub;
  late Client client;
  late Commands<String, String> commands;

  setUp(() async {
    pubsub = await PubSub.connect<String, String>('redis://localhost:6379');
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await pubsub.disconnect();
    await client.disconnect();
  });

  group('PubSub', () {
    test('subscribe', () async {
      final channel = uuid();
      final message = uuid();

      // Subscribe.
      pubsub.subscribe(channel: channel);

      expect(
          pubsub.stream,
          emitsInOrder(<Object>[
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.subscribe));
              expect(event.channel, equals(channel));
              expect(event.channelCount, equals(1));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (MessageEvent<String, String> event) {
              expect(event.channel, equals(channel));
              expect(event.message, equals(message));
              expect(event.pattern, isNull);
              return true;
            },
          ]));

      // Publish a message.
      await commands.publish(channel, message);
    });

    test('unsubscribe', () async {
      final channel1 = uuid();
      final channel2 = uuid();
      final channel3 = uuid();

      pubsub
        // Subscribe.
        ..subscribe(channels: <String>[channel1, channel2, channel3])
        // Unsubscribe.
        ..unsubscribe(channel: channel1)
        ..unsubscribe(channels: <String>[channel2, channel3]);

      expect(
          pubsub.stream,
          emitsInOrder(<Object>[
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.subscribe));
              expect(event.channel, equals(channel1));
              expect(event.channelCount, equals(1));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.subscribe));
              expect(event.channel, equals(channel2));
              expect(event.channelCount, equals(2));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.subscribe));
              expect(event.channel, equals(channel3));
              expect(event.channelCount, equals(3));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.unsubscribe));
              expect(event.channel, equals(channel1));
              expect(event.channelCount, equals(2));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.unsubscribe));
              expect(event.channel, equals(channel2));
              expect(event.channelCount, equals(1));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.unsubscribe));
              expect(event.channel, equals(channel3));
              expect(event.channelCount, equals(0));
              return true;
            },
          ]));
    });

    test('psubscribe', () async {
      final base = uuid();
      final pattern = '$base.*';
      final channel = '$base.test';
      final message = uuid();

      // Subscribe.
      pubsub.psubscribe(pattern: pattern);

      expect(
          pubsub.stream,
          emitsInOrder(<Object>[
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.psubscribe));
              expect(event.channel, equals(pattern));
              expect(event.channelCount, equals(1));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (MessageEvent<String, String> event) {
              expect(event.channel, equals(channel));
              expect(event.message, equals(message));
              expect(event.pattern, equals(pattern));
              return true;
            },
          ]));

      // Publish a message.
      await commands.publish(channel, message);
    });

    test('punsubscribe', () async {
      final pattern1 = uuid();
      final pattern2 = uuid();
      final pattern3 = uuid();

      pubsub
        // Subscribe.
        ..psubscribe(patterns: <String>[pattern1, pattern2, pattern3])
        // Unsubscribe.
        ..punsubscribe(pattern: pattern1)
        ..punsubscribe(patterns: <String>[pattern2, pattern3]);

      expect(
          pubsub.stream,
          emitsInOrder(<Object>[
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.psubscribe));
              expect(event.channel, equals(pattern1));
              expect(event.channelCount, equals(1));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.psubscribe));
              expect(event.channel, equals(pattern2));
              expect(event.channelCount, equals(2));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.psubscribe));
              expect(event.channel, equals(pattern3));
              expect(event.channelCount, equals(3));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.punsubscribe));
              expect(event.channel, equals(pattern1));
              expect(event.channelCount, equals(2));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.punsubscribe));
              expect(event.channel, equals(pattern2));
              expect(event.channelCount, equals(1));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.punsubscribe));
              expect(event.channel, equals(pattern3));
              expect(event.channelCount, equals(0));
              return true;
            },
          ]));
    });

    test('ping', () async {
      // Subscribe (PING only can be called after a pub/sub command).
      final channel = uuid();
      pubsub.subscribe(channel: channel);

      // Ping.
      final message = uuid();
      pubsub
        ..ping()
        ..ping(message);

      expect(
          pubsub.stream,
          emitsInOrder(<Object>[
            // ignore: avoid_types_on_closure_parameters
            (SubscriptionEvent<String> event) {
              expect(event.command, equals(PubSubEventType.subscribe));
              expect(event.channel, equals(channel));
              expect(event.channelCount, equals(1));
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (PongEvent<String> event) {
              expect(event.message, isEmpty);
              return true;
            },
            // ignore: avoid_types_on_closure_parameters
            (PongEvent<String> event) {
              expect(event.message, equals(message));
              return true;
            },
          ]));
    });

    test('codec', () async {
      expect(pubsub.codec.encode<List<int>>('abc'), equals([97, 98, 99]));
      expect(pubsub.codec.decode<String>(const StringReply([97, 98, 99])),
          equals('abc'));
    });

    group('support', () {
      group('SubscriptionEvent', () {
        test('Non null toString', () {
          const value = SubscriptionEvent<String>(null, 'channel', null);
          expect(value.toString(), startsWith('SubscriptionEvent<String>:'));
        });
        test('toString', () {
          const value = SubscriptionEvent<String?>(null, null, null);
          expect(value.toString(), startsWith('SubscriptionEvent<String?>:'));
        });
      });
      group('MessageEvent', () {
        test('toString', () {
          const value = MessageEvent<String?, String?>(null, null);
          expect(
              value.toString(), startsWith('MessageEvent<String?, String?>:'));
        });
      });

      group('PongEvent', () {
        test('toString', () {
          const value = PongEvent<String?>(null);
          expect(value.toString(), startsWith('PongEvent<String?>:'));
        });
      });
    });
  });
}
