// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:collection' show LinkedHashMap;

import '../command.dart';
import '../protocol.dart';

/// Redis sorted sets commands.
abstract class SortedSetCommands<K, V> {
  /// Removes and returns the member with the highest score from one or more
  /// sorted sets, or blocks until one is available.
  ///
  /// See https://redis.io/commands/bzpopmax
  Future<SortedSetPopResult<K, V>?> bzpopmax(
      {K? key, Iterable<K> keys = const [], int timeout = 0});

  /// Removes and returns the member with the lowest score from one or more
  /// sorted sets, or blocks until one is available.
  ///
  /// See https://redis.io/commands/bzpopmin
  Future<SortedSetPopResult<K, V>?> bzpopmin(
      {K? key, Iterable<K> keys = const [], int timeout = 0});

  /// Adds one or more members to a sorted set, or updates its score if it
  /// already exists.
  ///
  /// Returns the number of elements added to the sorted sets.
  ///
  /// See [zaddIncr].
  ///
  /// See https://redis.io/commands/zadd
  Future<int> zadd(K key,
      {SortedSetExistMode? mode,
      bool changed = false,
      double? score,
      V? member,
      Map<V, double> set = const {}});

  /// Increments the score of a member of a sorted set.
  ///
  /// Returns the new score of the member.
  ///
  /// See [zadd] and [zincrby].
  ///
  /// See https://redis.io/commands/zadd
  Future<double?> zaddIncr(K key, double score, V member,
      {SortedSetExistMode? mode});

  /// Returns the cardinality (number of elements) of the sorted set stored
  /// at [key].
  ///
  /// See https://redis.io/commands/zcard
  Future<int> zcard(K key);

  /// Returns the number of elements in the sorted set at [key] with a
  /// score between [min] and [max].
  ///
  /// See https://redis.io/commands/zcount
  Future<int> zcount(K key, String min, String max);

  /// Increments the score of [member] in the sorted set stored at [key]
  /// by [increment].
  ///
  /// Returns the new score of [member].
  ///
  /// See https://redis.io/commands/zincrby
  Future<double> zincrby(K key, double increment, V member);

  /// Computes the intersection of numkeys sorted sets given by the
  /// specified keys, and stores the result in [destination].
  ///
  /// Returns the number of elements in the resulting sorted set
  /// at [destination].
  ///
  /// See https://redis.io/commands/zinterstore
  Future<int> zinterstore(K destination, List<K> keys,
      {Iterable<double> weights = const [], AggregateMode? mode});

  /// Counts the number of members in a sorted set between a given
  /// lexicographical range.
  ///
  /// Returns the number of elements in the specified score range.
  ///
  /// See https://redis.io/commands/zlexcount
  Future<int> zlexcount(K key, V min, V max);

  /// Removes and returns up to [count] members with the highest scores in
  /// the sorted set stored at [key].
  ///
  /// Returns the list of popped scores and elements.
  ///
  /// See https://redis.io/commands/zpopmax
  Future<Map<V, double?>?> zpopmax(K key, {int? count});

  /// Removes and returns up to [count] members with the lowest scores in
  /// the sorted set stored at [key].
  ///
  /// Returns the list of popped scores and elements.
  ///
  /// See https://redis.io/commands/zpopmin
  Future<Map<V, double?>?> zpopmin(K key, {int? count});

  /// Returns the specified range of elements in the sorted set stored at [key].
  ///
  /// See https://redis.io/commands/zrange
  Future<Map<V, double?>?> zrange(K key, int start, int stop,
      {bool withScores = false});

  /// Returns a range of members in a sorted set, by lexicographical range.
  ///
  /// See https://redis.io/commands/zrangebylex
  Future<List<V>> zrangebylex(K key, V min, V max, {int? offset, int? count});

  /// Returns a range of members in a sorted set, by score.
  ///
  /// See https://redis.io/commands/zrangebyscore
  Future<Map<V, double?>?> zrangebyscore(K key, String min, String max,
      {bool withScores = false, int? offset, int? count});

  /// Returns the rank of member in the sorted set stored at [key], with
  /// the scores ordered from low to high.
  ///
  /// See https://redis.io/commands/zrank
  Future<int?> zrank(K key, V member);

  /// Removes the specified members from the sorted set stored at [key].
  ///
  /// Returns the number of members removed from the sorted set.
  ///
  /// See https://redis.io/commands/zrem
  Future<int> zrem(K key, {V? member, Iterable<V> members = const []});

  /// Removes all members in a sorted set between the given lexicographical
  /// range.
  ///
  /// Returns the number of elements removed.
  ///
  /// See https://redis.io/commands/zremrangebylex
  Future<int> zremrangebylex(K key, V min, V max);

  /// Removes all members in a sorted set within the given indexes.
  ///
  /// Returns the number of elements removed.
  ///
  /// See https://redis.io/commands/zremrangebyrank
  Future<int> zremrangebyrank(K key, int start, int stop);

  /// Removes all members in a sorted set within the given scores.
  ///
  /// Returns the number of elements removed.
  ///
  /// See https://redis.io/commands/zremrangebyscore
  Future<int> zremrangebyscore(K key, String min, String max);

  /// Returns the specified range of elements in the sorted set stored at [key].
  ///
  /// See https://redis.io/commands/zrevrange
  Future<Map<V, double?>?> zrevrange(K key, int start, int stop,
      {bool withScores = false});

