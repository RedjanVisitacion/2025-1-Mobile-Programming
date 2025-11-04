import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../globals.dart' as g;
import '../audio/audio_screen.dart';
import '../bluetooth/bluetooth_screen.dart';
import '../camera/camera_screen.dart';
import '../power/power_screen.dart';
import '../login/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Features'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Logout')),
                      ],
                    ),
                  ) ??
                  false;
              if (ok) {
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _FeatureTile(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CameraApp(cameras: g.cameras)),
            ),
          ),
          _FeatureTile(
            icon: Icons.mic,
            label: 'Audio',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AudioScreen()),
            ),
          ),
          _FeatureTile(
            icon: Icons.battery_full,
            label: 'Power',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PowerScreen()),
            ),
          ),
          _FeatureTile(
            icon: Icons.bluetooth,
            label: 'Bluetooth',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BluetoothScreen()),
            ),
          ),
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
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
