import 'dart:ffi';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1020), Color(0xFF11264F), Color(0xFF0AA9BD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 0.3),
                ),
                child: const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white24,
                  backgroundImage: AssetImage('assets/images/RPSV-ICON.png'),
                ),
              ),
            ),
            
            SizedBox(height: 30,),
            Text("Redjan Phil S. Visitacion",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Times New Roman',
              ),
            ),
            
            const SizedBox(height: 75),
            Expanded(
              child: GridView.count(
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
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xCC0AA9BD), Color(0xCC1B4DB1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.15),
              ),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ]),
        ),
      ),
    );
  }
}