  /// Returns a range of members in a sorted set, by lexicographical range,
  /// ordered from higher to lower strings.
  ///
  /// See https://redis.io/commands/zrevrangebylex
  Future<List<V>> zrevrangebylex(K key, V max, V min,
      {int? offset, int? count});

  /// Returns a range of members in a sorted set, by score, with scores
  /// ordered from high to low.
  ///
  /// See https://redis.io/commands/zrevrangebyscore
  Future<Map<V, double?>?> zrevrangebyscore(K key, String max, String min,
      {bool withScores = false, int? offset, int? count});

  /// Returns the rank of member in the sorted set stored at [key], with
  /// the scores ordered from high to low.
  ///
  /// See https://redis.io/commands/zrevrank
  Future<int?> zrevrank(K key, V member);

  /// Incrementally iterates members and scores of a sorted set stored at [key].
  ///
  /// See https://redis.io/commands/zscan
  Future<SortedSetScanResult<K>> zscan(K key, int cursor,
      {K? pattern, int? count});

  /// Returns the score of [member] in the sorted set at [key].
  ///
  /// See https://redis.io/commands/zscore
  Future<double?> zscore(K key, V member);

  /// Adds multiple sorted sets and stores the resulting sorted set in a
  /// new key.
  ///
  /// Returns the number of elements in the resulting sorted set at destination.
  ///
  /// See https://redis.io/commands/zunionstore
  Future<int> zunionstore(K destination, List<K> keys,
      {Iterable<double> weights = const [], AggregateMode? mode});
}

/// Modes allowed for the ZADD command.
class SortedSetExistMode {
  /// The name of the mode.
  final String name;

  const SortedSetExistMode._(this.name);

  /// Only set the key if it does not already exist.
  static const SortedSetExistMode nx = SortedSetExistMode._(r'NX');

  /// Only set the key if it already exist.
  static const SortedSetExistMode xx = SortedSetExistMode._(r'XX');

  @override
  String toString() => 'SortedSetExistMode: $name';
}

/// Modes allowed for the ZINTERSTORE and ZUNIONSTORE commands.
class AggregateMode {
  /// The name of the mode.
  final String name;

  const AggregateMode._(this.name);

  /// The score of an element is summed across the inputs where it exists.
  static const AggregateMode sum = AggregateMode._(r'SUM');

  /// The resulting set will contain the minimum score of an element across
  /// the inputs where it exists.
  static const AggregateMode min = AggregateMode._(r'MIN');

  /// The resulting set will contain the maximum score of an element across
  /// the inputs where it exists.
  static const AggregateMode max = AggregateMode._(r'MAX');

  @override
  String toString() => 'AggregateMode: $name';
}

/// Result of the BZPOPMIN and BZPOPMAX commands.
class SortedSetPopResult<K, V> {
  /// The key.
  final K key;

  /// The member.
  final MapEntry<V, double?>? member;

  /// Creates a [SortedSetMapper] instance.
  const SortedSetPopResult(this.key, this.member);

  @override
  String toString() => 'SortedSetPopResult<$K, $V>: {key=$key member=$member}';
}

/// Result of the ZSCAN command.
class SortedSetScanResult<K> {
  /// The cursor.
  final int? cursor;

  /// The members with theirs scores.
  final Map<K?, double?>? members;

  /// Creates a [SortedSetScanResult] instance.
  const SortedSetScanResult(this.cursor, this.members);

  @override
  String toString() =>
      'SortedSetScanResult<$K>: {cursor=$cursor, members=$members}';
}

/// A mapper for the BZPOPMIN and BZPOPMAX commands.
class SortedSetPopResultMapper<K, V>
    implements Mapper<SortedSetPopResult<K, V>> {
  @override
  SortedSetPopResult<K, V> map(covariant ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final key = codec.decode<K>(array[0]);
    final value = codec.decode<V>(array[1]);
    final score = codec.decode<double>(array[2]);
    final member = MapEntry<V, double>(value, score);

    return SortedSetPopResult<K, V>(key, member);
  }
}

/// A mapper for the ZSCAN command.
class SortedSetScanMapper<K> implements Mapper<SortedSetScanResult<K>> {
  @override
  SortedSetScanResult<K> map(covariant ArrayReply reply, RedisCodec codec) {
    final cursor = codec.decode<int>(reply.array[0]);
    final members = _mapSet(reply.array[1] as ArrayReply, codec);

    return SortedSetScanResult<K>(cursor, members);
  }

  /// Maps a [reply] to a Map<K, double>.
  Map<K, double> _mapSet(ArrayReply reply, RedisCodec codec) {
    // ignore: prefer_collection_literals
    final set = LinkedHashMap<K, double>();

    final array = reply.array;
    for (var i = 0; i < array.length; i += 2) {
      final member = codec.decode<K>(array[i]);
      final score = codec.decode<double>(array[i + 1]);

      set[member] = score;
    }

    return set;
  }
}

/// A mapper to be used with some sorted set commands.
class SortedSetMapper<V> implements Mapper<Map<V, double?>> {
  /// Retrieves the scores.
  final bool withScores;

  /// Creates a [SortedSetMapper] instance.
  SortedSetMapper({this.withScores = false});

  @override
  Map<V, double?> map(covariant ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    // ignore: prefer_collection_literals
    final set = LinkedHashMap<V, double?>();

    final incr = withScores ? 2 : 1;

    for (var i = 0; i < array.length; i += incr) {
      final member = codec.decode<V>(array[i]);
      final score = withScores ? codec.decode<double>(array[i + 1]) : null;

      set[member] = score;
    }

    return set;
  }
}
