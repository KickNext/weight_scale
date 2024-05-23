import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:weight_scale/protocol.dart';
import 'package:weight_scale/weight_scale_device.dart';

class WeightScaleManager {
  static const MethodChannel _methodChannel = MethodChannel('com.kicknext.weight_scale');
  static const EventChannel _eventChannel = EventChannel('com.kicknext.weight_scale/events');

  static final WeightScaleManager _instance = WeightScaleManager._internal();
  factory WeightScaleManager() => _instance;
  WeightScaleManager._internal();

  WeightScaleDevice? _connectedDevice;
  Stream<ScaleData>? _dataStream;
  StreamSubscription<ScaleData>? _dataSubscription;

  // Callback for error handling
  void Function(Object error, StackTrace stackTrace)? onErrorCallback;

  // Get list of connected devices
  Future<List<WeightScaleDevice>> getDevices() async {
    try {
      final devices = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getDevices');
      if (devices == null) return [];

      List<WeightScaleDevice> deviceList = devices.entries.map((entry) {
        final deviceInfo = (entry.value as String).split(':');
        return WeightScaleDevice(
          deviceName: entry.key as String,
          vendorID: deviceInfo[0],
          productID: deviceInfo[1],
        );
      }).toList();

      return await _filterValidDevices(deviceList);
    } on PlatformException catch (e, stackTrace) {
      _handleError(e, stackTrace, 'getDevices');
      return [];
    }
  }

  Future<List<WeightScaleDevice>> _filterValidDevices(List<WeightScaleDevice> devices) async {
    List<WeightScaleDevice> validDevices = [];
    for (var device in devices) {
      if (await _checkDevice(device)) {
        validDevices.add(device);
      }
    }
    return validDevices;
  }

  // Connect to a device
  Future<void> connect(WeightScaleDevice device) async {
    try {
      await _methodChannel.invokeMethod('connect', {"deviceId": device.deviceName});
      device.isConnected = true;
      _connectedDevice = device;

      // Initialize data stream
      _initializeDataStream();
    } on PlatformException catch (e, stackTrace) {
      _handleError(e, stackTrace, 'connect');
      device.isConnected = false;
    }
  }

  // Disconnect from the device
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnect');
      _connectedDevice?.isConnected = false;
      _connectedDevice = null;

      // Cancel data stream subscription and clear data stream
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      _dataStream = null;
    } on PlatformException catch (e, stackTrace) {
      _handleError(e, stackTrace, 'disconnect');
    }
  }

  // Initialize data stream
  void _initializeDataStream() {
    _dataStream =
        _eventChannel.receiveBroadcastStream().map(_parseEvent).where((event) => event != null).cast<ScaleData>();

    // Subscribe to the data stream
    _dataSubscription = _dataStream!.listen((data) {
      // Handle incoming data
      _debugPrint('WeightScaleManager: Received data: $data');
    }, onError: (error, stackTrace) {
      _handleError(error, stackTrace, '_initializeDataStream');
    });
  }

  ScaleData? _parseEvent(dynamic event) {
    if (event is Uint8List) {
      try {
        return ScaleProtocol.parseData(event);
      } catch (e, stackTrace) {
        _handleError(e, stackTrace, '_parseEvent');
        return null;
      }
    } else {
      _handleError(const FormatException("Received unknown data format"), StackTrace.current, '_parseEvent');
      return null;
    }
  }

  // Get a stream of data from the device
  Stream<ScaleData>? get dataStream => _dataStream;

  // Get the connected device
  WeightScaleDevice? get connectedDevice => _connectedDevice;

  // Check if a device is connected
  bool get isConnected => _connectedDevice != null;

  // Check if the device sends data within 500 ms
  Future<bool> _checkDevice(WeightScaleDevice device) async {
    final completer = Completer<bool>();

    // Connect to the device
    await connect(device);

    // Listen for data and complete the future if data is received
    final subscription = dataStream!.listen((data) {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    });

    // Complete the future with false if no data is received within 500 ms
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      await subscription.cancel();
      await disconnect();
    });

    return completer.future;
  }

  // Handle errors
  void _handleError(Object error, StackTrace stackTrace, String context) {
    _debugPrint('WeightScaleManager: Error in $context: $error\nStack trace: $stackTrace');
    onErrorCallback?.call(error, stackTrace);
  }

  void _debugPrint(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
