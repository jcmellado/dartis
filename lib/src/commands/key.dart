// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import '../command.dart';
import '../protocol.dart';

/// Redis keys commands.
abstract class KeyCommands<K, V> {
  /// Removes the specified keys.
  ///
  /// Returns the number of keys that were removed.
  ///
  /// See https://redis.io/commands/del
  Future<int> del({K? key, Iterable<K> keys = const []});

  /// Returns a serialized version of the value stored at [key] in a
  /// Redis-specific format.
  ///
  /// See https://redis.io/commands/dump
  Future<List<int>?> dump(K key);

  /// Determines if a set of keys exist.
  ///
  /// Returns the number of keys existing among the ones specified as arguments.
  ///
  /// See https://redis.io/commands/exists
  Future<int> exists({K? key, Iterable<K> keys = const []});

  /// Sets a [key]'s time to live in [seconds].
  ///
  /// Returns `1` if the timeout was set, `0` if [key] does not exist.
  ///
  /// See https://redis.io/commands/expire
  Future<int> expire(K key, int seconds);

  /// Sets the expiration for a [key] as a UNIX timestamp.
  ///
  /// Returns `1` if the timeout was set, `0` if [key] does not exist.
  ///
  /// See https://redis.io/commands/expireat
  Future<int> expireat(K key, int timestamp);

  /// Returns all keys matching [pattern].
  ///
  /// See https://redis.io/commands/keys
  Future<List<K>> keys(K pattern);

  /// Atomically transfers some keys from a source Redis instance to a
  /// destination Redis instance.
  ///
  /// Returns `OK` on success, `NOKEY` if no keys were found in the
  /// source instance.
  ///
  /// See https://redis.io/commands/migrate
  Future<String> migrate(String host, int port, int destinationDb, int timeout,
      {bool copy = false,
      bool replace = false,
      K? key,
      Iterable<K> keys = const []});

  /// Moves [key] from the currently selected database to the specified
  /// destination database.
  ///
  /// Returns `1` if [key] was moved, `0` if [key] was not moved.
  ///
  /// See https://redis.io/commands/move
  Future<int> move(K key, int db);

  /// Inspects the internals of the Redis Object associated with a [key].
  ///
  /// See [objectHelp].
  ///
  /// See https://redis.io/commands/object
  Future<String?> object(ObjectSubcommand subcommand, K key);

  /// Returns a succint help text for the OBJECT command.
  ///
  /// See [object].
  ///
  /// See https://redis.io/commands/object
  Future<List<String>> objectHelp();

  /// Removes the existing timeout on [key].
  ///
  /// Returns `1` if the timeout was removed, `0` if [key] does not exist
  /// or does not have an associated timeout.
  ///
  /// See https://redis.io/commands/persist
  Future<int> persist(K key);

  /// Sets a [key]'s time to live in milliseconds.
  ///
  /// Returns `1` if the timeout was set, `0` if [key] does not exist.
  ///
  /// See https://redis.io/commands/pexpire
  Future<int> pexpire(K key, int milliseconds);

  /// Sets the expiration for a [key] as a UNIX timestamp specified
  /// in milliseconds.
  ///
  /// Returns `1` if the timeout was set, `0` if [key] does not exist.
  ///
  /// See https://redis.io/commands/pexpireat
  Future<int> pexpireat(K key, int millisecondsTimestamp);

  /// Returns the time to live for a [key] in milliseconds.
  ///
  /// See https://redis.io/commands/pttl
  Future<int> pttl(K key);

  /// Returns a random key from the currently selected database.
  ///
  /// See https://redis.io/commands/randomkey
  Future<K> randomkey();

  /// Renames [key] to [newkey].
  ///
  /// See https://redis.io/commands/rename
  Future<void> rename(K key, K newkey);

  /// Renames [key] to [newkey] if [newkey] does not yet exist.
  ///
  /// Returns `1` if [key] was renamed to [newkey], `0` if [newkey]
  /// already exists.
  ///
  /// See https://redis.io/commands/renamenx
  Future<int> renamenx(K key, K newkey);

  /// Creates a [key] associated with a value that is obtained by
  /// deserializing the provided serialized value (obtained via [dump]).
  ///
  /// See https://redis.io/commands/restore
  Future<void> restore(K key, int ttl, List<int> serializedValue,
      {bool replace = false});

