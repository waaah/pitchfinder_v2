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
  double pitch;
  @override
  void initState() {
    super.initState();
    detector =  new Pitchdetector(sampleRate : 44100 , sampleSize : 4096);
    isRecording = isRecording;
    detector.onRecorderStateChanged.listen((event) {
      setState(() {
        pitch = event["pitch"];
      }); 
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
               isRecording ? Text("Recording...") :  Container() ,
	             isRecording ? Text("Recorded hz from mic is : $pitch") : Text( "Not Recording."),
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
    await detector.startRecording();
    if(detector.isRecording){
	    setState(() {
        isRecording = true;
    	});
    }
  }
  void stopRecording() async {
    detector.stopRecording();
    setState(() {
      isRecording = false;
      pitch = detector.pitch;
    });


  }
}
