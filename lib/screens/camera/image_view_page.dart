import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

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
