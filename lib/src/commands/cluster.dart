// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:collection' show LinkedHashMap;

import '../command.dart';
import '../protocol.dart';

/// A convenient shared mapper for the CLUSTER INFO command.
const ClusterInfoMapper clusterInfoMapper = ClusterInfoMapper();

/// A convenient shared mapper for the CLUSTER SLOTS command.
const ClusterSlotRangeMapper clusterSlotRangeMapper = ClusterSlotRangeMapper();

/// Redis cluster commands.
abstract class ClusterCommands<K> {
  /// Assigns new hash slots to receiving node.
  ///
  /// See https://redis.io/commands/cluster-addslots
  Future<void> clusterAddslots({int? slot, Iterable<int> slots = const []});

  /// Returns the number of failure reports active for a given node.
  ///
  /// See https://redis.io/commands/cluster-count-failure-reports
  Future<int?> clusterCountFailureReports(String nodeId);

  /// Returns the number of local keys in the specified hash [slot].
  ///
  /// See https://redis.io/commands/cluster-countkeysinslot
  Future<int?> clusterCountkeysinslot(int slot);

  /// Sets hash slots as unbound in receiving node.
  ///
  /// See https://redis.io/commands/cluster-delslots
  Future<void> clusterDelslots({int? slot, Iterable<int> slots = const []});

  /// Forces a slave to perform a manual failover of its master.
  ///
  /// See https://redis.io/commands/cluster-failover
  Future<void> clusterFailover([ClusterFailoverMode? mode]);

  /// Removes a node from the nodes table.
  ///
  /// See https://redis.io/commands/cluster-forget
  Future<void> clusterForget(String nodeId);

  /// Returns an array of keys names stored in the contacted node
  /// and hashing to the specified hash [slot]. The maximum number
  /// of keys to return is specified via the [count] argument.
  ///
  /// See https://redis.io/commands/cluster-getkeysinslot
  Future<List<K>?> clusterGetkeysinslot(int slot, int count);

  /// Provides info about Redis Cluster node state.
  ///
  /// See https://redis.io/commands/cluster-info
  Future<Map<String, String>?> clusterInfo();

  /// Returns the hash slot number of the specified [key].
  ///
  /// See https://redis.io/commands/cluster-keyslot
  Future<int?> clusterKeyslot(K key);

  /// Forces a node cluster to handshake with another node.
  ///
  /// See https://redis.io/commands/cluster-meet
  Future<void> clusterMeet(String ip, int port);

  /// Provides the current cluster configuration of the node
  /// we are contacting.
  ///
  /// See https://redis.io/commands/cluster-nodes
  Future<String?> clusterNodes();

  /// Reconfigures a node as a slave of the specified master node.
  ///
  /// See https://redis.io/commands/cluster-replicate
  Future<void> clusterReplicate(String nodeId);

  /// Reset a Redis Cluster node.
  ///
  /// See https://redis.io/commands/cluster-reset
  Future<void> clusterReset([ClusterResetMode? mode]);

  /// Forces the node to save cluster state on disk.
  ///
  /// See https://redis.io/commands/cluster-saveconfig
  Future<void> clusterSaveconfig();

  /// Sets a specific config epoch in a fresh node.
  ///
  /// See https://redis.io/commands/cluster-set-config-epoch
  Future<void> clusterSetConfigEpoch(int configEpoch);

  /// Binds a hash slot to a specific node.
  ///
  /// See https://redis.io/commands/cluster-setslot
  Future<void> clusterSetslot(int slot, ClusterSetslotCommand command,
      {String? nodeId});

  /// Lists slave nodes of the specified master node.
  ///
  /// See https://redis.io/commands/cluster-slaves
  Future<String?> clusterSlaves(String nodeId);

  /// Returns details about which cluster slots map to which Redis instances.
  ///
  /// See https://redis.io/commands/cluster-slots
  Future<List<ClusterSlotRange>?> clusterSlots();

  /// Enables read queries for a connection to a Redis Cluster slave node.
  ///
  /// See https://redis.io/commands/readonly
  Future<void> readonly();

  /// Disables read queries for a connection to a Redis Cluster slave node.
  ///
  /// See https://redis.io/commands/readwrite
  Future<void> readwrite();
}

/// The allowed modes for the CLUSTER FAILOVER command.
class ClusterFailoverMode {
  /// The name of the mode.
  final String name;

  const ClusterFailoverMode._(this.name);

