// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import '../command.dart';
import '../protocol.dart';

/// A convenient shared mapper for the GEOPOS command.
const GeoPositionMapper geoPositionMapper = GeoPositionMapper();

/// A convenient shared mapper for the GEORADIUS family commands.
const GeoRadiusStoreMapper geoRadiusStoreMapper = GeoRadiusStoreMapper();

/// Redis geo commands.
abstract class GeoCommands<K, V> {
  /// Adds one or more geospatial items in the geospatial index represented
  /// by the sorted set stored at [key].
  ///
  /// Returns the number of elements added to the sorted set.
  ///
  /// See https://redis.io/commands/geoadd
  Future<int?> geoadd(K key,
      {GeoItem<V>? item, Iterable<GeoItem<V>> items = const []});

  /// Returns the distance between two members in the geospatial index
  /// represented by the sorted set stored at [key].
  ///
  /// See https://redis.io/commands/geodist
  Future<double?> geodist(K key, V member1, V member2, {GeoUnit? unit});

  /// Returns members of a geospatial index represented by the sorted set
  /// stored at [key] as standard geohash strings.
  ///
  /// See https://redis.io/commands/geohash
  Future<List<String?>?> geohash(K key,
      {V? member, Iterable<V> members = const []});

  /// Returns the positions (longitude, latitude) of all the specified members
  /// of the geospatial index represented by the sorted set stored at [key].
  ///
  /// See https://redis.io/commands/geopos
  Future<List<GeoPosition?>?> geopos(K key,
      {V? member, Iterable<V> members = const []});

  /// Queries a geospatial index represented by the sorted set stored at [key]
  /// to fetch members matching a given maximum distance from a point.
  ///
  /// See [georadiusStore].
  ///
  /// See https://redis.io/commands/georadius
  Future<List<GeoradiusResult<V>>?> georadius(
      K key, double longitude, double latitude, double radius, GeoUnit unit,
      {bool withCoord = false,
      bool withDist = false,
      bool withHash = false,
      int? count,
      GeoOrder? order});

  /// Queries a geospatial index represented by the sorted set stored at [key]
  /// to fetch members matching a given maximum distance from a point and
  /// stores the result.
  ///
  /// See [georadius].
  ///
  /// See https://redis.io/commands/georadius
  Future<int?> georadiusStore(
      K key, double longitude, double latitude, double radius, GeoUnit unit,
      {int? count, GeoOrder? order, K? storeKey, K? storeDistKey});

  /// Queries a geospatial index represented by the sorted set stored at [key]
  /// to fetch members matching a given maximum distance from a member.
  ///
  /// See [georadiusbymemberStore].
  ///
  /// See https://redis.io/commands/georadiusbymember
  Future<List<GeoradiusResult<V>>?> georadiusbymember(
      K key, V member, double radius, GeoUnit unit,
      {bool withCoord = false,
      bool withDist = false,
      bool withHash = false,
      int? count,
      GeoOrder? order});

  /// Queries a geospatial index represented by the sorted set stored at [key]
  /// to fetch members matching a given maximum distance from a member and
  /// stores the result.
  ///
  /// See [georadiusbymember].
  ///
  /// See https://redis.io/commands/georadiusbymember
  Future<int?> georadiusbymemberStore(
      K key, V member, double radius, GeoUnit unit,
      {int? count, GeoOrder? order, K? storeKey, K? storeDistKey});
}

/// Metric units.
class GeoUnit {
  /// The name of the unit.
  final String name;

  const GeoUnit._(this.name);

  /// Meter.
  static const GeoUnit meter = GeoUnit._(r'm');

  /// Kilometer.
  static const GeoUnit kilometer = GeoUnit._(r'km');

  /// Mile.
  static const GeoUnit mile = GeoUnit._(r'mi');

  /// Feet.
  static const GeoUnit feet = GeoUnit._(r'ft');

  @override
  String toString() => 'GeoUnit: $name';
}

/// Orders.
class GeoOrder {
  /// The name of the order.
  final String name;

  const GeoOrder._(this.name);

  /// Ascending.
  static const GeoOrder ascending = GeoOrder._(r'ASC');

  /// Descending.
  static const GeoOrder descending = GeoOrder._(r'DESC');

  @override
  String toString() => 'GeoOrder: $name';
}

