import 'package:flutter/services.dart';
import 'package:weight_scale/protocol.dart';

class WeightScale {
  static const MethodChannel _methodChannel = MethodChannel('com.kicknext.weight_scale');
  static const EventChannel _eventChannel = EventChannel('com.kicknext.weight_scale/events');

  // Singleton pattern
  static final WeightScale _instance = WeightScale._internal();
  factory WeightScale() => _instance;
  WeightScale._internal();

  // Stream for receiving data
  Stream<ScaleData>? _dataStream;

  // Get list of connected devices
  Future<Map<String, String>> getDevices() async {
    try {
      final devices = await _methodChannel.invokeMethod<Map>('getDevices');
      return devices?.cast<String, String>() ?? {};
    } on PlatformException catch (e) {
      print("Failed to get devices: '${e.message}'.");
      return {};
    }
  }

  // Connect to a device by its ID
  Future<void> connect(String deviceId) async {
    try {
      await _methodChannel.invokeMethod('connect', {"deviceId": deviceId});
    } on PlatformException catch (e) {
      print("Failed to connect: '${e.message}'.");
    }
  }

  // Disconnect from the device
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      print("Failed to disconnect: '${e.message}'.");
    }
  }

  // Get a stream of data from the device
  Stream<ScaleData> get dataStream {
    _dataStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Uint8List) {
        try {
          return ScaleProtocol.parseData(event);
        } catch (e) {
          print("Failed to parse data: $e");
          return null;
        }
      } else {
        print("Received unknown data format");
        return null;
      }
    }).where((event) => event != null).cast<ScaleData>();
    return _dataStream!;
  }
}
