// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import '../command.dart';
import '../protocol.dart';

/// Redis sets commands.
abstract class SetCommands<K, V> {
  /// Adds the specified members to the set stored at [key].
  ///
  /// Returns the number of elements that were added to the set.
  ///
  /// See https://redis.io/commands/sadd
  Future<int> sadd(K key, {V? member, Iterable<V> members = const []});

  /// Returns the set cardinality (number of elements) of the set stored
  /// at [key].
  ///
  /// See https://redis.io/commands/scard
  Future<int> scard(K key);

  /// Returns the members of the set resulting from the difference between
  /// the first set and all the successive sets.
  ///
  /// See https://redis.io/commands/sdiff
  Future<List<V>> sdiff(K key, {Iterable<K> keys = const []});

  /// Subtracts multiple sets and store the resulting set in a key.
  ///
  /// Returns the number of elements in the resulting set.
  ///
  /// See https://redis.io/commands/sdiffstore
  Future<int> sdiffstore(K destination, K key, {Iterable<K> keys = const []});

  /// Returns the members of the set resulting from the intersection of all
  /// the given sets.
  ///
  /// See https://redis.io/commands/sinter
  Future<List<V>> sinter(K key, {Iterable<K> keys = const []});

  /// Intersects multiple sets and store the resulting set in a key.
  ///
  /// Returns the number of elements in the resulting set.
  ///
  /// See https://redis.io/commands/sinterstore
  Future<int> sinterstore(K destination, K key, {Iterable<K> keys = const []});

  /// Determines if a given value is a member of a set.
  ///
  /// Returns `1` if the element is a member of the set, `0` if the element
  /// is not a member of the set, or if key does not exist.
  ///
  /// See https://redis.io/commands/sismember
  Future<int> sismember(K key, V member);

  /// Returns all the members of the set value stored at [key].
  ///
  /// See https://redis.io/commands/smembers
  Future<List<V>> smembers(K key);

  /// Moves [member] from the set at [source] to the set at [destination].
  ///
  /// Returns `1` if the element is moved, `0` if the element is not a
  /// member of [source] and no operation was performed.
  ///
  /// See https://redis.io/commands/smove
  Future<int> smove(K source, K destination, V member);

  /// Removes and returns one random element from the set value stored at [key].
  ///
  /// See [spopCount].
  ///
  /// See https://redis.io/commands/spop
  Future<V?> spop(K key);

  /// Removes and returns [count] random elements from the set value
  /// stored at [key].
  ///
  /// See [spop].
  ///
  /// See https://redis.io/commands/spop
  Future<List<V>> spopCount(K key, int count);

  /// Returns one random members from a set.
  ///
  /// See [srandmemberCount].
  ///
  /// See https://redis.io/commands/srandmember
  Future<V?> srandmember(K key);

  /// Returns one random members from a set.
  ///
  /// See [srandmember].
  ///
  /// See https://redis.io/commands/srandmember
  Future<List<V>> srandmemberCount(K key, int count);

  /// Removes one or more members from a set.
  ///
  /// Returns the number of members that were removed from the set.
  ///
  /// See https://redis.io/commands/srem
  Future<int> srem(K key, {V? member, Iterable<V> members = const []});

  /// Incrementally iterates the members of a set stored at [key].
  ///
  /// See https://redis.io/commands/sscan
  Future<SetScanResult<V>> sscan(K key, int cursor, {K? pattern, int? count});

  /// Returns the members of the set resulting from the union of all the
  /// given sets.
  ///
  /// See https://redis.io/commands/sunion
  Future<List<V>> sunion(K key, {Iterable<K> keys = const []});

  /// Adds multiple sets and stores the resulting set in a key.
  ///
  /// See https://redis.io/commands/sunionstore
  Future<int> sunionstore(K destination, K key, {Iterable<K> keys = const []});
}

/// Result of the SSCAN command.
class SetScanResult<V> {
  /// The cursor.
  final int? cursor;

  /// The members.
  final List<V>? members;

  /// Creates a [SetScanResult] instance.
  const SetScanResult(this.cursor, this.members);

  @override
  String toString() => 'SetScanResult<$V>: {cursor=$cursor, members=$members}';
}

/// A mapper for the SSCAN command.
class SetScanMapper<V> implements Mapper<SetScanResult<V>> {
  @override
  SetScanResult<V> map(covariant ArrayReply reply, RedisCodec codec) {
    final cursor = codec.decode<int>(reply.array![0]);
    final members = codec.decode<List<V>>(reply.array![1]);

    return SetScanResult<V>(cursor, members);
  }
}
