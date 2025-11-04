import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = const [];
  bool _busy = false;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    widget.device.connectionState.listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
    });
  }

  Future<void> _connect() async {
    if (_state == BluetoothConnectionState.connected || _busy || _connecting) return;
    setState(() {
      _busy = true;
      _connecting = true;
    });
    try {
      await widget.device.connect(timeout: const Duration(seconds: 10));
      try {
        await widget.device.connectionState
            .firstWhere((s) => s == BluetoothConnectionState.connected)
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
      _services = await widget.device.discoverServices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connect failed: $e')));
    } finally {
      if (mounted) setState(() {
        _busy = false;
        _connecting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    if (_state != BluetoothConnectionState.connected || _busy || _connecting) return;
    setState(() => _busy = true);
    try {
      await widget.device.disconnect();
      _services = const [];
    } catch (_) {} finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshServices() async {
    if (_state != BluetoothConnectionState.connected) return;
    try {
      final s = await widget.device.discoverServices();
      if (!mounted) return;
      setState(() => _services = s);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Discover failed: $e')));
    }
  }

  Future<void> _readCharacteristic(BluetoothCharacteristic c) async {
    try {
      final v = await c.read();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Read ${c.characteristicUuid}: ${v.length} bytes')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Read failed: $e')));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.advName.isNotEmpty ? widget.device.advName : widget.device.remoteId.str),
        actions: [
          if (_state == BluetoothConnectionState.connected)
            IconButton(onPressed: _refreshServices, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('State: ${_state.name}'),
            trailing: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : (_state == BluetoothConnectionState.connected
                    ? FilledButton(onPressed: _disconnect, child: const Text('Disconnect'))
                    : FilledButton(onPressed: _connect, child: const Text('Connect'))),
          ),
          const Divider(height: 1),
          Expanded(
            child: (_state == BluetoothConnectionState.connected)
                ? ListView.builder(
                    itemCount: _services.length,
                    itemBuilder: (c, i) {
                      final s = _services[i];
                      return ExpansionTile(
                        leading: const Icon(Icons.miscellaneous_services),
                        title: Text('Service ${s.serviceUuid.str}'),
                        children: [
                          ...s.characteristics.map((ch) {
                            final props = ch.properties;
                            final canRead = props.read;
                            return ListTile(
                              title: Text('Char ${ch.characteristicUuid.str}'),
                              subtitle: Text('props: ${[
                                if (props.read) 'read',
                                if (props.write) 'write',
                                if (props.notify) 'notify',
                                if (props.indicate) 'indicate',
                              ].join(', ')}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canRead)
                                    IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed: () => _readCharacteristic(ch),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  )
                : const Center(child: Text('Not connected')),
          ),
        ],
      ),
    );
  }
}
