import 'package:flutter/material.dart';
import 'package:weight_scale/weight_scale.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('RS232 Plugin Example')),
        body: RS232Example(),
      ),
    );
  }
}

class RS232Example extends StatefulWidget {
  @override
  _RS232ExampleState createState() => _RS232ExampleState();
}

class _RS232ExampleState extends State<RS232Example> {
  Map<String, String> _devices = {};
  String _selectedDevice = '';

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  void _getDevices() async {
    final devices = await WeightScale.getDevices();
    setState(() {
      _devices = devices;
    });
  }

  void _connect() async {
    if (_selectedDevice.isNotEmpty) {
      await WeightScale.connect(_selectedDevice);
    }
  }

  void _disconnect() async {
    await WeightScale.disconnect();
  }

  void _write() async {
    // Пример данных для отправки
    await WeightScale.write('Example data');
  }

  void _read() async {
    final result = await WeightScale.read();
    print('Read data: $result');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          DropdownButton<String>(
            value: _selectedDevice.isEmpty ? null : _selectedDevice,
            hint: Text('Select a device'),
            onChanged: (String? newValue) {
              setState(() {
                _selectedDevice = newValue!;
              });
            },
            items: _devices.keys.map<DropdownMenuItem<String>>((String key) {
              return DropdownMenuItem<String>(
                value: key,
                child: Text(key),
              );
            }).toList(),
          ),
          ElevatedButton(onPressed: _connect, child: Text('Connect')),
          ElevatedButton(onPressed: _disconnect, child: Text('Disconnect')),
          ElevatedButton(onPressed: _write, child: Text('Write Data')),
          ElevatedButton(onPressed: _read, child: Text('Read Data')),
        ],
      ),
    );
  }
}
