# Weight Scale Plugin

A Flutter plugin for interfacing with commercial weight scales via RS232 using the AUTO COMMUNICATE PROTOCOL. Provides real-time weight data streaming and robust device management for Android applications.

[![pub package](https://img.shields.io/pub/v/weight_scale.svg)](https://pub.dev/packages/weight_scale)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/nikitiser/weight_scale/actions/workflows/ci.yml/badge.svg)](https://github.com/nikitiser/weight_scale/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/nikitiser/weight_scale/branch/main/graph/badge.svg)](https://codecov.io/gh/nikitiser/weight_scale)

## Features

- 🔌 **Android USB-Serial support**: Full USB-Serial communication with commercial scales
- ⚡ **Real-time data streaming**: Continuous weight readings via EventChannel
- 🛡️ **Type-safe error handling**: Result<T> pattern instead of exceptions
- 🔍 **Device auto-discovery**: Automatic USB device detection and validation
- 📊 **Protocol validation**: Built-in BCC validation and frame structure checks
- 🎯 **Configurable**: Customizable timeouts, logging, and device filtering
- 📱 **Production ready**: Memory-efficient circular buffer and connection management

## Supported Protocols

- **RS232 AUTO COMMUNICATE PROTOCOL**: 16-byte frame structure
- **Frame format**: SOH + STX + Status + Sign + Weight(6) + Units(2) + BCC + ETX + EOT + Status2
- **Baud rate**: 9600 (configurable)
- **Data validation**: BCC (Block Check Character) validation

## Supported Devices

Currently tested with:

- Aclas scales (VID: 6790, PID: 29987)
- Generic USB-Serial scales
- Any RS232 scale using AUTO COMMUNICATE PROTOCOL

## Platform Support

**Android Only**: This plugin currently supports Android devices only through USB-Serial communication.

| Platform | Status           | Features                                                  |
| -------- | ---------------- | --------------------------------------------------------- |
| Android  | ✅ Full          | USB-Serial, Real-time streaming                           |
| iOS      | ❌ Not supported | iOS doesn't support USB host mode without MFi accessories |
| Windows  | ❌ Not supported | Not implemented                                           |
| macOS    | ❌ Not supported | Not implemented                                           |
| Linux    | ❌ Not supported | Not implemented                                           |

> **Note**: This plugin is designed specifically for Android applications that need to interface with commercial weight scales via USB-Serial. Other platforms may be considered for future versions based on community demand and technical feasibility.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  weight_scale: ^1.0.0
```

### Android Setup

Add this to your `android/build.gradle` (project level):

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url 'https://www.jitpack.io'
        }
    }
}
```

Add USB permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USB_PERMISSION" />
<uses-feature android:name="android.hardware.usb.host" />
```

## Quick Start

```dart
import 'package:weight_scale/weight_scale_manager.dart';
import 'package:weight_scale/core/config.dart';
import 'package:weight_scale/core/logger.dart';

class WeightScaleExample {
  late final WeightScaleManager manager;

  void initialize() {
    manager = WeightScaleManager(
      config: const WeightScaleConfig(
        deviceCheckTimeout: Duration(seconds: 2),
        debugLogging: true,
      ),
      logger: const ConsoleLogger(),
    );
  }

  Future<void> scanAndConnect() async {
    // Get available devices
    final result = await manager.getAvailableDevices();

    result.fold(
      (devices) async {
        if (devices.isNotEmpty) {
          // Connect to first available device
          final connectResult = await manager.connect(devices.first);

          connectResult.fold(
            (_) => print('Connected successfully!'),
            (failure) => print('Connection failed: ${failure.message}'),
          );
        }
      },
      (failure) => print('Scan failed: ${failure.message}'),
    );
  }

  void startListening() {
    manager.initialize();

    manager.dataStream?.listen(
      (scaleData) {
        print('Weight: ${scaleData.numericWeight} ${scaleData.weightUnits}');
        print('Status: ${scaleData.isStable ? 'Stable' : 'Unstable'}');
        print('Tare: ${scaleData.isTareActive ? 'Active' : 'Inactive'}');
      },
      onError: (error) => print('Stream error: $error'),
    );
  }
}
```

## Advanced Usage

### Custom Configuration

```dart
final manager = WeightScaleManager(
  config: WeightScaleConfig(
    deviceCheckTimeout: Duration(milliseconds: 500),
    knownScaleDevices: [
      ...WeightScaleConfig.defaultKnownScales,
      ScaleDeviceIdentifier(
        vendorID: '1234',
        productID: '5678',
        name: 'Custom Scale',
      ),
    ],
    debugLogging: false,
  ),
  logger: SilentLogger(), // For production
);
```

### Error Handling

```dart
manager.setErrorCallback((error, stackTrace) {
  if (error is PlatformException && error.code == 'CONNECTION_LOST') {
    print('Scale disconnected - attempting reconnection...');
    // Handle reconnection logic
  }
});
```

### Data Processing

```dart
manager.dataStream?.listen((data) {
  // Type-safe data access
  final weight = data.numericWeight;
  final isStable = data.isStable;
  final units = data.weightUnits;

  // Conditional processing
  if (data.isStable && !data.isZero) {
    processStableWeight(weight, units);
  }

  // Raw data access for custom protocols
  final rawBytes = data.rawData;
  if (rawBytes != null) {
    processRawData(rawBytes);
  }
});
```

## Architecture

The plugin follows clean architecture principles:

```
├── core/                    # Shared utilities and types
│   ├── result.dart         # Result<T> for type-safe error handling
│   ├── config.dart         # Configuration and device identifiers
│   └── logger.dart         # Logging abstraction
├── repositories/           # Data access interfaces
│   └── device_repository.dart
├── data/                   # Data handling interfaces
│   └── data_stream.dart
├── protocol.dart           # RS232 protocol implementation
├── weight_scale_manager.dart # Main API (singleton)
└── weight_scale_device.dart  # Device model
```

## Testing

Run unit tests:

```bash
flutter test
```

Run integration tests:

```bash
cd example
flutter test integration_test/
```

Calculate BCC values for custom data:

```bash
dart test/bcc_calculator.dart
```

## Troubleshooting

### Common Issues

**Device not found**

- Ensure USB permissions are granted
- Check VID/PID matches your scale model
- Verify scale is using AUTO COMMUNICATE PROTOCOL

**Connection timeout**

- Increase `deviceCheckTimeout` in config
- Check USB cable and connections
- Verify scale is powered on and ready

**Data parsing errors**

- Ensure scale uses 16-byte frame format
- Check BCC calculation implementation
- Enable debug logging to inspect raw data

**Memory issues**

- Plugin uses circular buffer to prevent memory leaks
- Dispose resources properly: `await manager.dispose()`

### Debug Logging

Enable detailed logging:

```dart
final manager = WeightScaleManager(
  config: const WeightScaleConfig(debugLogging: true),
  logger: const ConsoleLogger(),
);
```

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) and [code of conduct](CODE_OF_CONDUCT.md).

### Development Setup

1. Clone the repository
2. Run `flutter pub get`
3. Run tests: `flutter test`
4. Run example: `cd example && flutter run`

## Roadmap

- [ ] iOS support via Lightning/USB-C adapters
- [ ] Windows support via COM ports
- [ ] macOS and Linux support
- [ ] Custom protocol support
- [ ] Bluetooth scale support
- [ ] Web support via WebSerial API

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## Support

- 📖 [Documentation](https://github.com/nikitiser/weight_scale#readme)
- 🐛 [Bug Reports](https://github.com/nikitiser/weight_scale/issues)
- 💬 [Discussions](https://github.com/nikitiser/weight_scale/discussions)
- 📧 [Contact](mailto:nikitiser@gmail.com)
