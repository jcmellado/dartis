// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import '../command.dart';
import '../protocol.dart';

/// A convenient shared mapper for the SET command.
const StringSetMapper stringSetMapper = StringSetMapper();

/// Redis strings commands.
abstract class StringCommands<K, V> {
  /// Appends a [value] to a [key].
  ///
  /// Returns the length of the string after the append operation.
  ///
  /// See https://redis.io/commands/append
  Future<int> append(K key, V value);

  /// Returns the number of bits set to 1 in a string.
  ///
  /// See https://redis.io/commands/bitcount
  Future<int> bitcount(K key, [int? start, int? end]);

  /// Performs arbitrary bitfield integer [operations] in a string.
  ///
  /// Returns a list with each entry being the corresponding result of
  /// the operation given at the same position.
  ///
  /// See https://redis.io/commands/bitfield
  Future<List<int?>> bitfield(K key, List<BitfieldOperation> operations);

  /// Performs bitwise operations between strings.
  ///
  /// Returns the size of the string stored in the destination key.
  ///
  /// See https://redis.io/commands/bitop
  Future<int> bitop(BitopOperation operation, K destkey,
      {K? key, Iterable<K> keys = const []});

  /// Returns the position of the first bit set to 1 or 0 according to the
  /// request.
  ///
  /// See https://redis.io/commands/bitpos
  Future<int> bitpos(K key, int bit, [int? start, int? end]);

  /// Decrements the number stored at [key] by one.
  ///
  /// Returns the value of [key] after the decrement.
  ///
  /// See https://redis.io/commands/decr
  Future<int> decr(K key);

  /// Decrements the number stored at [key] by [decrement].
  ///
  /// Returns the value of [key] after the decrement.
  ///
  /// See https://redis.io/commands/decrby
  Future<int> decrby(K key, int decrement);

  /// Returns the value of [key].
  ///
  /// See https://redis.io/commands/get
  Future<V?> get(K key);

  /// Returns the bit value at [offset] in the string value stored at [key].
  ///
  /// See https://redis.io/commands/getbit
  Future<int> getbit(K key, int offset);

  /// Returns the substring of the string value stored at [key], determined
  /// by the offsets [start] and [end].
  ///
  /// See https://redis.io/commands/getrange
  Future<V> getrange(K key, int start, int end);

  /// Atomically sets [key] to [value] and returns the old value stored
  /// at [key].
  ///
  /// See https://redis.io/commands/getset
  Future<V?> getset(K key, V value);

  /// Increments the number stored at [key] by one.
  ///
  /// Returns the value of [key] after the increment.
  ///
  /// See https://redis.io/commands/incr
  Future<int> incr(K key);

  /// Increments the number stored at [key] by [increment].
  ///
  /// Returns the value of [key] after the increment.
  ///
  /// See https://redis.io/commands/incrby
  Future<int> incrby(K key, int increment);

  /// Increments the floating point number stored at [key] by the
  /// specified [increment].
  ///
  /// Returns the value of [key] after the increment.
  ///
  /// See https://redis.io/commands/incrbyfloat
  Future<double> incrbyfloat(K key, double increment);

  /// Returns the values of all specified keys.
  ///
  /// See https://redis.io/commands/mget
  Future<List<V?>> mget({K? key, Iterable<K> keys = const []});

  /// Sets the given keys to their respective values.
  ///
  /// See https://redis.io/commands/mset
  Future<void> mset({K? key, V? value, Map<K, V> map = const {}});

  /// Sets the given keys to their respective values, but only if all keys
  /// already exist.
  ///
  /// Returns `1` if the all the keys were set, `0` if no key was set.
  ///
  /// See https://redis.io/commands/msetnx
  Future<int> msetnx({K? key, V? value, Map<K, V> map = const {}});

  /// Sets the [value] and expiration in [milliseconds] of a [key].
  ///
  /// See https://redis.io/commands/psetex
  Future<void> psetex(K key, int milliseconds, V value);

  /// Sets the [value] of a [key].
  ///
  /// Returns `true` if the operation was executed correctly, `false` otherwise.
  ///
  /// See https://redis.io/commands/set
  Future<bool> set(K key, V value,
      {int? seconds, int? milliseconds, SetExistMode? mode});

