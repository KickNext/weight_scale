import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:weight_scale/protocol.dart';
import 'package:weight_scale/weight_scale_manager.dart';
import 'package:weight_scale/weight_scale_device.dart';
import 'package:weight_scale/core/result.dart';

class WeightScaleApp extends StatefulWidget {
  const WeightScaleApp({super.key});

  @override
  WeightScaleAppState createState() => WeightScaleAppState();
}

class WeightScaleAppState extends State<WeightScaleApp> {
  final WeightScaleManager _weightScaleManager = WeightScaleManager();
  List<WeightScaleDevice> _devices = [];
  ScaleData? _data;
  StreamSubscription<ScaleData>? _dataSubscription;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // Set up error callback for WeightScaleManager
    _weightScaleManager.setErrorCallback((error, stackTrace) {
      _showError('Connection error: ${error.toString()}');
    });

    // Only try to get devices on Android
    if (_isAndroid) {
      _getDevices();
    }
  }

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  String get _platformMessage {
    if (kIsWeb) {
      return 'Web platform is not supported. This plugin requires Android with USB host support.';
    } else if (Platform.isAndroid) {
      return 'Android platform detected. USB scales supported.';
    } else if (Platform.isIOS) {
      return 'iOS platform is not supported. iOS does not support USB host mode without MFi accessories.';
    } else if (Platform.isWindows) {
      return 'Windows platform is not supported in this version.';
    } else if (Platform.isMacOS) {
      return 'macOS platform is not supported in this version.';
    } else if (Platform.isLinux) {
      return 'Linux platform is not supported in this version.';
    } else {
      return 'Unknown platform. Only Android is supported.';
    }
  }

  Future<void> _getDevices() async {
    if (!_isAndroid) return;

    final result = await _weightScaleManager.getAvailableDevices();
    result.fold(
      (devices) {
        setState(() {
          _devices = devices;
        });
      },
      (failure) {
        _showError('Failed to get devices: ${failure.message}');
      },
    );
  }

  Future<void> _connect(WeightScaleDevice device) async {
    final result = await _weightScaleManager.connect(device);
    result.fold(
      (_) {
        // Connection successful, set up data stream
        _dataSubscription?.cancel();
        _dataSubscription = _weightScaleManager.dataStream?.listen(
          (data) {
            setState(() {
              _data = data;
            });
          },
          onError: (error, stackTrace) {
            _showError('Data stream error: ${error.toString()}');
          },
        );
        setState(() {});
      },
      (failure) {
        _showError('Failed to connect: ${failure.message}');
      },
    );
  }

  Future<void> _disconnect() async {
    final result = await _weightScaleManager.disconnect();
    result.fold(
      (_) {
        // Disconnect successful
        _dataSubscription?.cancel();
        _dataSubscription = null;
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _data = null;
          });
        });
      },
      (failure) {
        _showError('Failed to disconnect: ${failure.message}');
        // Still cleanup local state even if disconnect failed
        _dataSubscription?.cancel();
        _dataSubscription = null;
        setState(() {
          _data = null;
        });
      },
    );
  }

  void _showError(String message) {
    _scaffoldMessengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text('Error: $message')));
  }

  @override
  void dispose() {
    _weightScaleManager.disconnect();
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Weight Scale Example'),
          actions: [
            if (_isAndroid)
              ElevatedButton(
                  onPressed: _getDevices, child: const Text('Find devices')),
          ],
        ),
        body: Center(
          child: !_isAndroid
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Platform Not Supported',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _platformMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'This plugin requires Android with USB host support to communicate with commercial weight scales.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 3,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                            border:
                                Border(right: BorderSide(color: Colors.black))),
                        child: _devices.isEmpty
                            ? const Center(child: Text('No devices found'))
                            : ListView(
                                children: _devices
                                    .map((device) => ListTile(
                                          title: Text(device.deviceName),
                                          subtitle: Text(
                                              '${device.productID}:${device.vendorID}'),
                                          trailing: _weightScaleManager
                                                          .connectedDevice
                                                          ?.deviceName ==
                                                      device.deviceName &&
                                                  (_weightScaleManager
                                                          .connectedDevice
                                                          ?.isConnected ??
                                                      false)
                                              ? const Icon(Icons.check)
                                              : null,
                                          onTap: () => _weightScaleManager
                                                          .connectedDevice
                                                          ?.deviceName ==
                                                      device.deviceName &&
                                                  (_weightScaleManager
                                                          .connectedDevice
                                                          ?.isConnected ??
                                                      false)
                                              ? _disconnect()
                                              : _connect(device),
                                        ))
                                    .toList(),
                              ),
                      ),
                    ),
                    Expanded(
                      child: _data == null
                          ? const Center(child: Text('No data received'))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Status: ${_data?.status.toString().split('.').last}',
                                  style: const TextStyle(fontSize: 36),
                                ),
                                Text(
                                  '${double.parse(_data?.weight ?? '0').toString()} ${_data?.weightUnits}',
                                  style: const TextStyle(
                                    fontSize: 100,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Tare: ${_data?.status2.toString().split('.').last}',
                                  style: const TextStyle(fontSize: 36),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

void main() => runApp(const WeightScaleApp());
