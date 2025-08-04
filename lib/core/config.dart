import 'package:weight_scale/weight_scale_device.dart';

/// Configuration class for weight scale operations
class WeightScaleConfig {
  /// Timeout for device validation check
  final Duration deviceCheckTimeout;

  /// USB serial connection parameters
  final SerialParameters serialParameters;

  /// Known scale device identifiers
  final List<ScaleDeviceIdentifier> knownScaleDevices;

  /// Debug logging enabled
  final bool debugLogging;

  /// Buffer size for data processing
  final int bufferSize;

  const WeightScaleConfig({
    this.deviceCheckTimeout = const Duration(milliseconds: 500),
    this.serialParameters = const SerialParameters(),
    this.knownScaleDevices = defaultKnownScales,
    this.debugLogging = true,
    this.bufferSize = 1024,
  });

  static const List<ScaleDeviceIdentifier> defaultKnownScales = [
    ScaleDeviceIdentifier(
      vendorID: '6790',
      productID: '29987',
      name: 'Aclas',
    ),
    ScaleDeviceIdentifier(
      vendorID: '1027',
      productID: '24577',
      name: 'No Name Scale',
    ),
  ];
}

/// Serial connection parameters
class SerialParameters {
  final int baudRate;
  final int dataBits;
  final int stopBits;
  final int parity;

  const SerialParameters({
    this.baudRate = 9600,
    this.dataBits = 8,
    this.stopBits = 1,
    this.parity = 0, // PARITY_NONE
  });

  Map<String, dynamic> toMap() => {
        'baudRate': baudRate,
        'dataBits': dataBits,
        'stopBits': stopBits,
        'parity': parity,
      };
}

/// Scale device identifier for filtering
class ScaleDeviceIdentifier {
  final String vendorID;
  final String productID;
  final String name;

  const ScaleDeviceIdentifier({
    required this.vendorID,
    required this.productID,
    required this.name,
  });

  bool matches(WeightScaleDevice device) =>
      device.vendorID == vendorID && device.productID == productID;
}
