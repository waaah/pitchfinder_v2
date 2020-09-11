import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pitchdetector/pitchdetector.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Pitchdetector detector;
  bool isRecording = false;
  String pitch;
  @override
  void initState() {
    super.initState();
    detector =  new Pitchdetector();
    isRecording = isRecording;
    detector.onRecorderStateChanged.listen((data) {
      if(mounted){
        setState(() {
          pitch = data["pitch"].toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: 
          Column(
            children: <Widget>[
               isRecording ? Text("Pitch is $pitch") :  Text("Press button to start.") ,
               FlatButton(
                onPressed: isRecording ?  stopRecording : startRecording, 
                child:   isRecording ?   Text("Press Me to stop") : Text("Press Me to run") 
              )
            ],
          )
          
        ),
      ),
    );
  }

  void startRecording()  async{
    print("startRecording");
    setState(() {
        isRecording = true;
    });
    
    await detector.startRecording();
  }
  void stopRecording() async {
     setState(() {
        isRecording = false;
        pitch = null;
    });
    await detector.stopRecording();
  }
}
