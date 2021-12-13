// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

/// Base class for implementing exceptions.
class RedisException implements Exception {
  /// An informative message.
  final String? message;

  /// Creates an [RedisException] instance with an informative [message].
  const RedisException(this.message);

  @override
  String toString() => 'RedisException: $message';
}

/// Exception thrown if there was an attempt to send a command after the
/// connection was closed.
class RedisConnectionClosedException extends RedisException {
  /// Creates a [RedisConnectionClosedException] instance.
  const RedisConnectionClosedException()
      : super('Attempted to send data after connection was closed.');
}
