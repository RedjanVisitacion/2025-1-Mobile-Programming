import 'dart:io' show Platform;
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});
  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  bool _scanning = false;
  final Map<String, ScanResult> _byId = {};
  StreamSubscription<List<ScanResult>>? _sub;
  String _filter = '';

  Future<void> _start() async {
    if (_scanning) return;
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final btScan = await Permission.bluetoothScan.status;
        if (!btScan.isGranted) {
          final r = await Permission.bluetoothScan.request();
          if (!r.isGranted) return;
        }

        var locPerm = await Permission.locationWhenInUse.status;
        if (!locPerm.isGranted) {
          locPerm = await Permission.locationWhenInUse.request();
          if (!locPerm.isGranted) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission is required to scan for Bluetooth')));
            return;
          }
        }

        final service = await Permission.locationWhenInUse.serviceStatus;
        if (!service.isEnabled) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turn on Location services (GPS) to scan for Bluetooth')));
          return;
        }
      }
    }

    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turn on Bluetooth to start scanning')));
        try { await FlutterBluePlus.turnOn(); } catch (_) {}
        return;
      }
    } catch (_) {}

    setState(() {
      _scanning = true;
      _byId.clear();
    });

    _sub?.cancel();
    _sub = FlutterBluePlus.scanResults.listen((r) {
      for (final s in r) {
        _byId[s.device.remoteId.str] = s;
      }
      if (!mounted) return;
      setState(() {});
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to start scan: $e')));
      setState(() { _scanning = false; });
      return;
    }

    if (!mounted) return;
    setState(() { _scanning = false; });
  }

  Future<void> _stop() async {
    await FlutterBluePlus.stopScan();
    if (!mounted) return;
    setState(() { _scanning = false; });
  }

  Future<void> _rescan() async {
    if (_scanning) {
      await _stop();
    }
    await _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _byId.values
        .where((r) => _filter.isEmpty || r.advertisementData.advName.toLowerCase().contains(_filter.toLowerCase()) || r.device.remoteId.str.toLowerCase().contains(_filter.toLowerCase()))
        .toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('Bluetooth'),
          const SizedBox(width: 8),
          if (_scanning) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
        actions: [
          IconButton(onPressed: _scanning ? _stop : _start, icon: Icon(_scanning ? Icons.stop : Icons.play_arrow)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Filter by name or ID'),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _rescan,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (c, i) {
                final r = items[i];
                final adv = r.advertisementData.advName;
                final name = (adv.isNotEmpty) ? adv : r.device.remoteId.str;
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(name),
                  subtitle: Text('RSSI ${r.rssi}'),
                  onTap: () {
                    () async {
                      if (_scanning) {
                        await _stop();
                      }
                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DeviceScreen(device: r.device)),
                      );
                    }();
                  },
                );
              },
            ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _rescan, child: const Icon(Icons.refresh)),
    );
  }
}