  /// FORCE.
  static const ClusterFailoverMode force = ClusterFailoverMode._(r'FORCE');

  /// TAKEOVER.
  static const ClusterFailoverMode takeover =
      ClusterFailoverMode._(r'TAKEOVER');

  @override
  String toString() => 'ClusterFailoverMode: $name';
}

/// The allowed modes for the CLUSTER RESET command.
class ClusterResetMode {
  /// The name of the mode.
  final String name;

  const ClusterResetMode._(this.name);

  /// HARD.
  static const ClusterResetMode hard = ClusterResetMode._(r'HARD');

  /// SOFT.
  static const ClusterResetMode soft = ClusterResetMode._(r'SOFT');

  @override
  String toString() => 'ClusterResetMode: $name';
}

/// The allowed subcommands for the CLUSTER SETSLOT command.
class ClusterSetslotCommand {
  /// The name of the subcommand.
  final String name;

  const ClusterSetslotCommand._(this.name);

  /// Set a hash slot in importing state.
  static const ClusterSetslotCommand importing =
      ClusterSetslotCommand._(r'IMPORTING');

  /// Set a hash slot in migrating state.
  static const ClusterSetslotCommand migrating =
      ClusterSetslotCommand._(r'MIGRATING');

  /// Clear any importing / migrating state from hash slot.
  static const ClusterSetslotCommand stable =
      ClusterSetslotCommand._(r'STABLE');

  /// Bind the hash slot to a different node.
  static const ClusterSetslotCommand node = ClusterSetslotCommand._(r'NODE');

  @override
  String toString() => 'ClusterSetslotCommand: $name';
}

/// A cluster node instance.
class ClusterNode {
  /// The IP.
  final String ip;

  /// The port.
  final int port;

  /// The ID.
  final String? id;

  /// Creates a [ClusterNode] instance.
  const ClusterNode(this.ip, this.port, [this.id]);

  @override
  String toString() => 'ClusterNode: {ip=$ip, port=$port, id=$id}';
}

/// A slot range.
class ClusterSlotRange {
  /// The start slot range.
  final int start;

  /// The end slot range.
  final int end;

  /// The Redis node instances.
  final List<ClusterNode> nodes;

  /// Creates a [ClusterSlotRange] instance.
  const ClusterSlotRange(this.start, this.end, this.nodes);

  @override
  String toString() =>
      'ClusterSlotRange: {start=$start, end=$end, nodes=$nodes}';
}

/// A maper for the CLUSTER INFO command.
class ClusterInfoMapper implements Mapper<Map<String, String>> {
  /// Creates a [ClusterInfoMapper] instance.
  const ClusterInfoMapper();

  @override
  Map<String, String> map(Reply reply, RedisCodec codec) {
    // ignore: prefer_collection_literals
    final map = LinkedHashMap<String, String>();

    final raw = codec.decode<String>(reply);
    final lines = raw.split('\r\n');

    for (final line in lines.where((line) => line.isNotEmpty)) {
      final parts = line.split(':');

      map[parts[0]] = parts[1];
    }

    return map;
  }
}

/// A maper for the CLUSTER SLOTS command.
class ClusterSlotRangeMapper implements Mapper<List<ClusterSlotRange>> {
  /// Creates a [ClusterSlotRangeMapper] instance.
  const ClusterSlotRangeMapper();

  @override
  List<ClusterSlotRange> map(covariant ArrayReply reply, RedisCodec codec) =>
      reply.array
          .map((value) => _mapRange(value as ArrayReply, codec))
          .toList();

  /// Maps a [reply] to a [ClusterSlotRange] instance.
  ClusterSlotRange _mapRange(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final start = codec.decode<int>(array[0]);
    final end = codec.decode<int>(array[1]);
    final nodes = <ClusterNode>[];

    for (var i = 2; i < array.length; i++) {
      final node = _mapNode(array[i] as ArrayReply, codec);

      nodes.add(node);
    }

    return ClusterSlotRange(start, end, nodes);
  }

  /// Maps a [reply] to a [ClusterNode] instance.
  ClusterNode _mapNode(ArrayReply reply, RedisCodec codec) {
    final array = reply.array;

    final ip = codec.decode<String>(array[0]);
    final port = codec.decode<int>(array[1]);

    String? id;
    if (array.length > 2) {
      id = codec.decode<String>(array[2]);
    }

    return ClusterNode(ip, port, id);
  }
}
