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
    let sampleSize = 2048;
    let sampleRate = 22050;
    let yin;
  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "pitchdetector", binaryMessenger: registrar.messenger())
    let instance = SwiftPitchdetectorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
        case "initializeValues":
            let dic = call.arguments as! [String : Any]
            self.sampleRate = dic["sampleRate"] as! Int;
            self.sampleSize = dic["sampleSize"] as! Int;
            self.yin = YIN( self.sampleRate , self.sampleSize);
            break;
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
        if #available(iOS 9.0, *) {
            let inputNode = engine.inputNode;
            let inputFormat = inputNode.outputFormat(forBus: 0);
            let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(self.sampleRate), channels: 1, interleaved: true);
            let formatConverter = AVAudioConverter(from:inputFormat , to : recordingFormat!)
            inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(self.sampleSize), format: inputFormat){
                       (buffer , time) in
                       
                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat!, frameCapacity: AVAudioFrameCount(self.sampleSize))
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
                        let pitch = yin.getPitch(channelData)
                        channel.invokeMethod("getPitch", arguments: pitch)
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


public class YIN {
  /**
	 * The default YIN threshold value. Should be around 0.10~0.15. See YIN
	 * paper for more information.
	 */
  let DEFAULT_THRESHOLD = 0.20;

  /**
	 * The default size of an audio buffer (in samples).
	 */
  let DEFAULT_BUFFER_SIZE = 2048;

  /**
	 * The actual YIN threshold.
	 */
  let threshold;

  /**
	 * The audio sample rate. Most audio has a sample rate of 44.1kHz.
	 */
    let sampleRate;

  /**
	 * The buffer that stores the calculated values. It is exactly half the size
	 * of the input buffer.
	 */
    let yinBuffer;


  init(audioSampleRate: Int, bufferSize : Int) {
    self.sampleRate = audioSampleRate;
    self.threshold = self.DEFAULT_THRESHOLD;
    var halfBufferSize = (bufferSize / 2).round();
    var doubleBufferSize = 2 * bufferSize;
    yinBuffer = [Double](count: halfBufferSize, repeatedValue: nil)
    //Initializations for FFT difference step
    audioBufferFFT = [Double](count: doubleBufferSize, repeatedValue: nil);
    // kernel = new List(doubleBufferSize);
    // yinStyleACF = new List(doubleBufferSize);
  }
  func getPitch(audioBuffer : [Double]) {
    let tauEstimate as !Double;
    try {
      let pitchInHertz as !Double;
      // step 2
      difference(audioBuffer);
      // step 3
      cumulativeMeanNormalizedDifference();
      // step 4
      tauEstimate = absoluteThreshold();
      // step 5
      if (tauEstimate != -1) {
        let betterTau = parabolicInterpolation(tauEstimate);
        // step 6
        // TODO Implement optimization for the AUBIO_YIN algorithm.
        // 0.77% => 0.5% error rate,
        // using the data of the YIN paper
        // bestLocalEstimate()

        // conversion to Hz
        pitchInHertz = sampleRate / betterTau;
      } else {
        // no pitch found
        pitchInHertz = -1;
      }

      return pitchInHertz;
    } catch (ex, stacktrace) {}
  }

  func difference(audioBuffer : [Double]) {
    let index, tau;
    let delta;
    for (tau = 0; tau < yinBuffer.length; tau++) {
      yinBuffer[tau] = 0;
    }
    for (tau = 1; tau < yinBuffer.length; tau++) {
      for (index = 0; index < yinBuffer.length; index++) {
        delta = audioBuffer[index] - audioBuffer[index + tau];
        yinBuffer[tau] += delta * delta;
      }
    }
  }

  /**
	 * The cumulative mean normalized difference function as described in step 3
	 * of the YIN paper. <br>
	 * <code>
	 * yinBuffer[0] == yinBuffer[1] = 1
	 * </code>
	 */
  void cumulativeMeanNormalizedDifference() {
    int tau;
    yinBuffer[0] = 1;
    double runningSum = 0;
    for (tau = 1; tau < yinBuffer.length; tau++) {
      runningSum += yinBuffer[tau];
      yinBuffer[tau] *= tau / runningSum;
    }
  }

  /**
	 * Implements step 4 of the AUBIO_YIN paper.
	 */
  int absoluteThreshold() {
    // Uses another loop construct
    // than the AUBIO implementation
    int tau;
    // first two positions in yinBuffer are always 1
    // So start at the third (index 2)
    var prob;
    for (tau = 2; tau < yinBuffer.length; tau++) {
      if (yinBuffer[tau] < threshold) {
        while (
            tau + 1 < yinBuffer.length && yinBuffer[tau + 1] < yinBuffer[tau]) {
          tau++;
        }
        // found tau, exit loop and return
        // store the probability
        // From the YIN paper: The threshold determines the list of
        // candidates admitted to the set, and can be interpreted as the
        // proportion of aperiodic power tolerated
        // within a periodic signal.
        //
        // Since we want the periodicity and and not aperiodicity:
        // periodicity = 1 - aperiodicity
        // result.setProbability(1 - yinBuffer[tau]);
        break;
      }
    }
    // if no pitch found, tau => -1
    if (tau == yinBuffer.length || yinBuffer[tau] >= threshold) {
      tau = -1;
      // result.setProbability(0);
      // result.setPitched(false);
    } else {
      // result.setPitched(true);
    }
    return tau;
  }

  /**
	 * Implements step 5 of the AUBIO_YIN paper. It refines the estimated tau
	 * value using parabolic interpolation. This is needed to detect higher
	 * frequencies more precisely. See http://fizyka.umk.pl/nrbook/c10-2.pdf and
	 * for more background
	 * http://fedc.wiwi.hu-berlin.de/xplore/tutorials/xegbohtmlnode62.html
	 * 
	 * @param tauEstimate
	 *            The estimated tau value.
	 * @return A better, more precise tau value.
	 */
  parabolicInterpolation(final int tauEstimate) {
    var betterTau;
    int x0;
    int x2;

    if (tauEstimate < 1) {
      x0 = tauEstimate;
    } else {
      x0 = tauEstimate - 1;
    }
    if (tauEstimate + 1 < yinBuffer.length) {
      x2 = tauEstimate + 1;
    } else {
      x2 = tauEstimate;
    }
    if (x0 == tauEstimate) {
      if (yinBuffer[tauEstimate] <= yinBuffer[x2]) {
        betterTau = tauEstimate;
      } else {
        betterTau = x2;
      }
    } else if (x2 == tauEstimate) {
      if (yinBuffer[tauEstimate] <= yinBuffer[x0]) {
        betterTau = tauEstimate;
      } else {
        betterTau = x0;
      }
    } else {
      double s0, s1, s2;
      s0 = yinBuffer[x0];
      s1 = yinBuffer[tauEstimate];
      s2 = yinBuffer[x2];
      // fixed AUBIO implementation, thanks to Karl Helgason:
      // (2.0f * s1 - s2 - s0) was incorrectly multiplied with -1
      betterTau = tauEstimate + (s2 - s0) / (2 * (2 * s1 - s2 - s0));
    }
    return betterTau;
  }
}