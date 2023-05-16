// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: directives_ordering
import 'package:dartis/dartis.dart';

import '../util.dart' show uuid;

void main() {
  late Client client;
  late GeoCommands<String, String> commands;

  // Some items for testing.
  const item1 = GeoItem<String>(GeoPosition(-3.6827461, 40.4893538), 'Madrid');
  const item2 =
      GeoItem<String>(GeoPosition(-0.3545661, 39.4561165), 'Valencia');
  const item3 = GeoItem<String>(GeoPosition(-4.3971722, 36.7585406), 'Málaga');

  // Precision.
  const delta = 0.0001;

  setUp(() async {
    client = await Client.connect('redis://localhost:6379');
    commands = client.asCommands<String, String>();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('GeoCommands', () {
    test('geoadd', () async {
      final key = uuid();

      // Add one item.
      expect(await commands.geoadd(key, item: item1), equals(1));

      // Add some items.
      expect(await commands.geoadd(key, items: [item2, item3]), equals(2));
    });

    test('geodist', () async {
      // Add some items.
      final key1 = uuid();
      await commands.geoadd(key1, items: [item1, item2, item3]);

      // Compute some distances.
      expect(await commands.geodist(key1, 'Madrid', 'Valencia'),
          closeTo(306056.1482, delta));
      expect(await commands.geodist(key1, 'Madrid', 'Málaga'),
          closeTo(419577.957, delta));

      // Compute the same distance with a different unit each time.
      expect(
          await commands.geodist(key1, 'Madrid', 'Valencia',
              unit: GeoUnit.meter),
          closeTo(306056.1482, delta));
      expect(
          await commands.geodist(key1, 'Madrid', 'Valencia',
              unit: GeoUnit.kilometer),
          closeTo(306.0561, delta));
      expect(
          await commands.geodist(key1, 'Madrid', 'Valencia',
              unit: GeoUnit.mile),
          closeTo(190.1749, delta));
      expect(
          await commands.geodist(key1, 'Madrid', 'Valencia',
              unit: GeoUnit.feet),
          closeTo(1004121.221, delta));

      // Compute the distance to a non existing member.
      final key2 = uuid();
      expect(await commands.geodist(key1, 'Madrid', key2), isNull);

      // Try to compute a distance from a non existing set.
      final key3 = uuid();
      expect(await commands.geodist(key3, 'Madrid', 'Valencia'), isNull);
    });

    test('geohash', () async {
      // Add some items.
      final key1 = uuid();
      await commands.geoadd(key1, items: [item1, item2, item3]);

      // Get one geohash.
      expect(await commands.geohash(key1, member: 'Madrid'),
          equals(['ezjqk4y79f0']));

      // Get some geohashes.
      expect(await commands.geohash(key1, members: ['Valencia', 'Málaga']),
          equals(['ezp8ryvbd10', 'eysc5gwn420']));

      // Get the geohash of a not existing member.
      final key2 = uuid();
      expect(await commands.geohash(key1, member: key2), equals([null]));

      expect(
          await commands.geohash(key1, members: ['Valencia', key2, 'Málaga']),
          equals(['ezp8ryvbd10', null, 'eysc5gwn420']));

      // Try to retrieve a geohash from a non existing set.
      final key3 = uuid();
      expect(await commands.geohash(key3, member: 'Madrid'), equals([null]));
    });

    test('geopos', () async {
      // Add some items.
      final key1 = uuid();
      await commands.geoadd(key1, items: [item1, item2, item3]);

      // Get one position.
      var results = await commands.geopos(key1, member: 'Madrid');
      expect(results![0]!.longitude, closeTo(-3.6827461, delta));
      expect(results[0]!.latitude, closeTo(40.4893538, delta));

      // Get some positions.
      results = await commands.geopos(key1, members: ['Valencia', 'Málaga']);
      expect(results![0]!.longitude, closeTo(-0.3545661, delta));
      expect(results[0]!.latitude, closeTo(39.4561165, delta));
      expect(results[1]!.longitude, closeTo(-4.3971722, delta));
      expect(results[1]!.latitude, closeTo(36.7585406, delta));

      // Get the position of a non existing member.
      final key2 = uuid();
      results = await commands.geopos(key1, member: key2);
      expect(results, equals([null]));

      results =
          await commands.geopos(key1, members: ['Valencia', key2, 'Málaga']);
      expect(results![0], isNotNull);
      expect(results[1], isNull);
      expect(results[2], isNotNull);

      // Try to retrieve a position from a non existing set.
      final key3 = uuid();
      expect(await commands.geopos(key3, member: 'Madrid'), equals([null]));
    });

    test('georadius', () async {
      // Add some items.
      final key1 = uuid();
      await commands.geoadd(key1, items: [item1, item2, item3]);

      // Compute.
      var results = await commands.georadius(
          key1, -0.2638491, 37.8234928, 0.0, GeoUnit.kilometer);
      expect(results, isEmpty);

      results = await commands.georadius(
          key1, -0.2638491, 37.8234928, 200.0, GeoUnit.kilometer);
      expect(results![0].member, 'Valencia');
      expect(results[0].position, isNull);
      expect(results[0].hash, isNull);
      expect(results[0].distance, isNull);

      // Compute retrieving the position.
      results = await commands.georadius(
          key1, -0.2638491, 37.8234928, 200.0, GeoUnit.kilometer,
          withCoord: true);
      expect(results![0].member, 'Valencia');
      expect(results[0].position!.longitude, closeTo(-0.3545661, delta));
      expect(results[0].position!.latitude, closeTo(39.4561165, delta));
      expect(results[0].hash, isNull);
      expect(results[0].distance, isNull);

      // Compute retrieving the position and hash.
      results = await commands.georadius(
          key1, -0.2638491, 37.8234928, 200.0, GeoUnit.kilometer,
          withCoord: true, withHash: true);
      expect(results![0].member, 'Valencia');
      expect(results[0].position!.longitude, closeTo(-0.3545661, delta));
      expect(results[0].position!.latitude, closeTo(39.4561165, delta));
      expect(results[0].hash, equals(1969199198234197));
      expect(results[0].distance, isNull);

      // Compute retrieving the position, hash and distance.
      results = await commands.georadius(
          key1, -0.2638491, 37.8234928, 200.0, GeoUnit.kilometer,
          withCoord: true, withHash: true, withDist: true);
      expect(results![0].member, 'Valencia');
      expect(results[0].position!.longitude, closeTo(-0.3545661, delta));
      expect(results[0].position!.latitude, closeTo(39.4561165, delta));
      expect(results[0].hash, equals(1969199198234197));
      expect(results[0].distance, closeTo(181.7617, delta));

      // Compute limiting the results.
      results = await commands.georadius(
          key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
          count: 1);
      expect(results, hasLength(1));

      results = await commands.georadius(
          key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
          count: 99);
      expect(results, hasLength(3));

      // Compute ordering the results.
      results = await commands.georadius(
          key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
          order: GeoOrder.ascending);
      expect(results![0].member, 'Valencia');
      expect(results[1].member, 'Málaga');
      expect(results[2].member, 'Madrid');

      results = await commands.georadius(
          key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
          order: GeoOrder.descending);
      expect(results![0].member, 'Madrid');
      expect(results[1].member, 'Málaga');
      expect(results[2].member, 'Valencia');

      // Try to retrieve from a non existing set.
      final key2 = uuid();
      expect(
          await commands.georadius(
              key2, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer),
          isEmpty);
    });

    test('georadiusStore', () async {
      // Add some items.
      final key1 = uuid();
      await commands.geoadd(key1, items: [item1, item2, item3]);

      // Compute and store the results.
      final key2 = uuid();
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 0.0, GeoUnit.kilometer,
              storeKey: key2),
          equals(0));
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 200.0, GeoUnit.kilometer,
              storeKey: key2),
          equals(1));
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              storeKey: key2),
          equals(3));

      final key3 = uuid();
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 0.0, GeoUnit.kilometer,
              storeDistKey: key3),
          equals(0));
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 200.0, GeoUnit.kilometer,
              storeDistKey: key3),
          equals(1));
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              storeDistKey: key3),
          equals(3));

      // Compute and store the results limiting the results.
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              count: 1, storeKey: key2),
          equals(1));
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              count: 99, storeKey: key2),
          equals(3));

      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              count: 1, storeDistKey: key3),
          equals(1));
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              count: 99, storeDistKey: key3),
          equals(3));

      // Compute and store the results ordering the results.
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              order: GeoOrder.ascending, storeKey: key2),
          equals(3));
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              order: GeoOrder.descending, storeKey: key2),
          equals(3));

      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              order: GeoOrder.ascending, storeDistKey: key3),
          equals(3));
      expect(
          await commands.georadiusStore(
              key1, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              order: GeoOrder.descending, storeDistKey: key3),
          equals(3));

      // Try to retrieve from a non existing set.
      final key4 = uuid();
      expect(
          await commands.georadiusStore(
              key4, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              storeKey: key2),
          isZero);

      expect(
          await commands.georadiusStore(
              key4, -0.2638491, 37.8234928, 1000.0, GeoUnit.kilometer,
              storeDistKey: key3),
          isZero);
    });

    test('georadiusbymember', () async {
      // Add some items.
      final key1 = uuid();
      await commands.geoadd(key1, items: [item1, item2, item3]);

      // Compute.
      var results = await commands.georadiusbymember(
          key1, 'Madrid', 0.0, GeoUnit.kilometer);
      expect(results![0].member, 'Madrid');
      expect(results[0].position, isNull);
      expect(results[0].hash, isNull);
      expect(results[0].distance, isNull);

      results = await commands.georadiusbymember(
          key1, 'Madrid', 400.0, GeoUnit.kilometer);
      expect(results![0].member, 'Valencia');
      expect(results[0].position, isNull);
      expect(results[0].hash, isNull);
      expect(results[0].distance, isNull);

      // Compute retrieving the position.
      results = await commands.georadiusbymember(
          key1, 'Madrid', 400.0, GeoUnit.kilometer,
          withCoord: true);
      expect(results![0].member, 'Valencia');
      expect(results[0].position!.longitude, closeTo(-0.3545661, delta));
      expect(results[0].position!.latitude, closeTo(39.4561165, delta));
      expect(results[0].hash, isNull);
      expect(results[0].distance, isNull);

      // Compute retrieving the position and hash.
      results = await commands.georadiusbymember(
          key1, 'Madrid', 400.0, GeoUnit.kilometer,
          withCoord: true, withHash: true);
      expect(results![0].member, 'Valencia');
      expect(results[0].position!.longitude, closeTo(-0.3545661, delta));
      expect(results[0].position!.latitude, closeTo(39.4561165, delta));
      expect(results[0].hash, equals(1969199198234197));
      expect(results[0].distance, isNull);

      // Compute retrieving the position, hash and distance.
      results = await commands.georadiusbymember(
          key1, 'Madrid', 400.0, GeoUnit.kilometer,
          withCoord: true, withHash: true, withDist: true);
      expect(results![0].member, 'Valencia');
      expect(results[0].position!.longitude, closeTo(-0.3545661, delta));
      expect(results[0].position!.latitude, closeTo(39.4561165, delta));
      expect(results[0].hash, equals(1969199198234197));
      expect(results[0].distance, closeTo(306.0561, delta));

      // Compute limiting the results.
      results = await commands.georadiusbymember(
          key1, 'Madrid', 1000.0, GeoUnit.kilometer,
          count: 1);
      expect(results, hasLength(1));

      results = await commands.georadiusbymember(
          key1, 'Madrid', 1000.0, GeoUnit.kilometer,
          count: 99);
      expect(results, hasLength(3));

      // Compute ordering the results.
      results = await commands.georadiusbymember(
          key1, 'Madrid', 1000.0, GeoUnit.kilometer,
          order: GeoOrder.ascending);
      expect(results![0].member, 'Madrid');
      expect(results[1].member, 'Valencia');
      expect(results[2].member, 'Málaga');

      results = await commands.georadiusbymember(
          key1, 'Madrid', 1000.0, GeoUnit.kilometer,
          order: GeoOrder.descending);
      expect(results![0].member, 'Málaga');
      expect(results[1].member, 'Valencia');
      expect(results[2].member, 'Madrid');

      // Try to retrieve from a non existing set.
      final key2 = uuid();
      expect(
          await commands.georadiusbymember(
              key2, 'Madrid', 1000.0, GeoUnit.kilometer),
          isEmpty);
    });

    test('georadiusbymemberStore', () async {
      // Add some items.
      final key1 = uuid();
      await commands.geoadd(key1, items: [item1, item2, item3]);

      // Compute and store the results.
      final key2 = uuid();
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 0.0, GeoUnit.kilometer,
              storeDistKey: key2),
          equals(1));
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              storeDistKey: key2),
          equals(3));

      final key3 = uuid();
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 0.0, GeoUnit.kilometer,
              storeDistKey: key3),
          equals(1));
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              storeDistKey: key3),
          equals(3));

      // Compute and store the results limiting the results.
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              count: 1, storeKey: key2),
          equals(1));
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              count: 99, storeKey: key2),
          equals(3));

      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              count: 1, storeDistKey: key3),
          equals(1));
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              count: 99, storeDistKey: key3),
          equals(3));

      // Compute and store the results ordering the results.
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              order: GeoOrder.ascending, storeKey: key2),
          equals(3));
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              order: GeoOrder.descending, storeKey: key2),
          equals(3));

      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              order: GeoOrder.ascending, storeDistKey: key3),
          equals(3));
      expect(
          await commands.georadiusbymemberStore(
              key1, 'Madrid', 1000.0, GeoUnit.kilometer,
              order: GeoOrder.descending, storeDistKey: key3),
          equals(3));

      // Try to retrieve from a non existing set.
      final key4 = uuid();
      expect(
          await commands.georadiusbymemberStore(
              key4, 'Madrid', 1000.0, GeoUnit.kilometer,
              storeKey: key2),
          isZero);

      expect(
          await commands.georadiusbymemberStore(
              key4, 'Madrid', 1000.0, GeoUnit.kilometer,
              storeDistKey: key3),
          isZero);
    });

    group('support', () {
      group('GeoUnit', () {
        test('toString', () {
          expect(GeoUnit.meter.toString(), startsWith('GeoUnit:'));
        });
      });

      group('GeoOrder', () {
        test('toString', () {
          expect(GeoOrder.ascending.toString(), startsWith('GeoOrder:'));
        });
      });

      group('GeoPosition', () {
        test('toString', () {
          const value = GeoPosition(0.0, 0.0);
          expect(value.toString(), startsWith('GeoPosition:'));
        });
      });

      group('GeoItem', () {
        test('toString', () {
          const position = GeoPosition(0.0, 0.0);
          const value = GeoItem<String?>(position, null);
          expect(value.toString(), startsWith('GeoItem<String?>:'));
        });
      });

      group('GeoradiusResult', () {
        test('toString', () {
          const value = GeoradiusResult<String?>(null);
          expect(value.toString(), startsWith('GeoradiusResult<String?>:'));
        });
      });
    });
  });
}
