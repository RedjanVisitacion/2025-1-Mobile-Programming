import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as rec;

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
