import 'dart:async';
import 'package:flutter/services.dart';

class WeightScale {
  static const MethodChannel _channel = MethodChannel('com.kicknext.weight_scale/serial');

  /// Получение списка подключенных USB-устройств
  static Future<Map<String, String>> getDevices() async {
    final Map<dynamic, dynamic> result = await _channel.invokeMethod('getDevices');
    return Map<String, String>.from(result);
  }

  /// Подключение к указанному устройству по его ID
  static Future<void> connect(String deviceId) async {
    try {
      await _channel.invokeMethod('connect', {'deviceId': deviceId});
    } on PlatformException catch (e) {
      print("Failed to connect: '${e.message}'.");
    }
  }

  /// Отключение от устройства
  static Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      print("Failed to disconnect: '${e.message}'.");
    }
  }

  /// Запись данных в устройство
  static Future<void> write(String data) async {
    try {
      await _channel.invokeMethod('write', {'data': data});
    } on PlatformException catch (e) {
      print("Failed to write: '${e.message}'.");
    }
  }

  /// Чтение данных из устройства
  static Future<String> read() async {
    try {
      final String result = await _channel.invokeMethod('read');
      return result;
    } on PlatformException catch (e) {
      print("Failed to read: '${e.message}'.");
      return '';
    }
  }
}
