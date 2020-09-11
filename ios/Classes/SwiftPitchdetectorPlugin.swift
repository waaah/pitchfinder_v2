import Flutter
import UIKit
import AVFoundation

var channel:FlutterMethodChannel!;// instance variable
public class SwiftPitchdetectorPlugin: NSObject, FlutterPlugin {
  var isRecording = false
  var hasPermissions = false
  var startTime: Date!
  var audioRecorder: AVAudioRecorder!
  var engine:AVAudioEngine!

  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "pitchdetector", binaryMessenger: registrar.messenger())
    let instance = SwiftPitchdetectorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
        case "startRecording":
            self.engine = AVAudioEngine();
            //let dic = call.arguments as! [String : Any]
            setupPcm();
            //result("start");
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
    result(nil)
  }
    func setupPcm(){
        print("pcm start recording");
        if #available(iOS 9.0, *) {
            let inputNode = engine.inputNode;
            let inputFormat = inputNode.outputFormat(forBus: 0);
            let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 22050, channels: 1, interleaved: true);
            let formatConverter = AVAudioConverter(from:inputFormat , to : recordingFormat!)
            inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(2048), format: inputFormat){
                       (buffer , time) in
                       
                       let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat!, frameCapacity: AVAudioFrameCount(2048))
                       var error : NSError? = nil;
                       
                       let inputBlock: AVAudioConverterInputBlock = {
                           inNumPackets , outStatus in
                           outStatus.pointee = AVAudioConverterInputStatus.haveData
                           return buffer;
                       }
                       formatConverter?.convert(to: pcmBuffer!, error: &error,withInputFrom: inputBlock)
                if error != nil{
                    print(error!.localizedDescription)
                }
                else if let channelData = pcmBuffer!.int16ChannelData{
                    let channelDataPointer = channelData.pointee;
                    let channelData = stride(
                        from : 0,
                        to : Int(pcmBuffer!.frameLength),
                        by: buffer.stride ).map{ Double(channelDataPointer[$0]) }
                    channel.invokeMethod("getPcm", arguments: channelData)
                }
            }
            engine.prepare();
            do{
                try! engine.start();
            }
            catch{
                
            }
            // Fallback on earlier versions
        }
        else{
            print("not available")
        }
       
    }
  func stopRecording(){
//      isRecording =
    print("stopping pcm recording");
    try! engine.stop()
  }
}
