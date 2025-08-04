import 'dart:async';
import 'package:flutter/material.dart';
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

    _getDevices();
  }

  Future<void> _getDevices() async {
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
            ElevatedButton(
                onPressed: _getDevices, child: const Text('Find devices')),
          ],
        ),
        body: Center(
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.black))),
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
                                            (_weightScaleManager.connectedDevice
                                                    ?.isConnected ??
                                                false)
                                        ? const Icon(Icons.check)
                                        : null,
                                    onTap: () => _weightScaleManager
                                                    .connectedDevice
                                                    ?.deviceName ==
                                                device.deviceName &&
                                            (_weightScaleManager.connectedDevice
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
