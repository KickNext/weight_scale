import 'package:flutter/material.dart';
import 'package:weight_scale/protocol.dart';
import 'package:weight_scale/weight_scale.dart';

class WeightScaleApp extends StatefulWidget {
  const WeightScaleApp({super.key});

  @override
  WeightScaleAppState createState() => WeightScaleAppState();
}

class WeightScaleAppState extends State<WeightScaleApp> {
  final WeightScale _weightScale = WeightScale();
  Map<String, String> _devices = {};
  ScaleData? _data;
  String? _connectedDeviceId;

  @override
  void initState() {
    super.initState();
    _weightScale.dataStream.listen((data) {
      setState(() {
        _data = data;
      });
    });
  }

  Future<void> _getDevices() async {
    _devices = await _weightScale.getDevices();
    setState(() {});
  }

  Future<void> _connect(String deviceId) async {
    setState(() {
      _connectedDeviceId = deviceId;
    });
    await _weightScale.connect(deviceId);
  }

  Future<void> _disconnect() async {
    await _weightScale.disconnect();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _connectedDeviceId = null;
        _data = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Weight Scale Example'),
          actions: [
            ElevatedButton(onPressed: _getDevices, child: const Text('Find devices')),
          ],
        ),
        body: Center(
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                child: DecoratedBox(
                  decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
                  child: _devices.isEmpty
                      ? const Center(child: Text('No devices found'))
                      : ListView(
                          children: _devices.entries
                              .map((entry) => ListTile(
                                    title: Text(entry.key),
                                    subtitle: Text(entry.value),
                                    trailing: _connectedDeviceId == entry.key ? const Icon(Icons.check) : null,
                                    onTap: () => _connectedDeviceId == entry.key ? _disconnect() : _connect(entry.key),
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
                            '${_data?.sign}${double.parse(_data?.weight ?? '0').toString()} ${_data?.weightUnits}',
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
