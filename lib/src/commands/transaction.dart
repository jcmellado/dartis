// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

/// Redis transactions commands.
abstract class TransactionCommands<K> {
  /// Discards all commands issued after MULTI.
  ///
  /// See https://redis.io/commands/discard
  Future<void> discard();

  /// Executes all commands issued after MULTI.
  ///
  /// https://redis.io/commands/exec
  Future<void> exec();

  /// Marks the start of a transaction block.
  ///
  /// See https://redis.io/commands/multi
  Future<void> multi();

  /// Flushes all the previously watched keys for a transaction.
  ///
  /// See https://redis.io/commands/unwatch
  Future<void> unwatch();

  /// Marks the given keys to be watched for conditional execution of a
  /// transaction.
  ///
  /// See https://redis.io/commands/watch
  Future<void> watch({K? key, Iterable<K> keys = const []});
}
