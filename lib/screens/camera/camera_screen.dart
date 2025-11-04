import 'dart:io' show File;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'image_view_page.dart';

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
