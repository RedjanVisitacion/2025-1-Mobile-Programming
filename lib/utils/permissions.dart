import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

Future<void> ensurePermissions() async {
  if (kIsWeb) return;

  var camStatus = await Permission.camera.status;
  if (!camStatus.isGranted) {
    await Permission.camera.request();
  }

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
