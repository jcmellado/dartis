// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

/// A convenient constant for null replies.
const NullReply nullReply = NullReply();

/// RESP (REdis Serialization Protocol) reply.
abstract class Reply {
  /// Returns the raw content of this reply.
  Object? get value;
}

/// Base class for implementing replies.
abstract class SingleReply implements Reply {
  /// The raw content.
  final List<int> bytes;

  /// Creates a [SingleReply] instance.
  const SingleReply(this.bytes);

  @override
  Object? get value => bytes;
}

/// A convenient abstraction for null replies.
class NullReply extends SingleReply {
  /// Creates a [NullReply] instance.
  const NullReply() : super(const []);

  @override
  Object? get value => null;

  @override
  String toString() => 'NullReply: null';
}

/// RESP simple string.
class StringReply extends SingleReply {
  /// Creates a [StringReply] instance.
  const StringReply(super.bytes);

  @override
  String toString() => 'StringReply: "${String.fromCharCodes(bytes)}"';
}

/// RESP integer.
class IntReply extends SingleReply {
  /// Creates an [IntReply] instance.
  const IntReply(super.bytes);

  @override
  String toString() => 'IntReply: ${int.parse(String.fromCharCodes(bytes))}';
}

/// RESP bulk string.
class BulkReply extends SingleReply {
  /// Creates a [BulkReply] instance.
  const BulkReply(super.bytes);

  @override
  String toString() => 'BulkReply: $bytes';
}

/// RESP array.
class ArrayReply implements Reply {
  /// The array of replies.
  final List<Reply> array;

  /// Creates an [ArrayReply] instance.
  const ArrayReply(this.array);

  @override
  Object get value => array;

  @override
  String toString() => 'ArrayReply: $array';
}

/// RESP error.
class ErrorReply extends SingleReply {
  /// Creates an [ErrorReply] instance.
  const ErrorReply(super.bytes);

  @override
  String toString() => 'ErrorReply: "${String.fromCharCodes(bytes)}"';
}
