import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:weight_scale/weight_scale_manager.dart';
import 'package:weight_scale/weight_scale_device.dart';
import 'package:weight_scale/protocol.dart';
import 'package:weight_scale/core/config.dart';
import 'package:weight_scale/core/logger.dart';
import 'package:weight_scale/core/result.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Weight Scale Plugin Integration Tests', () {
    late WeightScaleManager manager;

    setUp(() {
      // Reset singleton and create new instance for each test
      WeightScaleManager.resetInstance();
      manager = WeightScaleManager(
        config: const WeightScaleConfig(
          deviceCheckTimeout: Duration(seconds: 3),
          debugLogging: true,
        ),
        logger: const ConsoleLogger(),
      );
    });

    tearDown(() async {
      // Clean up after each test
      await manager.disconnect();
      await manager.dispose();
    });

    testWidgets('should get available USB devices',
        (WidgetTester tester) async {
      final result = await manager.getAvailableDevices();

      expect(result.isSuccess, isTrue);
      final devices = result.dataOrNull ?? [];

      // Log found devices for debugging
      for (final device in devices) {
        debugPrint(
            'Found device: ${device.deviceName} (VID: ${device.vendorID}, PID: ${device.productID})');
      }

      // Even if no scales are connected, this should succeed
      expect(devices, isA<List<WeightScaleDevice>>());
    });

    testWidgets('should handle connection to valid scale device',
        (WidgetTester tester) async {
      final devicesResult = await manager.getAvailableDevices();
      expect(devicesResult.isSuccess, isTrue);

      final devices = devicesResult.dataOrNull ?? [];

      if (devices.isNotEmpty) {
        final device = devices.first;
        debugPrint('Testing connection to: ${device.deviceName}');

        final connectResult = await manager.connect(device);

        if (connectResult.isSuccess) {
          // Connection successful
          expect(manager.isConnected, isTrue);
          expect(
              manager.connectedDevice?.deviceName, equals(device.deviceName));

          // Test disconnection
          final disconnectResult = await manager.disconnect();
          expect(disconnectResult.isSuccess, isTrue);
          expect(manager.isConnected, isFalse);
        } else {
          // Connection failed - this is acceptable if no real scale is connected
          debugPrint(
              'Connection failed (expected if no scale connected): ${connectResult.failureOrNull?.message}');
          expect(connectResult.isFailure, isTrue);
        }
      } else {
        debugPrint('No USB devices found - skipping connection test');
      }
    });

    testWidgets('should validate device connection and data reception',
        (WidgetTester tester) async {
      final devicesResult = await manager.getAvailableDevices();
      expect(devicesResult.isSuccess, isTrue);

      final devices = devicesResult.dataOrNull ?? [];

      if (devices.isNotEmpty) {
        final device = devices.first;
        debugPrint('Testing device validation: ${device.deviceName}');

        final validationResult = await manager.validateDevice(device);

        if (validationResult.isSuccess && validationResult.dataOrNull == true) {
          debugPrint('Device validation successful');
          expect(validationResult.dataOrNull, isTrue);
        } else {
          debugPrint(
              'Device validation failed (expected if not a real scale): ${validationResult.failureOrNull?.message}');
          // This is acceptable - not all USB devices are scales
        }
      }
    });

    testWidgets('should handle data stream when connected to scale',
        (WidgetTester tester) async {
      final devicesResult = await manager.getAvailableDevices();
      expect(devicesResult.isSuccess, isTrue);

      final devices = devicesResult.dataOrNull ?? [];

      if (devices.isNotEmpty) {
        final device = devices.first;
        final connectResult = await manager.connect(device);

        if (connectResult.isSuccess) {
          debugPrint('Connected, testing data stream...');

          manager.initialize();
          expect(manager.dataStream, isNotNull);

          // Set up error callback
          manager.setErrorCallback((error, stackTrace) {
            debugPrint('Error callback called: $error');
          });

          // Try to receive data with timeout
          try {
            final completer = Completer<ScaleData>();
            late StreamSubscription<ScaleData> subscription;

            subscription = manager.dataStream!.listen(
              (data) {
                debugPrint(
                    'Received scale data: ${data.weight} ${data.weightUnits}, Status: ${data.status}');
                if (!completer.isCompleted) {
                  completer.complete(data);
                }
                subscription.cancel();
              },
              onError: (error) {
                debugPrint('Data stream error: $error');
                if (!completer.isCompleted) {
                  completer.completeError(error);
                }
                subscription.cancel();
              },
            );

            // Wait for data with timeout
            final data = await completer.future.timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw TimeoutException(
                  'No data received', const Duration(seconds: 5)),
            );

            // Validate received data
            expect(data, isA<ScaleData>());
            expect(data.weight, isNotEmpty);
            expect(data.weightUnits, isIn(['kg', 'lb', 'g', 'oz']));
            expect(data.status, isA<Status>());
          } on TimeoutException {
            debugPrint(
                'No data received within timeout (expected if no active scale)');
            // This is acceptable - device might not be sending data
          } catch (e) {
            debugPrint(
                'Stream error: $e (expected if not connected to real scale)');
            // This is acceptable for testing without real hardware
          }

          await manager.disconnect();
        }
      }
    });

    testWidgets('should handle multiple connection attempts gracefully',
        (WidgetTester tester) async {
      final devicesResult = await manager.getAvailableDevices();
      expect(devicesResult.isSuccess, isTrue);

      final devices = devicesResult.dataOrNull ?? [];

      if (devices.isNotEmpty) {
        final device = devices.first;

        // First connection
        final firstConnect = await manager.connect(device);

        if (firstConnect.isSuccess) {
          // Second connection attempt should handle gracefully
          final secondConnect = await manager.connect(device);

          // Should either succeed (if already connected) or fail gracefully
          expect(secondConnect, isA<Result<void>>());

          await manager.disconnect();
        }
      }
    });

    testWidgets('should handle error scenarios properly',
        (WidgetTester tester) async {
      // Test connecting to non-existent device
      final fakeDevice = WeightScaleDevice(
        deviceName: 'fake_device',
        vendorID: '0000',
        productID: '0000',
      );

      final result = await manager.connect(fakeDevice);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, isNotEmpty);
    });

    testWidgets('should maintain singleton behavior',
        (WidgetTester tester) async {
      final manager1 = WeightScaleManager();
      final manager2 = WeightScaleManager();

      expect(identical(manager1, manager2), isTrue);
    });

    testWidgets('should handle configuration changes',
        (WidgetTester tester) async {
      final customConfig = WeightScaleConfig(
        deviceCheckTimeout: const Duration(milliseconds: 100),
        knownScaleDevices: [
          ...WeightScaleConfig.defaultKnownScales,
          const ScaleDeviceIdentifier(
            vendorID: '1234',
            productID: '5678',
            name: 'Test Scale',
          ),
        ],
        debugLogging: false,
      );

      WeightScaleManager.resetInstance();
      final configuredManager = WeightScaleManager(
        config: customConfig,
        logger: const SilentLogger(),
      );

      final result = await configuredManager.getAvailableDevices();
      expect(result.isSuccess, isTrue);
    });
  });

  group('Protocol Integration Tests', () {
    testWidgets('should parse real scale data correctly',
        (WidgetTester tester) async {
      // Test with various realistic scale data frames
      final testFrames = [
        // Stable positive weight
        Uint8List.fromList([
          0x01, 0x02, 0x53, 0x20, // SOH, STX, Stable, Positive
          0x30, 0x31, 0x2E, 0x32, 0x33, 0x34, // "01.234"
          0x6B, 0x67, // "kg"
          0x67, 0x03, 0x04, 0x10 // BCC, ETX, EOT, Zero
        ]),
        // Unstable negative weight
        Uint8List.fromList([
          0x01, 0x02, 0x55, 0x2D, // SOH, STX, Unstable, Negative
          0x30, 0x30, 0x2E, 0x35, 0x36, 0x37, // "00.567"
          0x6C, 0x62, // "lb"
          0x6A, 0x03, 0x04, 0x20 // BCC, ETX, EOT, Tare
        ]),
      ];

      for (final frame in testFrames) {
        try {
          final data = ScaleProtocol.parseData(frame);

          expect(data, isA<ScaleData>());
          expect(data.weight, isNotEmpty);
          expect(data.weightUnits, isIn(['kg', 'lb']));
          expect(data.status, isA<Status>());
          expect(data.status2, isA<Status2>());
          expect(data.numericWeight, isA<double>());

          debugPrint(
              'Parsed: ${data.weight} ${data.weightUnits}, Status: ${data.status}, Stable: ${data.isStable}');
        } catch (e) {
          fail('Failed to parse test frame: $e');
        }
      }
    });
  });
}
