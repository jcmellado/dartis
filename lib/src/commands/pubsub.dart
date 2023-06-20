// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import '../command.dart';
import '../protocol.dart';

/// Redis pub/sub commands.
abstract class PubSubCommands<K, V> {
  /// Posts a [message] to the given [channel].
  ///
  /// Returns the number of clients that received the [message].
  //
  /// See https://redis.io/commands/publish
  Future<int> publish(K channel, V message);

  /// Returns the currently active channels, optionally matching the
  /// specified [pattern].
  ///
  /// See [pubsubNumsub] and [pubsubNumpat].
  ///
  /// See https://redis.io/commands/pubsub
  Future<List<K>> pubsubChannels({K? pattern});

  /// Returns the number of subscribers (not counting clients subscribed
  /// to patterns) for the specified [channels].
  ///
  /// See [pubsubChannels] and [pubsubNumpat].
  ///
  /// See https://redis.io/commands/pubsub
  Future<List<PubsubResult<K>>> pubsubNumsub({Iterable<K> channels = const []});

  /// Returns the number of subscriptions to patterns.
  ///
  /// See [pubsubChannels] and [pubsubNumsub].
  //
  /// See https://redis.io/commands/pubsub
  Future<int> pubsubNumpat();
}

/// Result of the PUBSUB NUMSUB command.
class PubsubResult<K> {
  /// The channel name.
  final K channel;

  /// The number of subscribers.
  final int? subscriberCount;

  /// Creates a [PubsubResult] instance.
  const PubsubResult(this.channel, this.subscriberCount);

  @override
  String toString() => '''PubsubResult<$K>: {channel=$channel,'''
      ''' subscriberCount=$subscriberCount}''';
}

/// A mapper for the PUBSUB NUMSUB command.
class PubsubResultMapper<K> implements Mapper<List<PubsubResult<K>>> {
  @override
  List<PubsubResult<K>> map(covariant ArrayReply reply, RedisCodec codec) {
    final results = <PubsubResult<K>>[];

    final array = reply.array;
    for (var i = 0; i < array.length; i += 2) {
      final channel = codec.decode<K>(array[i]);
      final subscriberCount = codec.decode<int>(array[i + 1]);
      final result = PubsubResult<K>(channel, subscriberCount);

      results.add(result);
    }

    return results;
  }
}
