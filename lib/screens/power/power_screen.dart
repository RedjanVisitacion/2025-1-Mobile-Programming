import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

class PowerScreen extends StatefulWidget {
  const PowerScreen({super.key});
  @override
  State<PowerScreen> createState() => _PowerScreenState();
}

class _PowerScreenState extends State<PowerScreen> {
  final Battery _battery = Battery();
  int? _level;
  BatteryState? _state;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final lvl = await _battery.batteryLevel;
    final st = await _battery.batteryState;
    if (!mounted) return;
    setState(() {
      _level = lvl;
      _state = st;
    });
    _battery.onBatteryStateChanged.listen((s) {
      if (!mounted) return;
      setState(() {
        _state = s;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Power')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_level == null ? '...' : 'Battery: $_level%'),
          const SizedBox(height: 8),
          Text('State: ${_state?.name ?? '...'}'),
        ]),
      ),
    );
  }
}
