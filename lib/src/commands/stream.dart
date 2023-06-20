// Copyright (c) 2020-Present, Juan Mellado. All rights reserved. Use of this
// source is governed by a MIT-style license found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:collection' show LinkedHashMap;

import '../command.dart';
import '../exception.dart';
import '../protocol.dart';

/// A convenient shared mapper for the XGROUP command.
const StreamGroupMapper streamGroupMapper = StreamGroupMapper();

/// Redis streams commands.
abstract class StreamCommands<K, V> {
  /// Removes one or multiple messages from the pending entries list (PEL),
  /// that is the list of message IDs delivered but not yet acknowledged.
  /// Messages are removed for a consumer [group] of a stream at [key].
  ///
  /// Returns the number of messages successfully acknowledged.
  ///
  /// See https://redis.io/commands/xack
  Future<int> xack(K key, K group, {K? id, Iterable<K> ids = const []});

  /// Appends one or multiple entries to a stream at [key]. When the
  /// [roughly] option modifier is used the resulting stream length could
  /// be a few tens of entries more, but never less than [maxlen] items.
  ///
  /// Returns the ID of the added entry.
  ///
  /// See https://redis.io/commands/xadd
  Future<K> xadd(K key,
      {K? id,
      K? field,
      V? value,
      Map<K, V> fields = const {},
      int? maxlen,
      bool roughly = false});

  /// Changes the ownership of some pending messages for a consumer group, so
  /// that the new owner will be the specified [consumer]. A message is
  /// claimed only if its idle time is greater than [minIdleTime].
  ///
  /// Returns the claimed messages or just the IDs if [justId] is specified.
  ///
  /// See https://redis.io/commands/xclaim
  Future<Object> xclaim(K key, K group, K consumer, int minIdleTime,
      {K? id,
      Iterable<K> ids = const [],
      int? idle,
      int? idleTimestamp,
      int? retryCount,
      bool force = false,
      bool justId = false});

  /// Removes the specified entries from a stream at [key].
  ///
  /// Returns the number of entries deleted.
  ///
  /// See https://redis.io/commands/xdel
  Future<int> xdel(K key, {K? id, Iterable<K> ids = const []});

  /// Manages the consumer groups associated with a stream. The [subcommand]
  /// specifies if the command must create a new consumer group, destroy an
  /// existing consumer group, remove a consumer from a consumer group, set
  /// the last delivered ID of a consumer group, or print the help.
  ///
  /// Returns `null` for the create and set ID subcommands, `1` or `0` for
  /// the delete group and delete consumer subcommands, and an array of strings
  /// for the help subcommand.
  ///
  /// See https://redis.io/commands/xgroup
  Future<Object?> xgroup(StreamGroupSubcommand subcommand,
      {K? key, K? group, K? id, K? consumer, bool mkstream = false});

  /// Returns general information about a stream. The [subcommand]
  /// specifies if the command must return information about the consumer
  /// groups of the stream, the consumers of a consumer group, or
  /// print the help.
  ///
  /// See https://redis.io/commands/xinfo
  Future<Object> xinfo(StreamInfoSubcommand subcommand, {K? key, K? group});

  /// Returns the number of entries inside a stream at [key].
  ///
  /// See https://redis.io/commands/xlen
  Future<int> xlen(K key);

  /// Inspects the pending entries list (PEL) of a stream at [key] for
  /// a consumer [group]. A range can be specified by a [start] and [end] ID,
  /// and a non optional [count] to reduce the number of entries reported.
  /// The result can be filtered by a [consumer].
  ///
  /// Returns a summary about the pending entries list or the pending entries
  /// if a range is specified.
  ///
  /// See https://redis.io/commands/xpending
  Future<Object> xpending(K key, K group,
      {K? start, K? end, int? count, K? consumer});

  /// Returns the entries of a stream at [key] matching a given range of IDs.
  /// The range is specified by a [start] and [end] ID. Use [count] to reduce
  /// the number of entries reported.
  ///
  /// See https://redis.io/commands/xrange
  Future<List<StreamEntry<K, V>?>> xrange(K key, K start, K end, {int? count});

