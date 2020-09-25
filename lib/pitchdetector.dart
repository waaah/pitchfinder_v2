import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pitchdetector/pitchdetector.dart';
import 'package:pitchdetector/pitchdetectorclass.dart';

class Pitchdetector {
  static const MethodChannel _channel = const MethodChannel('pitchdetector');
  static StreamController<Object> _recorderController =
      StreamController<Map<String, Object>>.broadcast();
  bool _isRecording = false;
  double _pitch = null;
  
  int sampleSize = 2048;
  int sampleRate = 22050;
  List pcmSamples = [];

  Pitchdetector({
    this.sampleSize,
    this.sampleRate
  }){
    _channel.invokeMethod("initializeValues" , {
      "sampleRate": sampleRate,
      "sampleSize": sampleSize
    });
  } 

  Stream<Map<String, Object>> get onRecorderStateChanged =>
      _recorderController.stream;

  bool get isRecording => _isRecording;
  double get pitch => _pitch;

  Future<bool> checkPermission() async {
    return Permission.microphone.request().isGranted;
  }

  startRecording() async {
    if (await checkPermission()) {
      try {
        print("check permission");
        _pitch = null;
        var result = await _channel.invokeMethod('startRecording');
        _isRecording = true;
        createChannelHandler();
      } catch (ex) {
        print(ex);
      }
    } else {

    }
  }
  
  createChannelHandler() {
    _channel.setMethodCallHandler((MethodCall call){
      switch (call.method) {
        case "getPcm":
          if (_isRecording) {
              pcmSamples = call.arguments;
             //getPitchAsync(pcmSamples);
          }
          break;
        default:
          throw new ArgumentError("Unknown method: ${call.method}");
      }
      return null;
    });
  }

  Future getPitchAsync(pcmSamples){
    return new Future.delayed(new Duration(milliseconds : 550) , (){
      getPitchFromSamples(pcmSamples);
     
    });
  }
  getPitchFromSamples(pcmSamples){
    var yin = new YIN(sampleRate, sampleSize);
    double samplePitch = yin.getPitch(pcmSamples);
    if (samplePitch > -1.0) {
      _pitch = samplePitch;
    }
  }

  stopRecording() async {
    try {
      _isRecording = false;
      getPitchFromSamples(pcmSamples);
      destoryChannelHandler();
      _channel.invokeMethod('stopRecording');
    } catch (ex , stacktrace) {
      print(stacktrace.toString());
    }
  }
  destoryChannelHandler(){
    _channel.setMethodCallHandler((call) => null);
  }
}
