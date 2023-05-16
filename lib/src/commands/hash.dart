// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:collection' show LinkedHashMap;

import '../command.dart';
import '../protocol.dart';

/// Redis hashes commands.
abstract class HashCommands<K, V> {
  /// Removes one or more hash fields stored at [key].
  ///
  /// Returns the number of fields that were removed from the hash.
  ///
  /// See https://redis.io/commands/hdel
  Future<int?> hdel(K key, {K? field, Iterable<K> fields = const []});

  /// Ckecks if [field] is an existing field in the hash stored at [key].
  ///
  /// Returns `1` if the hash contains [field], `0` if the hash does not
  /// contain [field] or [key] does not exist.
  ///
  /// See https://redis.io/commands/hexists
  Future<int?> hexists(K key, K field);

  /// Returns the value associated with [field] in the hash stored at [key].
  ///
  /// See https://redis.io/commands/hget
  Future<V?> hget(K key, K field);

  /// Returns all fields and values of the hash stored at [key].
  ///
  /// See https://redis.io/commands/hgetall
  Future<Map<K, V?>?> hgetall(K key);

  /// Increments the number stored at [field] in the hash stored at [key]
  /// by [increment].
  ///
  /// Returns the value at [field] after the increment operation.
  ///
  /// See https://redis.io/commands/hincrby
  Future<int?> hincrby(K key, K field, int increment);

  /// Increments the specified [field] of a hash stored at [key], and
  /// representing a floating point number, by the specified [increment].
  ///
  /// Returns the value at [field] after the increment operation.
  ///
  /// See https://redis.io/commands/hincrbyfloat
  Future<double?> hincrbyfloat(K key, K field, double increment);

  /// Returns all field names in the hash stored at [key].
  ///
  /// See https://redis.io/commands/hkeys
  Future<List<K>?> hkeys(K key);

  /// Returns the number of fields contained in the hash stored at [key].
  ///
  /// See https://redis.io/commands/hlen
  Future<int?> hlen(K key);

  /// Returns the values associated with the specified fields in the hash
  /// stored at [key].
  ///
  /// See https://redis.io/commands/hmget
  Future<List<V?>> hmget(K key, {K? field, Iterable<K> fields = const []});

  /// Sets the specified fields to their respective values in the hash
  /// stored at [key].
  ///
  /// See https://redis.io/commands/hmset
  Future<void> hmset(K key, {K? field, V? value, Map<K, V?> hash = const {}});

  /// Incrementally iterates fields and values of a hash stored at [key].
  ///
  /// See https://redis.io/commands/hscan
  Future<HashScanResult<K, V?>?> hscan(K key, int cursor,
      {K? pattern, int? count});

  /// Sets [field] in the hash stored at [key] to [value].
  ///
  /// Returns `1` if [field] is a new field in the hash and [value] was set,
  /// `0` if [field] already exists in the hash and the value was updated.
  ///
  /// See https://redis.io/commands/hset
  Future<int?> hset(K key, K field, V? value);

  /// Sets [field] in the hash stored at [key] to [value], only if [field]
  /// does not yet exist.
  ///
  /// Returns `1` if [field] is a new field in the hash and [value] was set,
  /// `0` if [field] already exists in the hash and no operation was performed.
  ///
  /// See https://redis.io/commands/hsetnx
  Future<int?> hsetnx(K key, K field, V? value);

  /// Returns the string length of the value associated with [field] in the
  /// hash stored at [key].
  ///
  /// See https://redis.io/commands/hstrlen
  Future<int?> hstrlen(K key, K field);

  /// Returns all values in the hash stored at [key].
  ///
  /// See https://redis.io/commands/hvals
  Future<List<V?>?> hvals(K key);
}

/// Result of the HSCAN command.
class HashScanResult<K, V> {
  /// The cursor.
  final int cursor;

  /// The fields.
  final Map<K, V?> fields;

  /// Creates a [HashScanResult] instance.
  const HashScanResult(this.cursor, this.fields);

  @override
  String toString() =>
      'HashScanResult<$K, $V>: {cursor=$cursor, fields=$fields}';
}

/// A mapper for the HSCAN command.
class HashScanMapper<K, V> implements Mapper<HashScanResult<K, V?>> {
  @override
  HashScanResult<K, V?> map(covariant ArrayReply reply, RedisCodec codec) {
    final cursor = codec.decode<int>(reply.array[0]);
    final fields = _mapHash(reply.array[1] as ArrayReply, codec);

    return HashScanResult<K, V>(cursor, fields);
  }

  /// Maps a [reply] to a [Map] instance.
  Map<K, V> _mapHash(ArrayReply reply, RedisCodec codec) {
    // ignore: prefer_collection_literals
    final hash = LinkedHashMap<K, V>();

    final array = reply.array;
    for (var i = 0; i < array.length; i += 2) {
      final key = codec.decode<K>(array[i]);
      final value = codec.decode<V>(array[i + 1]);

      hash[key] = value;
    }

    return hash;
  }
}

/// A mapper for the HGETALL command.
class HashMapper<K, V> implements Mapper<Map<K, V?>> {
  @override
  Map<K, V?> map(covariant ArrayReply reply, RedisCodec codec) {
    // ignore: prefer_collection_literals
    final hash = LinkedHashMap<K, V?>();

    final array = reply.array;
    for (var i = 0; i < array.length; i += 2) {
      final key = codec.decode<K>(array[i]);
      final value = codec.decode<V>(array[i + 1]);

      hash[key!] = value;
    }

    return hash;
  }
}