  /// Reads data from one or multiple streams, only returning entries with an
  /// ID greater than the one reported by the caller. Use [count] to reduce
  /// the number of entries reported. Use [timeout] to wait a given
  /// number of milisecond before timing out if items are not available.
  ///
  /// Returns the stream entries or `null` on timeout.
  ///
  /// See https://redis.io/commands/xread
  Future<Map<K, List<StreamEntry<K, V>?>>?> xread(
      {K? key,
      K? id,
      Iterable<K> keys = const [],
      Iterable<K> ids = const [],
      int? count,
      int? timeout});

  /// Special version of the [xread] command with support for consumer groups.
  /// Reads data from one or multiple streams, only returning entries with an
  /// ID greater than the one reported by the caller. Use [count] to reduce
  /// the number of entries reported. Use [timeout] to wait a given
  /// number of milisecond before timing out if items are not available. Use
  /// [noack] to avoid adding the entries to the pending entries list (PEL).
  ///
  /// Returns the stream entries or `null` on timeout.
  ///
  /// See https://redis.io/commands/xreadgroup
  Future<Map<K, List<StreamEntry<K, V>?>>?> xreadgroup(K group, K consumer,
      {K? key,
      K? id,
      Iterable<K> keys = const [],
      Iterable<K> ids = const [],
      int? count,
      int? timeout,
      bool noack = false});

  /// Returns the entries of a stream at [key] matching a given range of IDs
  /// in reverse order. The range is specified by a [end] and [start] ID.
  /// Use [count] to reduce the number of entries reported.
  ///
  /// See https://redis.io/commands/xrevrange
  Future<List<StreamEntry<K, V>?>> xrevrange(K key, K end, K start,
      {int? count});

  /// Trims a stream at [key] to a given number [maxlen] of items. When the
  /// [roughly] option modifier is used the resulting length could be
  /// a few tens of entries more, but never less than [maxlen] items.
  ///
  /// Returns the number of entries deleted from the stream.
  ///
  /// See https://redis.io/commands/xtrim
  Future<int> xtrim(K key, int maxlen, {bool roughly = false});
}

/// Special IDs.
abstract class StreamId {
  /// Smallest ID possible (0-1).
  static const String min = r'-';

  /// Greatest ID possible (18446744073709551615-18446744073709551615).
  static const String max = r'+';

  /// Autogenerate ID.
  static const String auto = r'*';

  /// Last ID in a stream.
  static const String last = r'$';

  /// Last delivered ID of a consumer group.
  static const String lastDelivered = r'>';
}

/// Allowed subcommands for the XGROUP command.
class StreamGroupSubcommand {
  /// The name of the subcommand.
  final String name;

  const StreamGroupSubcommand._(this.name);

  /// Create a new consumer group.
  static const StreamGroupSubcommand create =
      StreamGroupSubcommand._(r'CREATE');

  /// Destroy a consumer group.
  static const StreamGroupSubcommand destroy =
      StreamGroupSubcommand._(r'DESTROY');

  /// Set the last delivered ID of a consumer group.
  static const StreamGroupSubcommand setId = StreamGroupSubcommand._(r'SETID');

  /// Remove a specific consumer from a consumer group.
  static const StreamGroupSubcommand deleteConsumer =
      StreamGroupSubcommand._(r'DELCONSUMER');

  /// Print the help.
  static const StreamGroupSubcommand help = StreamGroupSubcommand._(r'HELP');

  @override
  String toString() => 'StreamGroupSubcommand: $name';
}

/// Allowed subcommands for the XINFO command.
class StreamInfoSubcommand {
  /// The name of the subcommand.
  final String name;

  const StreamInfoSubcommand._(this.name);

  /// Return general information about a stream.
  static const StreamInfoSubcommand stream = StreamInfoSubcommand._(r'STREAM');

  /// Return all the consumer groups associated with a stream.
  static const StreamInfoSubcommand groups = StreamInfoSubcommand._(r'GROUPS');

  /// Return all the consumers of a consumer group.
  static const StreamInfoSubcommand consumers =
      StreamInfoSubcommand._(r'CONSUMERS');

