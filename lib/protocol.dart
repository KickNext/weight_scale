// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

/// Protocol constants for RS232 communication
class ProtocolConstants {
  static const int SOH = 0x01;
  static const int STX = 0x02;
  static const int ETX = 0x03;
  static const int EOT = 0x04;
  static const int SIGN_POSITIVE = 0x20; // Space character
  static const int SIGN_NEGATIVE = 0x2D; // Minus character
  static const int EXPECTED_FRAME_SIZE = 16;
}

/// Parser for RS232 scale communication protocol
class ScaleProtocol {
  /// Parse raw data bytes into ScaleData
  /// Throws [ArgumentError] for insufficient data
  /// Throws [FormatException] for invalid protocol structure
  static ScaleData parseData(Uint8List data) {
    _validateDataLength(data);

    final frame = _extractFrameData(data);
    _validateFrame(frame);

    return _buildScaleData(frame);
  }

  static void _validateDataLength(Uint8List data) {
    if (data.isEmpty) {
      throw ArgumentError('No data received');
    }
    if (data.length < ProtocolConstants.EXPECTED_FRAME_SIZE) {
      throw ArgumentError(
          'Insufficient data received: ${data.length} bytes, expected ${ProtocolConstants.EXPECTED_FRAME_SIZE}');
    }
  }

  static _FrameData _extractFrameData(Uint8List data) {
    return _FrameData(
      soh: data[0],
      stx: data[1],
      statusByte: data[2],
      signByte: data[3],
      weight: String.fromCharCodes(data.sublist(4, 10)),
      weightUnits: String.fromCharCodes(data.sublist(10, 12)),
      bcc: data[12],
      etx: data[13],
      eot: data[14],
      statusByte2: data[15],
      rawData: data.sublist(0, ProtocolConstants.EXPECTED_FRAME_SIZE),
    );
  }

  static void _validateFrame(_FrameData frame) {
    _validateHeaders(frame.soh, frame.stx, frame.etx, frame.eot);
    _validateSignByte(frame.signByte);
    _validateWeightUnits(frame.weightUnits);
    _validateBcc(frame.rawData, frame.bcc);
  }

  static ScaleData _buildScaleData(_FrameData frame) {
    final status = Status.fromByte(frame.statusByte);
    final status2 = Status2.fromByte(frame.statusByte2);
    final isPositive = frame.signByte != ProtocolConstants.SIGN_NEGATIVE;

    String weight = frame.weight;
    if (!isPositive) {
      weight = '-$weight';
    }

    return ScaleData(
      status: status,
      weight: weight,
      weightUnits: frame.weightUnits,
      status2: status2,
      isPositive: isPositive,
      rawData: frame.rawData,
    );
  }

  static void _validateHeaders(int soh, int stx, int etx, int eot) {
    if (soh != ProtocolConstants.SOH ||
        stx != ProtocolConstants.STX ||
        etx != ProtocolConstants.ETX ||
        eot != ProtocolConstants.EOT) {
      throw const FormatException(
          'Invalid frame headers - expected SOH/STX/ETX/EOT sequence');
    }
  }

  static void _validateSignByte(int signByte) {
    if (signByte != ProtocolConstants.SIGN_NEGATIVE &&
        signByte != ProtocolConstants.SIGN_POSITIVE) {
      throw FormatException(
          'Invalid sign character: 0x${signByte.toRadixString(16)} - expected space (0x20) or minus (0x2D)');
    }
  }

  static void _validateWeightUnits(String weightUnits) {
    if (weightUnits.length != 2) {
      throw FormatException(
          'Invalid weight units length: ${weightUnits.length} - expected 2 characters');
    }
  }

  static void _validateBcc(Uint8List data, int receivedBcc) {
    final calculatedBcc = calculateBcc(data.sublist(0, 12));
    if (receivedBcc != calculatedBcc) {
      throw FormatException(
          'BCC validation failed - calculated: 0x${calculatedBcc.toRadixString(16)}, received: 0x${receivedBcc.toRadixString(16)}');
    }
  }

  /// Calculate Block Check Character (BCC) for data validation
  static int calculateBcc(Uint8List data) {
    int bcc = 0;
    for (final byte in data) {
      bcc ^= byte;
    }
    bcc ^= ProtocolConstants.ETX;
    return bcc;
  }
}

/// Internal frame data structure
class _FrameData {
  final int soh;
  final int stx;
  final int statusByte;
  final int signByte;
  final String weight;
  final String weightUnits;
  final int bcc;
  final int etx;
  final int eot;
  final int statusByte2;
  final Uint8List rawData;

  const _FrameData({
    required this.soh,
    required this.stx,
    required this.statusByte,
    required this.signByte,
    required this.weight,
    required this.weightUnits,
    required this.bcc,
    required this.etx,
    required this.eot,
    required this.statusByte2,
    required this.rawData,
  });
}

/// Parsed scale data from RS232 communication
class ScaleData {
  final Status status;
  final String weight;
  final String weightUnits;
  final Status2 status2;
  final bool isPositive;
  final Uint8List? rawData;

  const ScaleData({
    required this.status,
    required this.weight,
    required this.weightUnits,
    required this.status2,
    required this.isPositive,
    this.rawData,
  });

  /// Get numeric weight value (parsing weight string)
  double get numericWeight {
    try {
      return double.parse(weight.replaceAll(' ', ''));
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if scale is in stable condition
  bool get isStable => status == Status.stable;

  /// Check if weight is zero
  bool get isZero => status2 == Status2.zero;

  /// Check if tare is active
  bool get isTareActive => status2 == Status2.tare;

  @override
  String toString() {
    return 'ScaleData(status: ${status.name}, weight: $weight $weightUnits, '
        'status2: ${status2.name}, isPositive: $isPositive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScaleData &&
        other.status == status &&
        other.weight == weight &&
        other.weightUnits == weightUnits &&
        other.status2 == status2 &&
        other.isPositive == isPositive;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        weight.hashCode ^
        weightUnits.hashCode ^
        status2.hashCode ^
        isPositive.hashCode;
  }

  /// Create a copy with modified fields
  ScaleData copyWith({
    Status? status,
    String? weight,
    String? weightUnits,
    Status2? status2,
    bool? isPositive,
    Uint8List? rawData,
  }) {
    return ScaleData(
      status: status ?? this.status,
      weight: weight ?? this.weight,
      weightUnits: weightUnits ?? this.weightUnits,
      status2: status2 ?? this.status2,
      isPositive: isPositive ?? this.isPositive,
      rawData: rawData ?? this.rawData,
    );
  }
}

enum Status {
  overload, // F (46h)
  stable, // S (53h)
  unstable, // U (55h)
  unknown; // Unknown status

  static Status fromByte(int byte) {
    switch (byte) {
      case 0x46: // 'F'
        return Status.overload;
      case 0x53: // 'S'
        return Status.stable;
      case 0x55: // 'U'
        return Status.unstable;
      default:
        return Status.unknown;
    }
  }
}

enum Status2 {
  none, // Value 0
  zero, // Value 16 (0x10)
  tare, // Value 32 (0x20)
  overload, // Value 64 (0x40)
  unknown; // Unknown status

  static Status2 fromByte(int byte) {
    switch (byte) {
      case 0:
        return Status2.none;
      case 0x10:
        return Status2.zero;
      case 0x20:
        return Status2.tare;
      case 0x40:
        return Status2.overload;
      default:
        return Status2.unknown;
    }
  }
}
