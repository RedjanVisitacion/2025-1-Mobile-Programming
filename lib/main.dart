import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'globals.dart' as g;
import 'screens/login/login_screen.dart';
import 'utils/permissions.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ensurePermissions();

  try {
    g.cameras = await availableCameras();
  } catch (_) {
    g.cameras = const <CameraDescription>[];
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
      routes: {
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}