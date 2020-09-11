import Flutter
import UIKit

public class SwiftPitchdetectorPlugin: NSObject, FlutterPlugin {
  var isRecording = false
  var hasPermissions = false
  var mExtension = ""
  var mPath = ""
  var startTime: Date!
  var audioRecorder: AVAudioRecorder!
  let engine = AVAudioEngine()    // instance variable

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pitchdetector", binaryMessenger: registrar.messenger())
    let instance = SwiftPitchdetectorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
        case "startRecording":
            print("start")
            // let dic = call.arguments as! [String : Any]
            // mExtension = dic["extension"] as? String ?? ""
            // mPath = dic["path"] as? String ?? ""
            // startTime = Date()
            // if mPath == "" {
            //     let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            //     mPath = documentsPath + "/" + String(Int(startTime.timeIntervalSince1970)) + ".pcm"
            //     print("path: " + mPath)
            // }
            // let settings = [
            //     AVFormatIDKey: getOutputFormatFromString(mExtension),
            //     AVSampleRateKey: 16000,
            //     AVNumberOfChannelsKey: 1,
            //     AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            // ]
            // do {
            //     try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
            //     try AVAudioSession.sharedInstance().setActive(true)
                
            //     audioRecorder = try AVAudioRecorder(url: URL(string: mPath)!, settings: settings)
            //     audioRecorder.delegate = self
            //     audioRecorder.record()
            // } catch {
            //     print("fail")
            //     result(FlutterError(code: "", message: "Failed to record", details: nil))
            // }
            // isRecording = true
            setupPcm(result);
            result("start");
            break;
        case "stopRecording":
            // print("stop")
            // audioRecorder.stop()
            // audioRecorder = nil
            // let duration = Int(Date().timeIntervalSince(startTime as Date) * 1000)
            // isRecording = false
            // var recordingResult = [String : Any]()
            // recordingResult["duration"] = duration
            // recordingResult["path"] = mPath
            // recordingResult["audioOutputFormat"] = mExtension
            stopRecording();
            result("stop");
            break;
        case "isRecording":
            // print("isRecording")
            // result(isRecording)
            result(hasPermissions)
            break;
        default:
            result(FlutterMethodNotImplemented)
            break;
      }
  }

  func getOutputFormatFromString(_ format : String) -> Int {
      return Int(kAudioFormatLinearPCM)
  }

  //mic engine setup
  func setupPcm( result: @escaping FlutterResult) {        
      let mixer = AVAudioMixerNode()
      engine.attach(mixer)

      let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!

      let input = engine.inputNode!
      let bus = 0
      engine.connect(engine.inputNode, to: mixer, format: engine.inputNode.inputFormat(forBus: 0))
      engine.connect(mixer, to: engine.outputNode, format: format)

      mixer.installTap(onBus: 0, bufferSize: 2048, format: mixer.outputFormat(forBus: 0), block: { [weak self] buffer, _ in
          let samples = buffer.floatChannelData[0]
          var recordingResult = [String : Any]()
          recordingResult["samples"] = samples
          self.channel.invokeMethod("recordingResult" , arguments:  recordingResult)
      })

      try! engine.start()
  }
  func stopRecording(){
      isRecording = true;
      try! engine.stop()
  }
}


