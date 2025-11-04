import 'dart:io' show File, Platform;

import 'package:battery_plus/battery_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' as rec;
import 'package:path_provider/path_provider.dart';

late List<CameraDescription> _cameras;

Future<void> _ensurePermissions() async {
  if (kIsWeb) return; // Web has different permission model

  // Camera permission
  var camStatus = await Permission.camera.status;
  if (!camStatus.isGranted) {
    camStatus = await Permission.camera.request();
  }

  // Storage/media library (Android 13+ uses Photos; pre-13 uses Storage)
  if (Platform.isAndroid) {
    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }
  }
  var micStatus = await Permission.microphone.status;
  if (!micStatus.isGranted) {
    await Permission.microphone.request();
  }
  if (Platform.isAndroid) {
    var loc = await Permission.locationWhenInUse.status;
    if (!loc.isGranted) {
      await Permission.locationWhenInUse.request();
    }
    var bScan = await Permission.bluetoothScan.status;
    if (!bScan.isGranted) {
      await Permission.bluetoothScan.request();
    }
    var bConn = await Permission.bluetoothConnect.status;
    if (!bConn.isGranted) {
      await Permission.bluetoothConnect.request();
    }
    var bAdv = await Permission.bluetoothAdvertise.status;
    if (!bAdv.isGranted) {
      await Permission.bluetoothAdvertise.request();
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _ensurePermissions();

  // Safely get available cameras
  try {
    _cameras = await availableCameras();
  } catch (_) {
    _cameras = const <CameraDescription>[];
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Device Features',
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  void _login() {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;
    if (u == 'Admin' && p == '1234') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(controller: _userCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.person), labelText: 'Username')),
                const SizedBox(height: 12),
                TextField(controller: _passCtrl, obscureText: _obscure, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock), labelText: 'Password', suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)))),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _login, child: const Text('Sign In'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _FeatureTile(icon: Icons.camera_alt, label: 'Camera', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CameraApp(cameras: _cameras)))),
          _FeatureTile(icon: Icons.mic, label: 'Audio', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AudioScreen()))),
          _FeatureTile(icon: Icons.battery_full, label: 'Power', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PowerScreen()))),
          _FeatureTile(icon: Icons.bluetooth, label: 'Bluetooth', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BluetoothScreen()))),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeatureTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraApp({super.key, required this.cameras});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController? _controller;
  XFile? _lastPicture;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    if (widget.cameras.isEmpty) {
      // No cameras available
      setState(() {});
      return;
    }

    final camera = widget.cameras.first;
    final controller = CameraController(camera, ResolutionPreset.max);
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
      });
    } on CameraException catch (e) {
      debugPrint('Camera init error: ${e.code} ${e.description}');
      setState(() {
        _controller = null;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final picture = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _lastPicture = picture;
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewPage(imagePath: picture.path),
        ),
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a picture'),
        actions: [
          if (_lastPicture != null)
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ImageViewPage(imagePath: _lastPicture!.path),
                  ),
                );
              },
            ),
        ],
      ),
      body: controller == null
          ? const Center(child: Text('No camera available'))
          : (!controller.value.isInitialized)
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Positioned.fill(child: CameraPreview(controller)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FloatingActionButton(
                          onPressed: _takePicture,
                          child: const Icon(Icons.camera_alt),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class ImageViewPage extends StatelessWidget {
  final String imagePath;
  const ImageViewPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captured Image')),
      body: Center(
        child: kIsWeb
            ? const Text('Preview not supported on web')
            : Image.file(File(imagePath)),
      ),
    );
  }
}

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});
  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final rec.AudioRecorder _recorder = rec.AudioRecorder();
  bool _isRecording = false;
  String? _lastPath;

  Future<String> _newAudioPath() async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/rec_$ts.m4a';
  }

  Future<void> _toggle() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _lastPath = path;
      });
    } else {
      if (await _recorder.hasPermission()) {
        final p = await _newAudioPath();
        await _recorder.start(const rec.RecordConfig(), path: p);
        setState(() {
          _isRecording = true;
          _lastPath = null;
        });
      } else {
        final st = await Permission.microphone.request();
        if (st.isGranted) {
          final p = await _newAudioPath();
          await _recorder.start(const rec.RecordConfig(), path: p);
          setState(() {
            _isRecording = true;
            _lastPath = null;
          });
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Recorder')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isRecording ? Icons.mic : Icons.mic_none, size: 64, color: _isRecording ? Colors.red : null),
            const SizedBox(height: 16),
            FilledButton(onPressed: _toggle, child: Text(_isRecording ? 'Stop' : 'Record')),
            const SizedBox(height: 12),
            if (_lastPath != null) Text('Saved: ${_lastPath!}', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

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

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});
  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  bool _scanning = false;
  List<ScanResult> _results = const [];

  Future<void> _start() async {
    if (_scanning) return;
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final st = await Permission.bluetoothScan.status;
        if (!st.isGranted) {
          final r = await Permission.bluetoothScan.request();
          if (!r.isGranted) return;
        }
      }
    }
    setState(() {
      _scanning = true;
      _results = const [];
    });
    FlutterBluePlus.scanResults.listen((r) {
      if (!mounted) return;
      setState(() {
        _results = r;
      });
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    if (!mounted) return;
    setState(() {
      _scanning = false;
    });
  }

  Future<void> _stop() async {
    await FlutterBluePlus.stopScan();
    if (!mounted) return;
    setState(() {
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FilledButton(onPressed: _scanning ? null : _start, child: const Text('Scan')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _scanning ? _stop : null, child: const Text('Stop')),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (c, i) {
              final r = _results[i];
              final adv = r.advertisementData.advName;
              final name = (adv.isNotEmpty) ? adv : r.device.remoteId.str;
              return ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(name),
                subtitle: Text(r.rssi.toString()),
              );
            },
          ),
        ),
      ]),
    );
  }
}