  /// Print the help.
  static const StreamInfoSubcommand help = StreamInfoSubcommand._(r'HELP');

  @override
  String toString() => 'StreamInfoSubcommand: $name';
}

/// A stream entry.
class StreamEntry<K, V> {
  /// The entry ID.
  final K id;

  /// The entry fields.
  final Map<K, V>? fields;

  /// Creates a [StreamEntry] instance.
  const StreamEntry(this.id, this.fields);

  @override
  String toString() => '''StreamEntry<$K, $V>: {id=$id, fields=$fields}''';
}

/// A result of type summary for the XPENDING command.
class StreamPendingSummary<K, V> {
  /// The total number of pending messages for the consumer group.
  final int? pendingCount;

  /// The smallest ID among the pending messages.
  final K firstEntryId;

  /// The greatest ID among the pending messages.
  final K lastEntryId;

  /// The consumers in the consumer group with at least one pending message.
  final List<StreamPendingConsumer<K, V>> consumers;

  /// Creates a [StreamPendingSummary] instance.
  const StreamPendingSummary(
      this.pendingCount, this.firstEntryId, this.lastEntryId, this.consumers);

  @override
  String toString() =>
      '''StreamPendingSummary<$K, $V>: {pendingCount=$pendingCount,'''
      ''' firstEntryId=$firstEntryId, lastEntryId=$lastEntryId,'''
      ''' consumers=$consumers}''';
}

/// A consumer in a result of type summary for the XPENDING command.
class StreamPendingConsumer<K, V> {
  /// The name of the consumer.
  final K name;

  /// The number of pending message.
  final int? pendingCount;

  /// Creates a [StreamPendingConsumer] instance.
  const StreamPendingConsumer(this.name, this.pendingCount);

  @override
  String toString() => '''StreamPendingConsumer<$K, $V>: {name=$name,'''
      ''' pendingCount=$pendingCount}''';
}

/// A result of type stream entry for the XPENDING command.
class StreamPendingEntry<K, V> {
  /// The ID of the entry.
  final K id;

  /// The name of the consumer that fetched the entry and has still to
  /// acknowledge it.
  final K consumer;

  /// The number of milliseconds that elapsed since the last time this
  /// entry was delivered to this consumer.
  final int? deliveryTime;

  /// The number of times this message was delivered.
  final int? deliveredCount;

  /// Creates a [StreamPendingEntry] instance.
  const StreamPendingEntry(
      this.id, this.consumer, this.deliveryTime, this.deliveredCount);

  @override
  String toString() => '''StreamPendingEntry<$K, $V>: {id=$id,'''
      ''' consumer=$consumer, deliveryTime=$deliveryTime,'''
      ''' deliveredCount=$deliveredCount}''';
}

/// A mapper for the XCLAIM command.
abstract class StreamClaimMapper<K, V> implements Mapper<Object> {
  /// Creates a [StreamClaimMapper] instance.
  factory StreamClaimMapper({required bool justId}) =>
      justId ? StreamClaimIdMapper<K, V>() : StreamClaimStreamMapper<K, V>();
}

/// A mapper for the XCLAIM command.
class StreamClaimIdMapper<K, V> implements StreamClaimMapper<K, V> {
  @override
  List<K> map(covariant ArrayReply reply, RedisCodec codec) =>
      reply.array.map((entry) => codec.decode<K>(entry)).toList();
}

/// A mapper for the XCLAIM command.
class StreamClaimStreamMapper<K, V> implements StreamClaimMapper<K, V> {
  final _streamMapper = StreamMapper<K, V>();

  @override
  List<StreamEntry<K, V>> map(covariant ArrayReply reply, RedisCodec codec) =>
      _streamMapper.map(reply, codec);
}

/// A mapper for the XGROUP command.
class StreamGroupMapper implements Mapper<Object?> {
  /// Creates a [StreamGroupMapper] instance.
  const StreamGroupMapper();

  @override
  Object? map(Reply reply, RedisCodec codec) {
    if (reply is IntReply) {
      return codec.decode<int>(reply);
    }
    if (reply is ArrayReply) {
      return codec.decode<List<String>>(reply);
    }
    return null;
  }
}

