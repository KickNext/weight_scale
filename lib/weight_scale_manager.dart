import 'dart:async';
import 'package:flutter/services.dart';
import 'package:weight_scale/core/result.dart';
import 'package:weight_scale/core/config.dart';
import 'package:weight_scale/core/logger.dart';
import 'package:weight_scale/repositories/device_repository.dart';
import 'package:weight_scale/data/data_stream.dart';
import 'package:weight_scale/protocol.dart';
import 'package:weight_scale/weight_scale_device.dart';

/// Main manager class for weight scale operations
/// Implements singleton pattern to prevent multiple USB connections
class WeightScaleManager
    implements WeightScaleDeviceRepository, WeightScaleDataStream {
  static const MethodChannel _methodChannel =
      MethodChannel('com.kicknext.weight_scale');
  static const EventChannel _eventChannel =
      EventChannel('com.kicknext.weight_scale/events');

  static WeightScaleManager? _instance;
  final WeightScaleConfig _config;
  final WeightScaleLogger _logger;

  WeightScaleDevice? _connectedDevice;
  Stream<ScaleData>? _dataStream;
  StreamSubscription<ScaleData>? _dataSubscription;
  void Function(Object error, StackTrace stackTrace)? _errorCallback;

  WeightScaleManager._internal({
    WeightScaleConfig? config,
    WeightScaleLogger? logger,
  })  : _config = config ?? const WeightScaleConfig(),
        _logger = logger ?? const ConsoleLogger();

  /// Get singleton instance with optional configuration
  factory WeightScaleManager({
    WeightScaleConfig? config,
    WeightScaleLogger? logger,
  }) {
    return _instance ??= WeightScaleManager._internal(
      config: config,
      logger: logger,
    );
  }

  /// Reset singleton instance (for testing)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  @override
  Future<Result<List<WeightScaleDevice>>> getAvailableDevices() async {
    try {
      _logger.debug('Getting available devices...');
      final devices = await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>('getDevices');

      if (devices == null) {
        _logger.warning('No devices returned from platform channel');
        return const Success([]);
      }

      final deviceList = devices.entries.map((entry) {
        final deviceInfo = (entry.value as String).split(':');
        return WeightScaleDevice(
          deviceName: entry.key as String,
          vendorID: deviceInfo[0],
          productID: deviceInfo[1],
        );
      }).toList();

      _logger.debug('Found ${deviceList.length} USB devices');
      return Success(await _filterValidDevices(deviceList));
    } on PlatformException catch (e, stackTrace) {
      _logger.error('Failed to get devices', e, stackTrace);
      return Failure('Failed to get devices: ${e.message}',
          error: e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      _logger.error('Unexpected error getting devices', e, stackTrace);
      return Failure('Unexpected error: ${e.toString()}',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<List<WeightScaleDevice>> _filterValidDevices(
      List<WeightScaleDevice> devices) async {
    final validDevices = <WeightScaleDevice>[];
    _logger
        .debug('Filtering ${devices.length} devices against known scale IDs');

    for (final device in devices) {
      _logger.debug(
          'Checking device: ${device.deviceName} (VID: ${device.vendorID}, PID: ${device.productID})');

      final isKnownScale =
          _config.knownScaleDevices.any((id) => id.matches(device));

      if (isKnownScale) {
        _logger.debug(
            'Device ${device.deviceName} is a known scale, validating...');
        final validationResult = await validateDevice(device);

        if (validationResult.isSuccess && validationResult.dataOrNull == true) {
          _logger.info('Device ${device.deviceName} validated successfully');
          validDevices.add(device);
        } else {
          _logger.warning(
              'Device ${device.deviceName} validation failed: ${validationResult.failureOrNull?.message}');
        }
      } else {
        _logger
            .debug('Skipping device ${device.deviceName} - not a known scale');
      }
    }

    _logger.info('Found ${validDevices.length} valid scale devices');
    return validDevices;
  }

  @override
  Future<Result<void>> connect(WeightScaleDevice device) async {
    try {
      _logger.debug('Connecting to device: ${device.deviceName}');

      await _methodChannel.invokeMethod('connect', {
        "deviceName": device.deviceName,
        "vendorID": device.vendorID,
        "productID": device.productID,
      });

      device.isConnected = true;
      _connectedDevice = device;
      initialize();

      _logger.info('Successfully connected to ${device.deviceName}');
      return const Success(null);
    } on PlatformException catch (e, stackTrace) {
      _logger.error('Failed to connect to ${device.deviceName}', e, stackTrace);
      device.isConnected = false;
      return Failure('Connection failed: ${e.message}',
          error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<void>> disconnect() async {
    try {
      _logger.debug('Disconnecting from current device');

      await _methodChannel.invokeMethod('disconnect');
      _connectedDevice?.isConnected = false;
      _connectedDevice = null;

      await dispose();

      _logger.info('Successfully disconnected');
      return const Success(null);
    } on PlatformException catch (e, stackTrace) {
      _logger.error('Failed to disconnect', e, stackTrace);
      return Failure('Disconnect failed: ${e.message}',
          error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<bool>> validateDevice(WeightScaleDevice device) async {
    _logger.debug('Validating device: ${device.deviceName}');

    try {
      final connectResult = await connect(device);
      if (connectResult.isFailure) {
        return Failure(
            'Connection failed during validation: ${connectResult.failureOrNull?.message}');
      }

      if (_connectedDevice?.deviceName != device.deviceName) {
        return const Failure('Device connection state inconsistent');
      }

      // Wait for first data packet with timeout
      try {
        await dataStream!.first.timeout(_config.deviceCheckTimeout);
        _logger.debug('Device ${device.deviceName} sent data successfully');
        return const Success(true);
      } on TimeoutException catch (e, stackTrace) {
        _logger.debug('Device ${device.deviceName} validation timeout: $e');
        return Failure(
            'Device validation timeout: No data received within ${_config.deviceCheckTimeout}',
            error: e,
            stackTrace: stackTrace);
      } on PlatformException catch (e, stackTrace) {
        if (e.code == 'CONNECTION_LOST') {
          // Connection lost during validation is expected behavior
          _logger.debug(
              'Device ${device.deviceName} validation completed with connection lost (expected)');
          return const Success(true);
        } else {
          _logger.debug(
              'Device ${device.deviceName} validation failed with platform error: $e');
          return Failure('Platform validation error: ${e.message}',
              error: e, stackTrace: stackTrace);
        }
      }
    } catch (e, stackTrace) {
      _logger.debug('Device ${device.deviceName} validation failed: $e');
      return Failure('Validation failed: ${e.toString()}',
          error: e, stackTrace: stackTrace);
    } finally {
      // Always disconnect after validation
      if (_connectedDevice?.deviceName == device.deviceName) {
        final disconnectResult = await disconnect();
        if (disconnectResult.isFailure) {
          _logger.debug(
              'Failed to disconnect after validation, but continuing...');
        }
      }
    }
  }

  @override
  void initialize() {
    _logger.debug('Initializing data stream');

    _dataStream = _eventChannel
        .receiveBroadcastStream()
        .map(_parseEvent)
        .where((event) => event != null)
        .cast<ScaleData>()
        .handleError((error, stackTrace) {
      _logger.error('Data stream error', error, stackTrace);
      _errorCallback?.call(error, stackTrace);

      // Handle CONNECTION_LOST specifically without crashing
      if (error is PlatformException && error.code == 'CONNECTION_LOST') {
        _logger.debug('Connection lost - cleaning up stream');
        _dataSubscription?.cancel();
        _dataSubscription = null;
        _dataStream = null;
        _connectedDevice?.isConnected = false;
        _connectedDevice = null;
      }
    });

    _dataSubscription = _dataStream!.listen(
      (data) => _logger.debug('Received scale data: $data'),
      onError: (error, stackTrace) {
        _logger.error('Data stream error', error, stackTrace);
        _errorCallback?.call(error, stackTrace);

        // Handle CONNECTION_LOST specifically without crashing
        if (error is PlatformException && error.code == 'CONNECTION_LOST') {
          _logger.debug('Connection lost in subscription - cleaning up');
          _dataSubscription?.cancel();
          _dataSubscription = null;
          _dataStream = null;
          _connectedDevice?.isConnected = false;
          _connectedDevice = null;
        }
      },
      cancelOnError: false, // Don't cancel on error, handle gracefully
    );
  }

  @override
  Future<void> dispose() async {
    _logger.debug('Disposing resources');
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    _dataStream = null;
  }

  @override
  void setErrorCallback(
      void Function(Object error, StackTrace stackTrace)? callback) {
    _errorCallback = callback;
  }

  ScaleData? _parseEvent(dynamic event) {
    if (event is Uint8List) {
      try {
        return ScaleProtocol.parseData(event);
      } catch (e, stackTrace) {
        _logger.error('Failed to parse scale data', e, stackTrace);
        _errorCallback?.call(e, stackTrace);
        return null;
      }
    } else {
      const error = FormatException("Received unknown data format");
      _logger.error('Unknown data format received', error);
      _errorCallback?.call(error, StackTrace.current);
      return null;
    }
  }

  @override
  Stream<ScaleData>? get dataStream => _dataStream;

  @override
  WeightScaleDevice? get connectedDevice => _connectedDevice;

  @override
  bool get isConnected => _connectedDevice != null;

  // Legacy API compatibility
  Future<List<WeightScaleDevice>> getDevices() async {
    final result = await getAvailableDevices();
    return result.dataOrNull ?? [];
  }

  // Legacy API compatibility
  void Function(Object error, StackTrace stackTrace)? get onErrorCallback =>
      _errorCallback;
  set onErrorCallback(
      void Function(Object error, StackTrace stackTrace)? callback) {
    setErrorCallback(callback);
  }
}