/// A geospatial position represented by its longitude and latitude.
class GeoPosition {
  /// The longitude.
  final double longitude;

  /// The latitude.
  final double latitude;

  /// Creates a [GeoPosition] instance.
  const GeoPosition(this.longitude, this.latitude);

  @override
  String toString() =>
      'GeoPosition: {longitude=$longitude, latitude=$latitude}';
}

/// A item to be added with the GEOADD command.
class GeoItem<V> {
  /// The position.
  final GeoPosition position;

  /// The member.
  final V member;

  /// Creates a [GeoItem] instance.
  const GeoItem(this.position, this.member);

  @override
  String toString() => 'GeoItem<$V>: {position=$position, member=$member}';
}

/// A result from the GEORADIUS command.
class GeoradiusResult<V> {
  /// The member.
  final V member;

  /// The distance.
  final double? distance;

  /// The hash.
  final int? hash;

  /// The position.
  final GeoPosition? position;

  /// Creates a [GeoradiusResult] instance.
  const GeoradiusResult(this.member, {this.distance, this.hash, this.position});

  @override
  String toString() => '''GeoradiusResult<$V>: {member=$member,'''
      ''' distance=$distance, hash=$hash, position=$position}''';
}

/// A mapper to be used with the GEOPOS command.
class GeoPositionMapper implements Mapper<List<GeoPosition?>> {
  /// Creates a [GeoPositionMapper] instance.
  const GeoPositionMapper();

  @override
  List<GeoPosition?> map(covariant ArrayReply reply, RedisCodec codec) => reply
      .array
      .map((value) =>
          value is NullReply ? null : _mapPosition(value as ArrayReply, codec))
      .toList();

  /// Maps a [reply] to `null` or a [GeoPosition] instance.
  GeoPosition _mapPosition(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final longitude = codec.decode<double>(array[0]);
    final latitude = codec.decode<double>(array[1]);

    return GeoPosition(longitude, latitude);
  }
}

/// A mapper to be used with the GEORADIUS family commands.
class GeoRadiusMapper<V> implements Mapper<List<GeoradiusResult<V>>> {
  /// Return the distance of the returned items from the specified center.
  final bool withCoord;

  /// Return the longitude,latitude coordinates of the returned items.
  final bool withDist;

  /// Return the raw geohash-encoded sorted set score of the returned items.
  final bool withHash;

  /// Creates a [GeoRadiusMapper] instance.
  const GeoRadiusMapper(
      {this.withCoord = false, this.withDist = false, this.withHash = false});

  @override
  List<GeoradiusResult<V>> map(covariant ArrayReply reply, RedisCodec codec) {
    final results = <GeoradiusResult<V>>[];

    for (final reply in reply.array) {
      if (withCoord || withDist || withHash) {
        final result = _mapResult(reply as ArrayReply, codec);
        results.add(result);
      } else {
        final member = codec.decode<V>(reply);
        results.add(GeoradiusResult<V>(member));
      }
    }

    return results;
  }

  /// Maps a [reply] to a [GeoradiusResult] instance.
  GeoradiusResult<V> _mapResult(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;
    var index = 0;

    final member = codec.decode<V>(array[index++]);

    double? distance;
    if (withDist) {
      distance = codec.decode<double>(array[index++]);
    }

    int? hash;
    if (withHash) {
      hash = codec.decode<int>(array[index++]);
    }

    GeoPosition? position;
    if (withCoord) {
      position = _mapPosition(array[index++] as ArrayReply, codec);
    }

    return GeoradiusResult<V>(member!,
        distance: distance, hash: hash, position: position);
  }

  /// Maps a [reply] to a [GeoPosition] instance.
  GeoPosition _mapPosition(ArrayReply reply, RedisCodec codec) {
    final longitude = codec.decode<double>(reply.array[0]);
    final latitude = codec.decode<double>(reply.array[1]);

    return GeoPosition(longitude, latitude);
  }
}

/// A mapper to be used with the GEORADIUS family commands.
class GeoRadiusStoreMapper implements Mapper<int> {
  /// Creates a [GeoRadiusStoreMapper] instance.
  const GeoRadiusStoreMapper();

  @override
  int map(Reply reply, RedisCodec codec) {
    if (reply is ArrayReply) {
      return 0;
    }

    return codec.decode<int>(reply);
  }
}