/// A mapper for the XPENDING command.
abstract class StreamPendingMapper<K, V> implements Mapper<Object> {
  /// Creates a [StreamPendingMapper] instance.
  factory StreamPendingMapper({required bool justSummary}) => justSummary
      ? StreamPendingSummaryMapper<K, V>()
      : StreamPendingEntryMapper<K, V>();
}

/// A mapper for the XPENDING command.
class StreamPendingSummaryMapper<K, V> implements StreamPendingMapper<K, V> {
  @override
  StreamPendingSummary<K, V> map(covariant ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final pendingCount = codec.decode<int>(array[0]);
    final firstEntryId = codec.decode<K>(array[1]);
    final lastEntryId = codec.decode<K>(array[2]);
    final consumersReply = array[3];
    final consumers = consumersReply is NullReply
        ? <StreamPendingConsumer<K, V>>[]
        : _mapConsumers(consumersReply as ArrayReply, codec);

    return StreamPendingSummary<K, V>(
        pendingCount, firstEntryId, lastEntryId, consumers);
  }

  List<StreamPendingConsumer<K, V>> _mapConsumers(
      ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    return array
        .map((entry) => _mapConsumer(entry as ArrayReply, codec))
        .toList();
  }

  StreamPendingConsumer<K, V> _mapConsumer(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final name = codec.decode<K>(array[0]);
    final pendingCount = codec.decode<int>(array[1]);

    return StreamPendingConsumer<K, V>(name, pendingCount);
  }
}

/// A mapper for the XPENDING command.
class StreamPendingEntryMapper<K, V> implements StreamPendingMapper<K, V> {
  @override
  List<StreamPendingEntry<K, V>> map(
          covariant ArrayReply reply, RedisCodec codec) =>
      reply.array
          .map((entry) => _mapEntry(entry as ArrayReply, codec))
          .toList();

  StreamPendingEntry<K, V> _mapEntry(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final id = codec.decode<K>(array[0]);
    final consumer = codec.decode<K>(array[1]);
    final deliveryTime = codec.decode<int>(array[2]);
    final deliveredCount = codec.decode<int>(array[3]);

    return StreamPendingEntry<K, V>(id, consumer, deliveryTime, deliveredCount);
  }
}

/// A mapper for the XINFO command.
abstract class StreamInfoMapper<K, V> implements Mapper<Object> {
  /// Creates a [StreamInfoMapper] instance.
  factory StreamInfoMapper(StreamInfoSubcommand subcommand) {
    switch (subcommand) {
      case StreamInfoSubcommand.stream:
        return StreamInfoStreamsMapper<K, V>();
      case StreamInfoSubcommand.groups:
        return StreamInfoGroupsMapper<K, V>();
      case StreamInfoSubcommand.consumers:
        return StreamInfoConsumersMapper<K, V>();
      case StreamInfoSubcommand.help:
        return StreamInfoHelpMapper<K, V>();
      default:
        throw RedisException('Unexpected subcommand "$subcommand".');
    }
  }
}

/// A mapper for the XINFO command.
class StreamMapInfoMapper<K, V> implements StreamInfoMapper<K, V> {
  @override
  Object map(covariant ArrayReply reply, RedisCodec codec) {
    final hash = <String, Object?>{};

    final array = reply.array;
    for (var i = 0; i < array.length; i += 2) {
      final key = codec.decode<String>(array[i]);
      final value = array[i + 1];

      hash[key] = value is NullReply ? null : _mapValue(key, value, codec);
    }

    return hash;
  }

  Object? _mapValue(String? key, Reply value, RedisCodec codec) {
    if (value is ArrayReply) {
      return map(value, codec);
    }
    if (value is IntReply) {
      return codec.decode<int>(value);
    }
    return codec.decode<String>(value);
  }
}

/// A mapper for the XINFO command.
abstract class StreamListMapInfoMapper<K, V> extends StreamMapInfoMapper<K, V> {
  @override
  Object map(covariant ArrayReply reply, RedisCodec codec) => reply.array
      .map((entry) => super.map(entry as ArrayReply, codec))
      .toList();
}

