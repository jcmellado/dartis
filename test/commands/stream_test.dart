// Copyright (c) 2020-Present, Juan Mellado. All rights reserved. Use of this
// source is governed by a MIT-style license found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late Commands<String, String> commands;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('StreamCommands', () {
    test('xack', () async {
      // Remove a pending message from the pending entries list.
      final key1 = uuid();
      final group1 = uuid();
      final consumer1 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key1, group: group1, id: r'$', mkstream: true);
      final id1 = await commands.xadd(key1, fields: {'pressure': '1'});
      await commands.xreadgroup(group1, consumer1, key: key1, id: '>');

      expect(await commands.xack(key1, group1, id: id1), equals(1));
      expect(await commands.xack(key1, group1, id: id1), equals(0));

      // Remove some pending messages from the pending entries list.
      final key2 = uuid();
      final group2 = uuid();
      final consumer2 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key2, group: group2, id: r'$', mkstream: true);
      final id2 = await commands.xadd(key2, fields: {'pressure': '1'});
      final id3 = await commands.xadd(key2, fields: {'pressure': '2'});
      await commands.xreadgroup(group2, consumer2, key: key2, id: '>');

      expect(await commands.xack(key2, group2, ids: [id2, id3]), equals(2));
      expect(await commands.xack(key2, group2, ids: [id2, id3]), equals(0));
    });

    test('xadd', () async {
      // Add entry without ID to a stream.
      final key1 = uuid();
      var result = await commands.xadd(key1, field: 'pressure', value: '1');
      expect(result, isNotNull);

      // Add entry with a given ID to a stream.
      final key2 = uuid();
      result =
          await commands.xadd(key2, id: '1-0', field: 'pressure', value: '1');
      expect(result, equals('1-0'));

      // Add some entries to a stream.
      final key3 = uuid();
      final id1 = await commands.xadd(key3, field: 'pressure', value: '1');
      final id2 = await commands.xadd(key3, field: 'pressure', value: '2');

      var stream = await commands.xrange(key3, '-', '+');
      expect(stream, hasLength(2));
      expect(stream[0].id, equals(id1));
      expect(stream[0].fields, equals({'pressure': '1'}));
      expect(stream[1].id, equals(id2));
      expect(stream[1].fields, equals({'pressure': '2'}));

      // Add some entries with several fields to a stream.
      final key4 = uuid();
      result = await commands
          .xadd(key4, fields: {'pressure': '1', 'temperature': '2'});

      stream = await commands.xrange(key4, '-', '+');
      expect(stream, hasLength(1));
      expect(stream[0].id, equals(result));
      expect(stream[0].fields, equals({'pressure': '1', 'temperature': '2'}));

      // Add some entries to a capped stream.
      final key5 = uuid();
      await commands.xadd(key5, field: 'pressure', value: '1');
      await commands.xadd(key5, maxlen: 1, field: 'pressure', value: '2');
      expect(await commands.xlen(key5), equals(1));

      // Add some entries to a capped stream with a minimum of entries.
      final key6 = uuid();
      await commands.xadd(key6, field: 'pressure', value: '1');
      await commands.xadd(key6,
          maxlen: 1, roughly: true, field: 'pressure', value: '2');
      expect(await commands.xlen(key6), greaterThanOrEqualTo(1));
    });

    test('xclaim', () async {
      // Try to claim a non existing message.
      final key1 = uuid();
      final group1 = uuid();
      final consumer1 = uuid();
      final consumer2 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key1, group: group1, id: r'$', mkstream: true);
      await commands.xadd(key1, fields: {'pressure': '1'});
      await commands.xreadgroup(group1, consumer1, key: key1, id: '>');

      var result1 =
          await commands.xclaim(key1, group1, consumer2, 0, id: '1-0');
      expect(result1, isEmpty);

      // Claims a message.
      final key2 = uuid();
      final group2 = uuid();
      final consumer3 = uuid();
      final consumer4 = uuid();

      await commands.xgroup(StreamGroupSubcommand.create,
          key: key2, group: group2, id: r'$', mkstream: true);

      final id1 = await commands.xadd(key2, fields: {'pressure': '1'});
      await commands.xreadgroup(group2, consumer3, key: key2, id: '>');

      result1 = await commands.xclaim(key2, group2, consumer4, 0, id: id1);
      expect(result1, isA<List>());

      final result2 = result1 as List<StreamEntry<String?, String?>?>;
      expect(result2, hasLength(1));
      expect(result2[0]!.id, equals(id1));
      expect(result2[0]!.fields, {'pressure': '1'});

      // Claims a message with options.
      final key3 = uuid();
      final group3 = uuid();
      final consumer5 = uuid();
      final consumer6 = uuid();

      await commands.xgroup(StreamGroupSubcommand.create,
          key: key3, group: group3, id: r'$', mkstream: true);

      final id2 = await commands.xadd(key3, fields: {'pressure': '1'});
      await commands.xreadgroup(group3, consumer5, key: key3, id: '>');

      result1 = await commands.xclaim(key3, group3, consumer6, 0,
          id: id2,
          idle: 10,
          idleTimestamp: 20,
          retryCount: 30,
          force: true,
          justId: true);
      expect(result1, isA<List>());

      final result3 = result1 as List<String?>;
      expect(result3, hasLength(1));
      expect(result3[0], equals(id2));
    });

    test('xdel', () async {
      // Delete an entry from empty stream.
      final key1 = uuid();
      expect(await commands.xdel(key1, id: '1-0'), equals(0));

      // Delete an entry from a stream.
      final key2 = uuid();
      await commands.xadd(key2, id: '1-0', fields: {'pressure': '1'});
      expect(await commands.xdel(key2, id: '1-0'), equals(1));

      // Delete some entries from a stream.
      final key3 = uuid();
      final id1 = await commands.xadd(key3, fields: {'pressure': '1'});
      final id2 = await commands.xadd(key3, fields: {'temperature': '2'});
      expect(await commands.xdel(key3, ids: [id1, id2]), equals(2));
    });

    test('xgroup', () async {
      // Create a consumer group.
      final key1 = uuid();
      final group1 = uuid();
      final group2 = uuid();
      final id1 = await commands.xadd(key1, fields: {'pressure': '1'});
      expect(
          await commands.xgroup(StreamGroupSubcommand.create,
              key: key1, group: group1, id: id1),
          isNull);
      expect(
          await commands.xgroup(StreamGroupSubcommand.create,
              key: key1, group: group2, id: r'$', mkstream: true),
          isNull);

      // Destroy a consumer group.
      final key2 = uuid();
      final group3 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key2, group: group3, id: r'$', mkstream: true);
      expect(
          await commands.xgroup(StreamGroupSubcommand.destroy,
              key: key2, group: group3),
          equals(1));
      expect(
          await commands.xgroup(StreamGroupSubcommand.destroy,
              key: key2, group: group3),
          equals(0));

      // Set the last delivered ID of a consumer group.
      final key3 = uuid();
      final group4 = uuid();
      final id2 = await commands.xadd(key3, fields: {'pressure': '1'});
      final id3 = await commands.xadd(key3, fields: {'pressure': '2'});
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key3, group: group4, id: id2, mkstream: true);
      expect(
          await commands.xgroup(StreamGroupSubcommand.setId,
              key: key3, group: group4, id: id3),
          isNull);

      // Remove a consumer of a consumer group.
      final key4 = uuid();
      final group5 = uuid();
      final consumer1 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key4, group: group5, id: r'$', mkstream: true);
      await commands.xadd(key4, fields: {'pressure': '1'});
      await commands.xreadgroup(group5, consumer1, key: key4, id: '>');
      expect(
          await commands.xgroup(StreamGroupSubcommand.deleteConsumer,
              key: key4, group: group5, consumer: consumer1),
          equals(1));
      expect(
          await commands.xgroup(StreamGroupSubcommand.deleteConsumer,
              key: key4, group: group5, consumer: consumer1),
          equals(0));

      // Print the help.
      expect(await commands.xgroup(StreamGroupSubcommand.help), isNotEmpty);
    });

    test('xinfo', () async {
      // Return information about an empty stream.
      final key1 = uuid();
      final group1 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key1, group: group1, id: r'$', mkstream: true);
      expect(await commands.xinfo(StreamInfoSubcommand.stream, key: key1),
          isNotEmpty);

      // Return information about a stream.
      final key2 = uuid();
      await commands.xadd(key2, fields: {'pressure': '1'});
      expect(await commands.xinfo(StreamInfoSubcommand.stream, key: key2),
          isNotEmpty);

      // Return information about the consumer groups of an empty stream.
      final key3 = uuid();
      await commands.xadd(key3, fields: {'pressure': '1'});
      expect(await commands.xinfo(StreamInfoSubcommand.groups, key: key3),
          isEmpty);

      // Return information about the consumer groups of a stream.
      final key4 = uuid();
      final group2 = uuid();
      final group3 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key4, group: group2, id: r'$', mkstream: true);
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key4, group: group3, id: r'$', mkstream: true);
      expect(await commands.xinfo(StreamInfoSubcommand.groups, key: key4),
          hasLength(2));

      // Return information about the consumers of an empty consumer group.
      final key5 = uuid();
      final group4 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key5, group: group4, id: r'$', mkstream: true);
      expect(
          await commands.xinfo(StreamInfoSubcommand.consumers,
              key: key5, group: group4),
          isEmpty);

      // Return information about the consumers of a consumer group.
      final key6 = uuid();
      final group5 = uuid();
      final consumer1 = uuid();
      final consumer2 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key6, group: group5, id: r'$', mkstream: true);
      await commands.xadd(key6, fields: {'pressure': '1'});
      await commands.xadd(key6, fields: {'pressure': '2'});
      await commands.xreadgroup(group5, consumer1,
          key: key6, id: '>', count: 1);
      await commands.xreadgroup(group5, consumer2,
          key: key6, id: '>', count: 1);
      expect(
          await commands.xinfo(StreamInfoSubcommand.consumers,
              key: key6, group: group5),
          hasLength(2));

      // Print the help
      expect(await commands.xinfo(StreamInfoSubcommand.help), isNotEmpty);
    });

    test('xlen', () async {
      // Get length of non existing stream.
      final key1 = uuid();
      expect(await commands.xlen(key1), equals(0));

      // Get length of empty stream.
      final key2 = uuid();
      await commands.xadd(key2, id: '1-0', fields: {'pressure': '1'});
      await commands.xdel(key2, id: '1-0');
      expect(await commands.xlen(key2), equals(0));

      // Get length of stream.
      final key3 = uuid();
      await commands.xadd(key3, fields: {'pressure': '1'});
      await commands.xadd(key3, fields: {'pressure': '2'});
      expect(await commands.xlen(key3), equals(2));
    });

    test('xpending', () async {
      // Inspect an empty pending entries list.
      final key1 = uuid();
      final group1 = uuid();
      final consumer1 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key1, group: group1, id: r'$', mkstream: true);
      await commands.xreadgroup(group1, consumer1, key: key1, id: '>');

      var result1 = await commands.xpending(key1, group1);
      expect(result1, isA<StreamPendingSummary>());

      var result2 = result1 as StreamPendingSummary<String, String>;
      expect(result2.pendingCount, equals(0));
      expect(result2.firstEntryId, '');
      expect(result2.lastEntryId, '');
      expect(result2.consumers, <StreamPendingConsumer<String, String>>[]);

      // Inspect a pending entries list.
      final key2 = uuid();
      final group2 = uuid();
      final consumer2 = uuid();
      final consumer3 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key2, group: group2, id: r'$', mkstream: true);
      final id1 = await commands.xadd(key2, fields: {'pressure': '1'});
      await commands.xreadgroup(group2, consumer2, key: key2, id: '>');
      final id2 = await commands.xadd(key2, fields: {'pressure': '2'});
      await commands.xreadgroup(group2, consumer3, key: key2, id: '>');

      result1 = await commands.xpending(key2, group2);
      expect(result1, isA<StreamPendingSummary>());

      result2 = result1 as StreamPendingSummary<String, String>;
      expect(result2.pendingCount, equals(2));
      expect(result2.firstEntryId, equals(id1));
      expect(result2.lastEntryId, equals(id2));
      expect(result2.consumers, hasLength(2));
      expect(result2.consumers[0].name, isNotNull);
      expect(result2.consumers[0].pendingCount, equals(1));
      expect(result2.consumers[1].name, isNotNull);
      expect(result2.consumers[1].pendingCount, equals(1));

      // Inspect an empty range of a pending entries list.
      final key3 = uuid();
      final group3 = uuid();
      final consumer4 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key3, group: group3, id: r'$', mkstream: true);
      await commands.xreadgroup(group3, consumer4, key: key3, id: '>');

      var result3 =
          await commands.xpending(key3, group3, start: '-', end: '+', count: 1);
      expect(result3, isA<List>());

      var result4 = result3 as List<StreamPendingEntry<String?, String>>;
      expect(result4, isEmpty);

      // Inspect a range of a pending entries list.
      final key4 = uuid();
      final group4 = uuid();
      final consumer5 = uuid();
      final consumer6 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key4, group: group4, id: r'$', mkstream: true);
      final id3 = await commands.xadd(key4, fields: {'pressure': '1'});
      await commands.xreadgroup(group4, consumer5, key: key4, id: '>');
      final id4 = await commands.xadd(key4, fields: {'pressure': '2'});
      await commands.xreadgroup(group4, consumer6, key: key4, id: '>');

      result3 =
          await commands.xpending(key4, group4, start: '-', end: '+', count: 2);
      expect(result3, isA<List>());

      result4 = result3 as List<StreamPendingEntry<String?, String>>;
      expect(result4, hasLength(2));
      expect(result4[0].id, equals(id3));
      expect(result4[0].consumer, equals(consumer5));
      expect(result4[0].deliveryTime, greaterThanOrEqualTo(0));
      expect(result4[0].deliveredCount, equals(1));
      expect(result4[1].id, equals(id4));
      expect(result4[1].consumer, equals(consumer6));
      expect(result4[1].deliveryTime, greaterThanOrEqualTo(0));
      expect(result4[1].deliveredCount, equals(1));

      // Inspect a range of a pending entries list of a consumer.
      final key5 = uuid();
      final group5 = uuid();
      final consumer7 = uuid();
      final consumer8 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key5, group: group5, id: r'$', mkstream: true);
      final id5 = await commands.xadd(key5, fields: {'pressure': '1'});
      await commands.xreadgroup(group5, consumer7, key: key5, id: '>');
      await commands.xadd(key5, fields: {'pressure': '2'});
      await commands.xreadgroup(group5, consumer8, key: key5, id: '>');

      result3 = await commands.xpending(key5, group5,
          start: '-', end: '+', count: 1, consumer: consumer7);
      expect(result3, isA<List>());

      result4 = result3 as List<StreamPendingEntry<String?, String>>;
      expect(result4, hasLength(1));
      expect(result4[0].id, equals(id5));
      expect(result4[0].consumer, equals(consumer7));
      expect(result4[0].deliveryTime, greaterThanOrEqualTo(0));
      expect(result4[0].deliveredCount, equals(1));
    });

    test('xrange', () async {
      // Get range from non existing stream.
      final key1 = uuid();
      expect(await commands.xrange(key1, '-', '+'), isEmpty);

      // Get range from stream.
      final key2 = uuid();
      await commands.xadd(key2, id: '1-0', fields: {'pressure': '1'});

      var result = await commands.xrange(key2, '-', '+');
      expect(result, hasLength(1));
      expect(result[0].id, equals('1-0'));
      expect(result[0].fields, equals({'pressure': '1'}));

      // Get partial range from stream.
      final key3 = uuid();
      await commands.xadd(key3, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key3, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key3, id: '1-2', fields: {'pressure': '3'});
      await commands.xadd(key3, id: '1-3', fields: {'pressure': '4'});

      result = await commands.xrange(key3, '1-1', '1-2');
      expect(result, hasLength(2));
      expect(result[0].id, equals('1-1'));
      expect(result[0].fields, equals({'pressure': '2'}));
      expect(result[1].id, equals('1-2'));
      expect(result[1].fields, equals({'pressure': '3'}));

      // Get capped range from stream.
      final key4 = uuid();
      await commands.xadd(key4, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key4, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key4, id: '1-2', fields: {'pressure': '3'});
      await commands.xadd(key4, id: '1-3', fields: {'pressure': '4'});

      result = await commands.xrange(key4, '1-1', '1-2', count: 1);
      expect(result, hasLength(1));
      expect(result[0].id, equals('1-1'));
      expect(result[0].fields, equals({'pressure': '2'}));
    });

    test('xread', () async {
      // Try to read from non existing stream.
      final key1 = uuid();
      expect(await commands.xread(key: key1, id: '0-0'), isNull);

      // Read from stream.
      final key2 = uuid();
      await commands.xadd(key2, id: '1-0', fields: {'pressure': '1'});

      var result = await commands.xread(key: key2, id: '0');
      expect(result, hasLength(1));
      expect(result!.keys.first, equals(key2));
      expect(result[key2], hasLength(1));
      expect(result[key2]![0]!.id, equals('1-0'));
      expect(result[key2]![0]!.fields, equals({'pressure': '1'}));

      // Read from multiple streams.
      final key3 = uuid();
      final key4 = uuid();
      await commands.xadd(key3, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key4, id: '2-0', fields: {'pressure': '2'});

      result = await commands.xread(keys: [key3, key4], ids: ['0', '0']);
      expect(result!, hasLength(2));
      expect(result[key3], hasLength(1));
      expect(result[key3]![0]!.id, equals('1-0'));
      expect(result[key3]![0]!.fields, equals({'pressure': '1'}));
      expect(result[key4], hasLength(1));
      expect(result[key4]![0]!.id, equals('2-0'));
      expect(result[key4]![0]!.fields, equals({'pressure': '2'}));

      // Read partial range from stream.
      final key5 = uuid();
      await commands.xadd(key5, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key5, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key5, id: '1-2', fields: {'pressure': '3'});
      await commands.xadd(key5, id: '1-3', fields: {'pressure': '4'});

      result = await commands.xread(key: key5, id: '1-1');
      expect(result!, hasLength(1));
      expect(result[key5], hasLength(2));
      expect(result[key5]![0]!.id, equals('1-2'));
      expect(result[key5]![0]!.fields, equals({'pressure': '3'}));
      expect(result[key5]![1]!.id, equals('1-3'));
      expect(result[key5]![1]!.fields, equals({'pressure': '4'}));

      // Read capped range from stream.
      final key6 = uuid();
      await commands.xadd(key6, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key6, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key6, id: '1-2', fields: {'pressure': '3'});
      await commands.xadd(key6, id: '1-3', fields: {'pressure': '4'});

      result = await commands.xread(key: key6, id: '1-1', count: 1);
      expect(result!, hasLength(1));
      expect(result[key6], hasLength(1));
      expect(result[key6]![0]!.id, equals('1-2'));
      expect(result[key6]![0]!.fields, equals({'pressure': '3'}));

      // Read blocking entry from stream.
      final key7 = uuid();
      final key8 = uuid();
      await commands.xadd(key7, id: '1-0', fields: {'pressure': '1'});

      result =
          await commands.xread(keys: [key7, key8], ids: ['0', '0'], timeout: 1);
      expect(result!, hasLength(1));
      expect(result[key7], hasLength(1));
      expect(result[key7]![0]!.id, equals('1-0'));
      expect(result[key7]![0]!.fields, equals({'pressure': '1'}));
    });

    test('xreadgroup', () async {
      // Read from an empty stream.
      final key1 = uuid();
      final group1 = uuid();
      final consumer1 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key1, group: group1, id: r'$', mkstream: true);

      var result =
          await commands.xreadgroup(group1, consumer1, key: key1, id: '>');
      expect(result, isNull);

      // Read from a stream.
      final key2 = uuid();
      final group2 = uuid();
      final consumer2 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key2, group: group2, id: r'$', mkstream: true);
      final id1 = await commands.xadd(key2, fields: {'pressure': '1'});
      final id2 = await commands.xadd(key2, fields: {'temperature': '2'});

      result = await commands.xreadgroup(group2, consumer2, key: key2, id: '>');
      expect(result!, hasLength(1));
      expect(result[key2], hasLength(2));
      expect(result[key2]![0]!.id, id1);
      expect(result[key2]![0]!.fields, equals({'pressure': '1'}));
      expect(result[key2]![1]!.id, id2);
      expect(result[key2]![1]!.fields, equals({'temperature': '2'}));

      // Read from multiple streams.
      final key3 = uuid();
      final key4 = uuid();
      final group3 = uuid();
      final consumer3 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key3, group: group3, id: r'$', mkstream: true);
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key4, group: group3, id: r'$', mkstream: true);
      final id3 = await commands.xadd(key3, fields: {'pressure': '1'});
      final id4 = await commands.xadd(key4, fields: {'temperature': '2'});

      result = await commands
          .xreadgroup(group3, consumer3, keys: [key3, key4], ids: ['>', '>']);
      expect(result!, hasLength(2));
      expect(result[key3], hasLength(1));
      expect(result[key3]![0]!.id, id3);
      expect(result[key3]![0]!.fields, equals({'pressure': '1'}));
      expect(result[key4], hasLength(1));
      expect(result[key4]![0]!.id, id4);
      expect(result[key4]![0]!.fields, equals({'temperature': '2'}));

      // Read partial pending range from stream.
      final key5 = uuid();
      final group4 = uuid();
      final consumer4 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key5, group: group4, id: r'$', mkstream: true);
      await commands.xadd(key5, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key5, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key5, id: '1-2', fields: {'pressure': '3'});
      await commands.xadd(key5, id: '1-3', fields: {'pressure': '4'});
      await commands.xreadgroup(group4, consumer4, key: key5, id: '>');

      result =
          await commands.xreadgroup(group4, consumer4, key: key5, id: '1-1');
      expect(result!, hasLength(1));
      expect(result[key5], hasLength(2));
      expect(result[key5]![0]!.id, equals('1-2'));
      expect(result[key5]![0]!.fields, equals({'pressure': '3'}));
      expect(result[key5]![1]!.id, equals('1-3'));
      expect(result[key5]![1]!.fields, equals({'pressure': '4'}));

      // Read capped pending range from stream.
      final key6 = uuid();
      final group5 = uuid();
      final consumer5 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key6, group: group5, id: r'$', mkstream: true);
      await commands.xadd(key6, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key6, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key6, id: '1-2', fields: {'pressure': '3'});
      await commands.xadd(key6, id: '1-3', fields: {'pressure': '4'});
      await commands.xreadgroup(group5, consumer5, key: key6, id: '>');

      result = await commands.xreadgroup(group5, consumer5,
          key: key6, id: '1-1', count: 1);
      expect(result!, hasLength(1));
      expect(result[key6], hasLength(1));
      expect(result[key6]![0]!.id, equals('1-2'));
      expect(result[key6]![0]!.fields, equals({'pressure': '3'}));

      // Read blocking pending entry from stream.
      final key7 = uuid();
      final group6 = uuid();
      final consumer6 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key7, group: group6, id: r'$', mkstream: true);
      await commands.xadd(key7, id: '1-0', fields: {'pressure': '1'});
      await commands.xreadgroup(group6, consumer6, key: key7, id: '>');

      result = await commands.xreadgroup(group6, consumer6,
          key: key7, id: '0', timeout: 1);
      expect(result!, hasLength(1));
      expect(result[key7], hasLength(1));
      expect(result[key7]![0]!.id, equals('1-0'));
      expect(result[key7]![0]!.fields, equals({'pressure': '1'}));

      // Read acknowledging from stream.
      final key8 = uuid();
      final group7 = uuid();
      final consumer7 = uuid();
      await commands.xgroup(StreamGroupSubcommand.create,
          key: key8, group: group7, id: r'$', mkstream: true);
      await commands.xadd(key8, id: '1-0', fields: {'pressure': '1'});
      await commands.xreadgroup(group7, consumer7,
          key: key8, id: '>', noack: true);

      result = await commands.xreadgroup(group7, consumer7,
          key: key8, id: '0', timeout: 1);
      expect(result!, hasLength(1));
      expect(result[key8], isEmpty);
    });

    test('xrevrange', () async {
      // Get range from non existing stream.
      final key1 = uuid();
      expect(await commands.xrevrange(key1, '+', '-'), isEmpty);

      // Get range from stream.
      final key2 = uuid();
      await commands.xadd(key2, id: '1-0', field: 'pressure', value: '1');
      var result = await commands.xrevrange(key2, '+', '-');
      expect(result, hasLength(1));
      expect(result[0]!.id, equals('1-0'));
      expect(result[0]!.fields, equals({'pressure': '1'}));

      // Get partial range from stream.
      final key3 = uuid();
      await commands.xadd(key3, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key3, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key3, id: '1-2', fields: {'pressure': '3'});
      await commands.xadd(key3, id: '1-3', fields: {'pressure': '4'});
      result = await commands.xrevrange(key3, '1-2', '1-1');
      expect(result, hasLength(2));
      expect(result[0]!.id, equals('1-2'));
      expect(result[0]!.fields, equals({'pressure': '3'}));
      expect(result[1]!.id, equals('1-1'));
      expect(result[1]!.fields, equals({'pressure': '2'}));

      // Get capped range from stream.
      final key4 = uuid();
      await commands.xadd(key4, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key4, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key4, id: '1-2', fields: {'pressure': '3'});
      await commands.xadd(key4, id: '1-3', fields: {'pressure': '4'});
      result = await commands.xrevrange(key4, '1-2', '1-1', count: 1);
      expect(result, hasLength(1));
      expect(result[0]!.id, equals('1-2'));
      expect(result[0]!.fields, equals({'pressure': '3'}));
    });

    test('xtrim', () async {
      // Trim a non existing stream.
      final key1 = uuid();
      expect(await commands.xtrim(key1, 100), equals(0));

      // Trim a stream.
      final key2 = uuid();
      await commands.xadd(key2, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key2, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key2, id: '1-2', fields: {'pressure': '3'});
      expect(await commands.xtrim(key2, 1), equals(2));

      // Trim a stream.
      final key3 = uuid();
      await commands.xadd(key3, id: '1-0', fields: {'pressure': '1'});
      await commands.xadd(key3, id: '1-1', fields: {'pressure': '2'});
      await commands.xadd(key3, id: '1-2', fields: {'pressure': '3'});
      expect(await commands.xtrim(key3, 1, roughly: true),
          greaterThanOrEqualTo(0));
    });

    group('support', () {
      group('StreamGroupSubcommand', () {
        test('toString', () {
          expect(StreamGroupSubcommand.create.toString(),
              startsWith('StreamGroupSubcommand:'));
        });
      });

      group('StreamInfoSubcommand', () {
        test('toString', () {
          expect(StreamInfoSubcommand.stream.toString(),
              startsWith('StreamInfoSubcommand:'));
        });
      });

      group('StreamEntry', () {
        test('toString', () {
          const value = StreamEntry<String?, String>(null, null);
          expect(value.toString(), startsWith('StreamEntry<String?, String>:'));
        });
      });

      group('StreamPendingSummary', () {
        test('toString', () {
          const value =
              StreamPendingSummary<String?, String>(null, null, null, []);
          expect(value.toString(),
              startsWith('StreamPendingSummary<String?, String>:'));
        });
      });

      group('StreamPendingConsumer', () {
        test('toString', () {
          const value = StreamPendingConsumer<String?, String>(null, null);
          expect(value.toString(),
              startsWith('StreamPendingConsumer<String?, String>:'));
        });
      });

      group('StreamPendingEntry', () {
        test('toString', () {
          const value =
              StreamPendingEntry<String?, String>(null, null, null, null);
          expect(value.toString(),
              startsWith('StreamPendingEntry<String?, String>:'));
        });
      });
    });
  });
}