  /// Incrementally iterates the keys space.
  ///
  /// See https://redis.io/commands/scan
  Future<KeyScanResult<K>> scan(int cursor, {K? pattern, int? count});

  /// Sort the elements in a list, set or sorted set.
  ///
  /// Returns the sorted elements.
  ///
  /// See [sortStore].
  ///
  /// See https://redis.io/commands/sort
  Future<List<V?>> sort(K key,
      {K? by,
      int? offset,
      int? count,
      Iterable<K> get = const [],
      SortOrder? order,
      bool alpha = false});

  /// Sort the elements in a list, set or sorted set and stores the result
  /// at [destination].
  ///
  /// Returns the number of sorted elements in the destination list.
  ///
  /// See [sort].
  ///
  /// See https://redis.io/commands/sort
  Future<int> sortStore(K key, K destination,
      {K? by,
      int? offset,
      int? count,
      Iterable<K> get = const [],
      SortOrder? order,
      bool alpha = false});

  /// Alters the last access time of a key.
  ///
  /// Returns the number of keys that were touched.
  ///
  /// See https://redis.io/commands/touch
  Future<int> touch({K? key, Iterable<K> keys = const []});

  /// Returns the remaining time to live of a [key].
  ///
  /// See https://redis.io/commands/ttl
  Future<int> ttl(K key);

  /// Returns the string representation of the type of the value stored
  /// at [key].
  ///
  /// See https://redis.io/commands/type
  Future<String> type(K key);

  /// Removes the specified keys asynchronously in another thread.
  ///
  /// Returns the number of keys that were unlinked.
  ///
  /// See https://redis.io/commands/unlink
  Future<int> unlink({K? key, Iterable<K> keys = const []});

  /// Blocks the current client until all the previous write commands
  /// are successfully transferred and acknowledged by at least the
  /// specified number of slave.
  ///
  /// Returns the number of slaves reached by all the writes performed
  /// in the context of the current connection.
  ///
  /// See https://redis.io/commands/wait
  Future<int> wait(int numslaves, int timeout);
}

/// Orders.
class SortOrder {
  /// The name of the order.
  final String name;

  const SortOrder._(this.name);

  /// Ascending.
  static const SortOrder ascending = SortOrder._(r'ASC');

  /// Descending.
  static const SortOrder descending = SortOrder._(r'DESC');

  @override
  String toString() => 'SortOrder: $name';
}

/// Allowed subcommands for the OBJECT command.
class ObjectSubcommand {
  /// The name of the command.
  final String name;

  const ObjectSubcommand._(this.name);

  /// Returns the number of references of the value associated with the
  /// specified key.
  static const ObjectSubcommand refcount = ObjectSubcommand._(r'REFCOUNT');

  /// Returns the kind of internal representation used in order to store
  /// the value associated with a key.
  static const ObjectSubcommand encoding = ObjectSubcommand._(r'ENCODING');

  /// Returns the number of seconds since the object stored at the
  /// specified key is idle.
  static const ObjectSubcommand idletime = ObjectSubcommand._(r'IDLETIME');

  /// Returns the logarithmic access frequency counter of the object
  /// stored at the specified key.
  static const ObjectSubcommand freq = ObjectSubcommand._(r'FREQ');

  @override
  String toString() => 'ObjectSubcommand: $name';
}

/// Result of the SCAN command.
class KeyScanResult<K> {
  /// The cursor.
  final int? cursor;

  /// The keys.
  final List<K>? keys;

  /// Creates a [KeyScanResult] instance.
  const KeyScanResult(this.cursor, this.keys);

  @override
  String toString() => 'KeyScanResult<$K>: {cursor=$cursor, keys=$keys}';
}

/// A mapper for the SCAN command.
class KeyScanMapper<K> implements Mapper<KeyScanResult<K>> {
  @override
  KeyScanResult<K> map(covariant ArrayReply reply, RedisCodec codec) {
    final cursor = codec.decode<int>(reply.array![0]);
    final keys = codec.decode<List<K>>(reply.array![1]);

    return KeyScanResult<K>(cursor, keys);
  }
}