/// A mapper to be used with the XINFO command and STREAMS subcommand.
class StreamInfoStreamsMapper<K, V> extends StreamMapInfoMapper<K, V> {
  final _entryMapper = StreamEntryMapper<K, V>();

  @override
  Object? _mapValue(String? key, Reply value, RedisCodec codec) {
    switch (key) {
      case r'last-generated-id':
        return codec.decode<K>(value);
      case r'first-entry':
      case r'last-entry':
        if (value is! ArrayReply) {
          return null;
        }
        return _entryMapper.map(value, codec);
      default:
        return super._mapValue(key, value, codec);
    }
  }
}

/// A mapper to be used with the XINFO command and GROUPS subcommand.
class StreamInfoGroupsMapper<K, V> extends StreamListMapInfoMapper<K, V> {
  @override
  Object? _mapValue(String? key, Reply value, RedisCodec codec) {
    switch (key) {
      case r'name':
        return codec.decode<K>(value);
      default:
        return super._mapValue(key, value, codec);
    }
  }
}

/// A mapper to be used with the XINFO command and CONSUMERS subcommand.
class StreamInfoConsumersMapper<K, V> extends StreamListMapInfoMapper<K, V> {
  @override
  Object? _mapValue(String? key, Reply value, RedisCodec codec) {
    switch (key) {
      case r'name':
        return codec.decode<K>(value);
      default:
        return super._mapValue(key, value, codec);
    }
  }
}

/// A mapper to be used with the XINFO command and HELP subcommand.
class StreamInfoHelpMapper<K, V> implements StreamInfoMapper<K, V> {
  @override
  Object map(covariant ArrayReply reply, RedisCodec codec) {
    final help = <String>[];

    for (final entry in reply.array) {
      help.add(codec.decode<String>(entry));
    }

    return help;
  }
}

/// A mapper to be used with some stream commands.
class StreamsMapper<K, V> implements Mapper<Map<K, List<StreamEntry<K, V>>>> {
  final StreamMapper<K, V> _streamMapper = StreamMapper();

  @override
  Map<K, List<StreamEntry<K, V>>> map(
      covariant ArrayReply reply, RedisCodec codec) {
    final items = reply.array;

    final streams = <K, List<StreamEntry<K, V>>>{};

    for (var item in items) {
      final entry = item as ArrayReply;
      final key = codec.decode<K>(entry.array[0]);
      final stream = _streamMapper.map(entry.array[1] as ArrayReply, codec);

      streams[key] = stream;
    }

    return streams;
  }
}

/// A mapper to be used with some stream commands.
class StreamMapper<K, V> implements Mapper<List<StreamEntry<K, V>>> {
  final StreamEntryMapper<K, V> _entryMapper = StreamEntryMapper();

  @override
  List<StreamEntry<K, V>> map(covariant ArrayReply reply, RedisCodec codec) {
    final stream = <StreamEntry<K, V>>[];

    for (var entry in reply.array) {
      if (entry is ArrayReply) {
        stream.add(_entryMapper.map(entry, codec));
      }
    }

    return stream;
  }
}

/// A mapper to be used with some stream commands.
class StreamEntryMapper<K, V> implements Mapper<StreamEntry<K, V>> {
  final StreamEntryFieldsMapper<K, V> _fieldsMapper = StreamEntryFieldsMapper();

  @override
  StreamEntry<K, V> map(covariant ArrayReply reply, RedisCodec codec) {
    final entry = reply.array;

    final id = codec.decode<K>(entry[0]);
    final fields = _fieldsMapper.map(entry[1] as ArrayReply, codec);

    return StreamEntry<K, V>(id, fields);
  }
}

/// A mapper to be used with some stream commands.
class StreamEntryFieldsMapper<K, V> implements Mapper<Map<K, V>> {
  @override
  Map<K, V> map(covariant ArrayReply reply, RedisCodec codec) {
    // ignore: prefer_collection_literals
    final fields = LinkedHashMap<K, V>();

    final array = reply.array;
    for (var i = 0; i < array.length; i += 2) {
      final key = codec.decode<K>(array[i]);
      final value = codec.decode<V>(array[i + 1]);

      fields[key] = value;
    }

    return fields;
  }
}