  /// Sets or clears the bit at [offset] in the string value stored at [key].
  ///
  /// Returns the original bit value stored at [offset].
  ///
  /// See https://redis.io/commands/setbit
  Future<int> setbit(K key, int offset, int value);

  /// Sets the [value] and expiration of a [key].
  ///
  /// See https://redis.io/commands/setex
  Future<void> setex(K key, int seconds, V value);

  /// Sets the [value] of a [key], only if the [key] does not exist
  ///
  /// Returns `1` if the [key] was set, `0` if the [key] was not set.
  ///
  /// See https://redis.io/commands/setnx
  Future<int> setnx(K key, V value);

  /// Overwrites part of the string stored at [key], starting at the
  /// specified [offset], for the entire length of [value].
  ///
  /// Returns the length of the string after it was modified by the command.
  ///
  /// See https://redis.io/commands/setrange
  Future<int> setrange(K key, int offset, V value);

  /// Returns the length of the string value stored at [key].
  ///
  /// See https://redis.io/commands/strlen
  Future<int> strlen(K key);
}

/// Allowed commands for the BITFIELD command.
class BitfieldCommand {
  /// The name of the command.
  final String name;

  const BitfieldCommand._(this.name);

  /// Returns the specified bit field.
  static const BitfieldCommand get = BitfieldCommand._(r'GET');

  /// Set the specified bit field and returns its old value.
  static const BitfieldCommand set = BitfieldCommand._(r'SET');

  /// Increments/decrements the specified bit field and returns the new value.
  static const BitfieldCommand incrby = BitfieldCommand._(r'INCRBY');

  @override
  String toString() => 'BitfieldCommand: $name';
}

/// The modes used to fine-tune the behavior of the increment and decrement
/// overflow (or underflow) for the BITFIELD command.
class BitfieldOverflow {
  /// The name of the mode.
  final String name;

  const BitfieldOverflow._(this.name);

  /// Wrap around, both with signed and unsigned integers.
  static const BitfieldOverflow wrap = BitfieldOverflow._(r'WRAP');

  /// Uses saturation arithmetic.
  static const BitfieldOverflow sat = BitfieldOverflow._(r'SAT');

  /// No operation is performed on overflows or underflows detected.
  static const BitfieldOverflow fail = BitfieldOverflow._(r'FAIL');

  @override
  String toString() => 'BitfieldOverflow: $name';
}

/// Allowed operations for the BITOP command.
class BitopOperation {
  /// The name of the operation.
  final String name;

  const BitopOperation._(this.name);

  /// AND.
  static const BitopOperation and = BitopOperation._(r'AND');

  /// OR.
  static const BitopOperation or = BitopOperation._(r'OR');

  /// XOR.
  static const BitopOperation xor = BitopOperation._(r'XOR');

  /// NOT.
  static const BitopOperation not = BitopOperation._(r'NOT');

  @override
  String toString() => 'BitopOperation: $name';
}

/// Allowed modes for the SET command.
class SetExistMode {
  /// The name of the mode.
  final String name;

  const SetExistMode._(this.name);

  /// Only set the key if it does not already exist.
  static const SetExistMode nx = SetExistMode._(r'NX');

  /// Only set the key if it already exist.
  static const SetExistMode xx = SetExistMode._(r'XX');

  @override
  String toString() => 'SetExistMode: $name';
}

/// Operations to be performed for the BITFIELD command.
class BitfieldOperation {
  /// The command.
  final BitfieldCommand? command;

  /// The type.
  final String? type;

  /// The offset.
  final String? offset;

  /// The value/increment.
  final int? value;

  /// The overflow.
  final BitfieldOverflow? overflow;

  /// Creates a [BitfieldOperation] instance.
  const BitfieldOperation(this.command, this.type, this.offset,
      {this.value, this.overflow});

  @override
  String toString() => '''BitfieldOperation: {command=$command, type=$type,'''
      ''' offset=$offset, value=$value, overflow=$overflow}''';
}

/// Mapper to be used with the SET command.
class StringSetMapper implements Mapper<bool> {
  /// Creates a [StringSetMapper] instance.
  const StringSetMapper();

  @override
  bool map(Reply reply, RedisCodec codec) => reply.value != null;
}
