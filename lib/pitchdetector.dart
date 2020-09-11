import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pitchdetector/pitchdetector.dart';
import 'package:pitchdetector/pitchdetectorclass.dart';

class Pitchdetector {
  static const MethodChannel _channel = const MethodChannel('pitchdetector');
  static StreamController<Object> _recorderController =
      StreamController<Map<String, Object>>.broadcast();
  bool _isRecording = false;

  Stream<Map<String, Object>> get onRecorderStateChanged =>
      _recorderController.stream;
  bool get isRecording => _isRecording;


  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<String> recordingCallback() async {}
  Future<bool> checkPermission() async {
    return await Permission.microphone.request().isGranted;
  }

  startRecording() async {
    print("setrecording");
    if (await checkPermission()) {
      try {
        var result = await _channel.invokeMethod('startRecording');
        _isRecording = true;
        _channel.setMethodCallHandler((MethodCall call) {
          switch (call.method) {
            case "getPcm":
                if(_isRecording && _recorderController != null){
                   var yin = new YIN(22050, 2048);
                   double pitch =  yin.getPitch(call.arguments);
                  _recorderController.add({
                    "pitch": pitch,
                  });
                }
              break;
            default:
              throw new ArgumentError("Unknown method: ${call.method}");
          }
          return null;
        });
        return result;
      } catch (ex) {
        print(ex);
      }
    } else {}
  }

  stopRecording() async {
    _isRecording = false;
    var result = await _channel.invokeMethod('stopRecording');
  }
  setChannelHandler(){

  }
}
