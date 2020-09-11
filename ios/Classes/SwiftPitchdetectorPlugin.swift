import Flutter
import UIKit
import AVFoundation

public class SwiftPitchdetectorPlugin: NSObject, FlutterPlugin {
    var amdf = AMDF(sampleRate : Int(22050.0) , bufferSize : 2048);

  var isRecording = false
  var hasPermissions = false
  var startTime: Date!
  var audioRecorder: AVAudioRecorder!
  let engine = AVAudioEngine()
  public var channel:FlutterMethodChannel!;// instance variable
  private var outputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 22050, channels: 1, interleaved: true)
  public static func register(with registrar: FlutterPluginRegistrar) {
    var channel = FlutterMethodChannel(name: "pitchdetector", binaryMessenger: registrar.messenger())
    let instance = SwiftPitchdetectorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
        case "startRecording":
            print("start")
            //let dic = call.arguments as! [String : Any]
            //setupPcm();
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

  func getOutputFormatFromString(_ format : String) -> Int {
      return Int(kAudioFormatLinearPCM)
  }

  //mic engine setup
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        let input = engine.inputNode
        let bus = 0
        let inputFormat = input.outputFormat(forBus: 0)
    if #available(iOS 9.0, *) {
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat!)!
        input.installTap(onBus: bus, bufferSize: 2048, format: inputFormat) { (buffer, time) -> Void in
            var newBufferAvailable = true

            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }

            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: self.outputFormat!, frameCapacity: AVAudioFrameCount(self.outputFormat!.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate))!

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            assert(status != .error)

            if (self.outputFormat?.commonFormat == AVAudioCommonFormat.pcmFormatInt16) {
                let values = UnsafeBufferPointer(start: convertedBuffer.int16ChannelData![0], count: Int(convertedBuffer.frameLength))
                let arr = Array(values)
                //self.channel.invokeMethod("getPcm", arguments: arr)
                events(arr)
                //var pitch = self.amdf.getPitch(audioBuffer: arr);
                //NSLog("the pitch is:"+ String(pitch))
            }
            else{
                let values = UnsafeBufferPointer(start: convertedBuffer.int32ChannelData![0], count: Int(convertedBuffer.frameLength))
                let arr = Array(values)
                for el in arr{
                    NSLog(String(el))
                }
                //events(arr)
            }
        }

        try! engine.start()
    } else {
        NSLog("cannot use earlier version")
        // Fallback on earlier versions
    }
        
    return nil;
  }
  func stopRecording(){
//      isRecording = true;
//      try! engine.stop()
  }
}
class AMDF{
    var DEFAULT_MIN_FREQUENCY = 82.0;
    var DEFAULT_MAX_FREQUENCY = 1000.0;
    var DEFAULT_RATIO = 5.0;
    var DEFAULT_SENSITIVITY = 0.1;

    var sampleRate = 0;
    var amd = Array<Double>();

    var maxPeriod = 0;
    var minPeriod = 0;
    var ratio = 0.0;
    var sensitivity = 0.0;


    init(sampleRate: Int , bufferSize: Int){		        implement(sampleRate : sampleRate ,  bufferSize:bufferSize , minFrequency : DEFAULT_MIN_FREQUENCY ,maxFrequency :  DEFAULT_MAX_FREQUENCY);
    }

    func implement(sampleRate:Int , bufferSize: Int , minFrequency:Double , maxFrequency:Double){
        self.sampleRate = sampleRate;
        amd = [];
        self.ratio = self.DEFAULT_RATIO;
        self.sensitivity = DEFAULT_SENSITIVITY;
        self.maxPeriod = Int(((Double(self.sampleRate) / minFrequency) + 0.5).rounded());
        self.minPeriod = Int(((Double(self.sampleRate) / maxFrequency) + 0.5).rounded());
    }

    func getPitch(audioBuffer : Array<Int16>) -> Double{
        var t = 0;
        var f0 = -1.0;
        var minval:Double = .infinity;
        var maxval:Double = -.infinity;

        var frames1 = Array<Double>();
        var frames2 = Array<Double>();
        var calcSub = Array<Double>();
	
        var maxShift = audioBuffer.count;
        for i in 0 ... maxShift - 1 {
        //for (let i = 0; i < maxShift; i++) {
            frames1 = [Double](repeating: 0.0, count : maxShift - i + 1 );
            frames2 = [Double]( repeating: 0.0, count : maxShift - i + 1 )

            t = 0;
            for aux1 in 0 ... maxShift - i {
            //for (let aux1 = 0; aux1 < maxShift - i; aux1++) {
                t = t + 1;
                frames1[t] = Double(audioBuffer[aux1]);
            }

            t = 0;
            for aux2 in i ... maxShift-1{
            //for (let aux2 = i; aux2 < maxShift; aux2++) {
                t = t + 1;
                frames2[t] = Double(audioBuffer[aux2]);
            }

            let frameLength = frames1.count;
            calcSub =  [Double]( repeating : 0.0 , count : maxShift - i + 1);
            for u in 0 ... frameLength-1{
            //for (int u = 0; u < frameLength; u++) {
                calcSub[u] = frames1[u] - frames2[u];
            }

            var summation = 0.0;
            for l in 0 ... frameLength - 1{
            //for (let l = 0; l < frameLength; l++) {
                summation += abs(calcSub[l]);
            }
            amd[i] = summation;
        }
        for j in self.minPeriod ... self.maxPeriod-1 {
        //for (let j = minPeriod; j < maxPeriod; j++) {
            if (amd[j] < minval) {
                minval = amd[j];
            }
            if (amd[j] > maxval) {
                maxval = amd[j];
            }
        }
        let cutoff = ((self.sensitivity * (maxval - minval) ) + minval).rounded();
        var j = self.minPeriod;

        while (j <= maxPeriod && ( (amd[j]) > cutoff)) {
            j = j + 1;
        }
        var search_length = minPeriod / 2;
        minval = amd[j]
        var minpos = j;
        var i = j;
        while ((i < j + search_length) && (i <= maxPeriod)) {
            i = i + 1;
            if (  amd[i] < minval) {
                minval = amd[i];
                minpos = i;
            }
        }
        let compare = ( amd[minpos]  * ratio).rounded();
        if ( compare  < maxval) {
            f0 = Double(sampleRate / minpos);
        }
        return f0;
    }

}
