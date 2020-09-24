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
    detector =  new Pitchdetector(sampleRate : 22050 , sampleSize : 2048);
    isRecording = isRecording;
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
	       pitch != null && !isRecording ? Text("Recorded hz from mic is : $pitch") : ( isRecording ? Container() : Text( "No Pitch found.")),
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

         await detector.stopRecording();
    setState(() {
        isRecording = false;
        pitch = detector.pitch;
    });


  }
}
