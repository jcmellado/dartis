// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import '../command.dart';

/// Redis scripting commands.
abstract class ScriptingCommands<K> {
  /// Executes a Lua [script] in the server.
  ///
  /// Returns the result of the script as an object of type [T].
  ///
  /// An optional [mapper] can be provided to convert the result in an
  /// object of type [T].
  ///
  /// See https://redis.io/commands/eval
  Future<T> eval<T>(String script,
      {Iterable<K> keys = const [],
      Iterable<Object> args = const [],
      Mapper<T>? mapper});

  /// Evaluates a script cached on the server side by its SHA1 digest.
  ///
  /// See [eval].
  ///
  /// See https://redis.io/commands/evalsha
  Future<T> evalsha<T>(String sha1,
      {Iterable<K> keys = const [],
      Iterable<Object> args = const [],
      Mapper<T>? mapper});

  /// Sets the debug [mode] for subsequent scripts executed with [eval].
  ///
  /// See https://redis.io/commands/script-debug
  Future<void> scriptDebug(ScriptDebugMode mode);

  /// Accepts one or more SHA1 digests and returns a list of ones or zeros to
  /// signal if the scripts are already defined or not inside the script cache.
  ///
  /// See https://redis.io/commands/script-exists
  Future<List<int>> scriptExists(
      {String? sha1, Iterable<String> sha1s = const []});

  /// Flushes the Lua scripts cache.
  ///
  /// See https://redis.io/commands/script-flush
  Future<void> scriptFlush();

  /// Kills the currently executing Lua script,
  ///
  /// See https://redis.io/commands/script-kill
  Future<void> scriptKill();

  /// Loads a [script] into the scripts cache, without executing it.
  ///
  /// Returns the SHA1 digest of the script added into the script cache.
  ///
  /// See https://redis.io/commands/script-load
  Future<String> scriptLoad(String script);
}

/// Modes allowed for the SCRIPT DEBUG command.
class ScriptDebugMode {
  /// The name of the mode.
  final String name;

  const ScriptDebugMode._(this.name);

  /// Enables non-blocking asynchronous debugging of Lua scripts
  /// (changes are discarded).
  static const ScriptDebugMode yes = ScriptDebugMode._(r'YES');

  /// Enables blocking synchronous debugging of Lua scripts
  /// (saves changes to data).
  static const ScriptDebugMode sync = ScriptDebugMode._(r'SYNC');

  /// Disables scripts debug mode.
  static const ScriptDebugMode no = ScriptDebugMode._(r'NO');

  @override
  String toString() => 'ScriptDebugMode: $name';
}
