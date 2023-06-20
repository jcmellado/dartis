// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;

import '../exception.dart';
import '../logger.dart';
import 'reply.dart';

/// A converter that converts an instance of type [S] into an instance
/// of type [T].
abstract class Converter<S extends Object, T extends Object> {
  /// The source type [S] of this converter.
  Type get sourceType => S;

  /// The target type [T] of this converter.
  Type get targetType => T;

  /// Converts an instance of type [S] into an instance of type [T].
  T convert(S value, RedisCodec codec);

  /// Checks if this can converts a [value] into an instance of type [U].
  bool supports<U>(Object value) =>
      value is S && U == targetType ||
      U.toString() == '${targetType.toString()}?';
}

/// A converter that converts an instance of type [S] into a list of bytes.
///
/// Extend from this class for building your own encoders.
abstract class Encoder<S extends Object> extends Converter<S, List<int>> {}

/// A converter that converts a server reply into an instance of type [T].
///
/// Extend from this class for building your own decoders.
abstract class Decoder<S extends Reply, T extends Object>
    extends Converter<S, T> {}

// A convert that converts a server reply into a list of instance of type [T].
///
/// Extend from this class for building your own array decoders.
abstract class ArrayDecoder<S extends Reply, T> extends Converter<S, List<T>> {
  /// Checks if this can converts a [value] into an instance of type [List<U>].
  @override
  bool supports<U>(Object? value) =>
      value != null && value is S && U.toString().startsWith('List<$T>');
}

/// A generic converter that encodes instances of any type to lists of bytes
/// and decodes lists of server replies to instances of any type.
///
/// Converters for all well-known types are registered by default.
///
/// Custom converters can be registered in order of adding new ones or
/// replacing the existing ones.
class RedisCodec {
  final _Encoder _encoder = _Encoder();

  final _Decoder _decoder = _Decoder();

  /// Registers a new [encoder] or a new [decoder], or both.
  void register(
      {Converter<Object?, Object?>? encoder,
      Converter<Object?, Object?>? decoder}) {
    assert(encoder != null || decoder != null);

    if (encoder != null) {
      _encoder.register(encoder);
    }
    if (decoder != null) {
      _decoder.register(decoder);
    }
  }

  /// Converts a [value] of any type into an instance of type [T].
  T encode<T>(Object value) => _encoder.convert<T>(value, this);

  /// Converts a [value] of any type into an instance of type [T].
  T decode<T>(Object value) => _decoder.convert<T>(value, this);
}

/// A converter that converts instances of multiple types.
abstract class _MultiConverter {
  final List<Converter<Object?, Object?>> _converters = [];

  /// Registers a new [converter].
  ///
  /// If a converter for the given types already exists the new one replaces
  /// the existing one.
  void register(Converter<Object?, Object?> converter) {
    log.fine(() => 'Registering converter: $converter.');

    _converters
      ..removeWhere((c) =>
          c.sourceType == converter.sourceType &&
          c.targetType == converter.targetType)
      ..add(converter);
  }

  /// Converts a [value] of any type into an instance of type [T].
  T convert<T>(Object value, RedisCodec codec) {
    for (final converter in _converters) {
      if (converter.supports<T>(value)) {
        return converter.convert(value, codec) as T;
      }
    }

    throw RedisException('Unexpected value of type "${value.runtimeType}".');
  }
}

/// A set of encoders that convert instances of any type into lists of bytes.
///
/// Encoders for all well-known types are registered by default.
class _Encoder extends _MultiConverter {
  _Encoder() {
    register(_RawEncoder());
    register(_StringEncoder());
    register(_IntEncoder());
    register(_DoubleEncoder());
  }
}

/// A set of decoders that convert lists of bytes into instances of any type.
///
/// Decoders for all well-known types are registered by default.
class _Decoder extends _MultiConverter {
  _Decoder() {
    register(_RawReplyDecoder());
    register(_StringReplyDecoder());
    register(_IntReplyDecoder());
    register(_DoubleReplyDecoder());
    register(_ArrayReplyDecoder<List<int>>());
    register(_ArrayReplyDecoder<String>());
    register(_ArrayReplyDecoder<String?>());
    register(_ArrayReplyDecoder<int>());
    register(_ArrayReplyDecoder<int?>());
    register(_ArrayReplyDecoder<double>());
    register(_ArrayReplyDecoder<double?>());
  }
}

/// An encoder that does nothing.
class _RawEncoder extends Encoder<List<int>> {
  @override
  List<int> convert(List<int> value, RedisCodec codec) => value;
}

/// An encoder that converts a [String] into a list of bytes.
class _StringEncoder extends Encoder<String> {
  @override
  List<int> convert(String? value, RedisCodec codec) => utf8.encode(value!);
}

/// An encoder that converts an [int] into a list of bytes.
class _IntEncoder extends Encoder<int> {
  @override
  List<int> convert(int? value, RedisCodec codec) => value.toString().codeUnits;
}

/// An encoder that converts a [double] into a list of bytes.
class _DoubleEncoder extends Encoder<double> {
  static const List<int> _infinity = <int>[43, 105, 110, 102]; // +inf

  static const List<int> _negativeInfinity = <int>[45, 105, 110, 102]; // -inf

  @override
  List<int> convert(double? value, RedisCodec codec) {
    if (value!.isFinite) {
      return value.toString().codeUnits;
    }
    if (value == double.infinity) {
      return _infinity;
    }
    if (value == double.negativeInfinity) {
      return _negativeInfinity;
    }

    // Unsupported double.nan conversion.
    throw RedisException('Value "$value" could not be encoded.');
  }
}

/// A decoder that returns the raw value of a server reply.
class _RawReplyDecoder extends Decoder<SingleReply, List<int>> {
  @override
  List<int> convert(SingleReply? value, RedisCodec codec) => value!.bytes;
}

/// A decoder that converts a server reply into an [String].
class _StringReplyDecoder extends Decoder<SingleReply, String> {
  @override
  String convert(SingleReply value, RedisCodec codec) =>
      utf8.decode(value.bytes);
}

/// A decoder that converts a server reply into an [int].
class _IntReplyDecoder extends Decoder<SingleReply, int> {
  @override
  int convert(SingleReply value, RedisCodec codec) =>
      int.parse(String.fromCharCodes(value.bytes));
}

/// A decoder that converts a server reply into a [double].
class _DoubleReplyDecoder extends Decoder<SingleReply, double> {
  @override
  double convert(SingleReply value, RedisCodec codec) {
    final number = String.fromCharCodes(value.bytes);

    if (number == r'+inf') {
      return double.infinity;
    }
    if (number == r'-inf') {
      return double.negativeInfinity;
    }

    return double.parse(number);
  }
}

/// A decoder that converts an array of server replies into a list of
/// instances of type [T].
class _ArrayReplyDecoder<T> extends ArrayDecoder<ArrayReply, T> {
  @override
  List<T> convert(ArrayReply value, RedisCodec codec) => value.array
      .map((reply) => reply is NullReply ? null as T : codec.decode<T>(reply))
      .toList();
}
