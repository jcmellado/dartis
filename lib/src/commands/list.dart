// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import '../command.dart';
import '../protocol.dart';

/// Redis lists commands.
abstract class ListCommands<K, V> {
  /// Removes and gets the first element in a list, or blocks until one is
  /// available.
  ///
  /// See https://redis.io/commands/blpop
  Future<ListPopResult<K, V>?> blpop(
      {K? key, Iterable<K> keys = const [], int timeout = 0});

  /// Removes and gets the last element in a list, or blocks until one is
  /// available.
  ///
  /// See https://redis.io/commands/brpop.
  Future<ListPopResult<K, V>?> brpop(
      {K? key, Iterable<K> keys = const [], int timeout = 0});

  /// Pops a value from a list, push it to another list and return it; or
  /// blocks until one is available.
  ///
  /// Returns the element being popped from [source] and pushed to
  /// [destination], `null` if the [timeout] is reached.
  ///
  /// See https://redis.io/commands/brpoplpush
  Future<V> brpoplpush(K source, K destination, {int timeout = 0});

  /// Returns the element at index [index] in the list stored at [key].
  ///
  /// See https://redis.io/commands/lindex
  Future<V?> lindex(K key, int index);

  /// Inserts [value] in the list stored at [key] either before or after the
  /// reference value [pivot].
  ///
  /// Returns the length of the list after the insert operation, `-1` when
  /// the value [pivot] was not found.
  ///
  /// See https://redis.io/commands/linsert
  Future<int> linsert(K key, InsertPosition position, V pivot, V value);

  /// Returns the length of the list stored at [key].
  ///
  /// See https://redis.io/commands/llen
  Future<int> llen(K key);

  /// Removes and returns the first element of the list stored at [key].
  ///
  /// See https://redis.io/commands/lpop
  Future<V?> lpop(K key);

  /// Inserts all the specified values at the head of the list stored at [key].
  ///
  /// Returns the length of the list after the push operations.
  ///
  /// See https://redis.io/commands/lpush
  Future<int> lpush(K key, {V? value, Iterable<V> values = const []});

  /// Inserts [value] at the head of the list stored at [key], only if [key]
  /// already exists and holds a list.
  ///
  /// Returns the length of the list after the push operation.
  ///
  /// See https://redis.io/commands/lpushx
  Future<int> lpushx(K key, V value);

  /// Returns the specified elements of the list stored at [key].
  ///
  /// See https://redis.io/commands/lrange
  Future<List<V>> lrange(K key, int start, int stop);

  /// Removes the first [count] occurrences of elements equal to [value] from
  /// the list stored at [key].
  ///
  /// Returns the number of removed elements.
  ///
  /// See https://redis.io/commands/lrem
  Future<int> lrem(K key, int count, V value);

  /// Sets to [value] the element at index [index] of the list stored at [key].
  ///
  /// See https://redis.io/commands/lset
  Future<void> lset(K key, int index, V value);

  /// Trims an existing list so that it will contain only the specified range
  /// of elements specified.
  ///
  /// See https://redis.io/commands/ltrim
  Future<void> ltrim(K key, int start, int stop);

  /// Removes and returns the last element of the list stored at [key].
  ///
  /// See https://redis.io/commands/rpop
  Future<V?> rpop(K key);

  /// Removes the last element in a list stored at [source], prepends it
  /// to another list stored at [destination] and returns it.
  ///
  /// See https://redis.io/commands/rpoplpush
  Future<V?> rpoplpush(K source, K destination);

  /// Appends one or multiple values to a list stored at [key].
  ///
  /// Returns the length of the list after the push operation.
  ///
  /// See https://redis.io/commands/rpush
  Future<int> rpush(K key, {V? value, Iterable<V> values = const []});

  /// Appends a value to a list stored at [key], only if the list exists.
  ///
  /// Returns the length of the list after the push operation.
  ///
  /// See https://redis.io/commands/rpushx
  Future<int> rpushx(K key, V value);
}

/// Positions allowed for the LINSERT command.
class InsertPosition {
  /// The name of the position.
  final String name;

  const InsertPosition._(this.name);

  /// Before.
  static const InsertPosition before = InsertPosition._(r'BEFORE');

  /// After.
  static const InsertPosition after = InsertPosition._(r'AFTER');

  @override
  String toString() => 'InsertPosition: $name';
}

/// Result of the BLPOP and BRPOP commands.
class ListPopResult<K, V> {
  /// The key.
  final K key;

  /// The value.
  final V value;

  /// Creates a [ListPopResult] instance.
  const ListPopResult(this.key, this.value);

  @override
  String toString() => 'ListPopResult<$K, $V>: {key=$key, value=$value}';
}

/// A mapper for the BLPOP and BRPOP commands.
class ListPopResultMapper<K, V> implements Mapper<ListPopResult<K?, V?>?> {
  @override
  ListPopResult<K?, V?>? map(covariant ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    if (array.isEmpty) {
      return null;
    }

    final key = codec.decode<K>(array[0]);
    final value = codec.decode<V>(array[1]);

    return ListPopResult<K?, V?>(key, value);
  }
}

/// A mapper for the BRPOPLPUSH command.
class BrpoplpushMapper<V> implements Mapper<V?> {
  @override
  V? map(Reply reply, RedisCodec codec) {
    // BRPOPLPUSH returns a null [ArrayReply] instead of a null [BulkReply].
    if (reply is ArrayReply) {
      return null;
    }

    return codec.decode<V>(reply);
  }
}
