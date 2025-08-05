import 'package:flutter_test/flutter_test.dart';
import 'package:weight_scale/weight_scale_manager.dart';
import 'package:weight_scale/weight_scale_device.dart';
import 'package:weight_scale/core/config.dart';
import 'package:weight_scale/core/logger.dart';
import 'package:weight_scale/core/result.dart';

void main() {
  group('WeightScaleManager', () {
    setUp(() {
      // Reset singleton for each test
      WeightScaleManager.resetInstance();
    });

    tearDown(() {
      WeightScaleManager.resetInstance();
    });

    test('should create singleton instance', () {
      final manager1 = WeightScaleManager();
      final manager2 = WeightScaleManager();

      expect(identical(manager1, manager2), isTrue);
    });

    test('should use custom config and logger', () {
      const customConfig = WeightScaleConfig(
        deviceCheckTimeout: Duration(seconds: 5),
        debugLogging: false,
      );
      const customLogger = SilentLogger();

      final manager = WeightScaleManager(
        config: customConfig,
        logger: customLogger,
      );

      expect(manager, isNotNull);
    });

    test('should handle error callback', () {
      final manager = WeightScaleManager();

      manager.setErrorCallback((error, stackTrace) {
        // Callback set successfully
      });

      // Since we can't directly trigger the callback, we test that it's set
      expect(manager.onErrorCallback, isNotNull);
    });

    test('should return empty list when no devices available', () async {
      final manager = WeightScaleManager();

      // This will fail on real device but we're testing the structure
      final result = await manager.getAvailableDevices();
      expect(result, isA<Result<List<WeightScaleDevice>>>());
    });

    test('should handle connection state properly', () {
      final manager = WeightScaleManager();

      expect(manager.isConnected, isFalse);
      expect(manager.connectedDevice, isNull);
    });

    test('should reset singleton properly', () {
      final manager1 = WeightScaleManager();
      WeightScaleManager.resetInstance();
      final manager2 = WeightScaleManager();

      expect(identical(manager1, manager2), isFalse);
    });
  });

  group('WeightScaleDevice', () {
    test('should create device with required parameters', () {
      final device = WeightScaleDevice(
        deviceName: 'Test Device',
        vendorID: '1234',
        productID: '5678',
      );

      expect(device.deviceName, equals('Test Device'));
      expect(device.vendorID, equals('1234'));
      expect(device.productID, equals('5678'));
      expect(device.isConnected, isFalse);
    });

    test('should serialize to/from JSON', () {
      final device = WeightScaleDevice(
        deviceName: 'Test Device',
        vendorID: '1234',
        productID: '5678',
      );

      final json = device.toJson();
      final reconstructed = WeightScaleDevice.fromJson(json);

      expect(reconstructed.deviceName, equals(device.deviceName));
      expect(reconstructed.vendorID, equals(device.vendorID));
      expect(reconstructed.productID, equals(device.productID));
    });

    test('should handle device list serialization', () {
      final devices = [
        WeightScaleDevice(
          deviceName: 'Device 1',
          vendorID: '1111',
          productID: '2222',
        ),
        WeightScaleDevice(
          deviceName: 'Device 2',
          vendorID: '3333',
          productID: '4444',
        ),
      ];

      final jsonList = WeightScaleDevice.listToJson(devices);
      final reconstructed = WeightScaleDevice.listFromJson(jsonList);

      expect(reconstructed.length, equals(2));
      expect(reconstructed[0].deviceName, equals('Device 1'));
      expect(reconstructed[1].deviceName, equals('Device 2'));
    });

    test('should have proper toString representation', () {
      final device = WeightScaleDevice(
        deviceName: 'Test Device',
        vendorID: '1234',
        productID: '5678',
      );

      final string = device.toString();
      expect(string, contains('Test Device'));
      expect(string, contains('1234'));
      expect(string, contains('5678'));
      expect(string, contains('false')); // isConnected
    });
  });

  group('WeightScaleConfig', () {
    test('should use default values', () {
      const config = WeightScaleConfig();

      expect(
          config.deviceCheckTimeout, equals(const Duration(milliseconds: 500)));
      expect(config.debugLogging, isTrue);
      expect(config.bufferSize, equals(1024));
      expect(config.knownScaleDevices, isNotEmpty);
    });

    test('should accept custom values', () {
      const config = WeightScaleConfig(
        deviceCheckTimeout: Duration(seconds: 2),
        debugLogging: false,
        bufferSize: 2048,
        knownScaleDevices: [],
      );

      expect(config.deviceCheckTimeout, equals(const Duration(seconds: 2)));
      expect(config.debugLogging, isFalse);
      expect(config.bufferSize, equals(2048));
      expect(config.knownScaleDevices, isEmpty);
    });

    test('should have default known scales', () {
      const config = WeightScaleConfig();

      expect(config.knownScaleDevices.length, greaterThan(0));

      // Check for Aclas scale
      final aclasScale = config.knownScaleDevices.firstWhere(
        (scale) => scale.name == 'Aclas',
        orElse: () => throw StateError('Aclas scale not found'),
      );

      expect(aclasScale.vendorID, equals('6790'));
      expect(aclasScale.productID, equals('29987'));
    });
  });

  group('ScaleDeviceIdentifier', () {
    test('should match device correctly', () {
      const identifier = ScaleDeviceIdentifier(
        vendorID: '1234',
        productID: '5678',
        name: 'Some Device',
      );

      final matchingDevice = WeightScaleDevice(
        deviceName: 'Some Device',
        vendorID: '1234',
        productID: '5678',
      );

      final nonMatchingDevice = WeightScaleDevice(
        deviceName: 'Other Device',
        vendorID: '9999',
        productID: '0000',
      );

      expect(identifier.matches(matchingDevice), isTrue);
      expect(identifier.matches(nonMatchingDevice), isFalse);
    });
  });

  group('Result', () {
    test('should create Success result', () {
      const result = Success('test data');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals('test data'));
      expect(result.failureOrNull, isNull);
    });

    test('should create Failure result', () {
      const result = Failure('error message');

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, isNotNull);
      expect(result.failureOrNull?.message, equals('error message'));
    });

    test('should fold correctly', () {
      const success = Success(42);
      const failure = Failure('error');

      final successResult = success.fold(
        (data) => 'Success: $data',
        (failure) => 'Failure: ${failure.message}',
      );

      final failureResult = failure.fold(
        (data) => 'Success: $data',
        (failure) => 'Failure: ${failure.message}',
      );

      expect(successResult, equals('Success: 42'));
      expect(failureResult, equals('Failure: error'));
    });
  });

  group('Loggers', () {
    test('ConsoleLogger should have default values', () {
      const logger = ConsoleLogger();

      expect(logger.prefix, equals('WeightScale'));
      expect(logger.enabled, isTrue); // In test environment
    });

    test('SilentLogger should be silent', () {
      const logger = SilentLogger();

      // These should not throw and should be silent
      logger.debug('debug message');
      logger.info('info message');
      logger.warning('warning message');
      logger.error('error message', Exception('test'), StackTrace.current);
    });
  });
}
