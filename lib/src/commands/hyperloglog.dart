// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

/// Redis HyperLogLogs commands.
abstract class HyperLogLogCommands<K, V> {
  /// Adds the specified elements to the specified HyperLogLog.
  ///
  /// Returns `1` if at least one HyperLogLog internal register was
  /// altered, `0` otherwise.
  ///
  /// See https://redis.io/commands/pfadd
  Future<int?> pfadd(K key, {V? element, Iterable<V> elements = const []});

  /// Returns the approximated cardinality of the set(s) observed by the
  /// HyperLogLog at key(s).
  ///
  /// See https://redis.io/commands/pfcount
  Future<int?> pfcount({K? key, Iterable<K> keys = const []});

  /// Merges multiple HyperLogLog values into a single one.
  ///
  /// See https://redis.io/commands/pfmerge
  Future<void> pfmerge(K destkey,
      {K? sourcekey, Iterable<K> sourcekeys = const []});
}
