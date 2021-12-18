// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

/// Redis connection commands.
abstract class ConnectionCommands {
  /// Requests for authentication in a password-protected Redis server.
  ///
  /// See https://redis.io/commands/auth
  Future<void> auth(String password);

  /// Returns [message].
  ///
  /// See https://redis.io/commands/echo
  Future<String?> echo(String message);

  /// Returns `PONG` if no [message] is provided, otherwise returns a copy
  /// of the [message].
  ///
  /// See https://redis.io/commands/ping
  Future<String?> ping([String? message]);

  /// Closes the connection.
  ///
  /// See https://redis.io/commands/quit
  Future<void> quit();

  /// Changes the selected database for the current connection.
  ///
  /// See https://redis.io/commands/select
  Future<void> select(int index);

  /// Swaps two Redis databases.
  ///
  /// See https://redis.io/commands/swapdb
  Future<void> swapdb(int index1, int index2);
}
