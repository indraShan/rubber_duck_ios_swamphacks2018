//
//  ViewController.swift
//  RubberDuck
//
//  Created by Indrajit on 20/01/18.
//  Copyright © 2018 Indrajit. All rights reserved.
//

import UIKit
import LoginWithAmazon
import AVFoundation

class ViewController: UIViewController {
    var recorder: AVAudioRecorder!
    var player: AVAudioPlayer!
    var soundFileURL: URL!
    var accessToken: NSString!
    @IBOutlet weak var rubberDuck: UIImageView!

    func loginIfRequired() {
        let authRequest = AMZNAuthorizeRequest();
        let scopeData:[String: Any] = [
            "productID" : Config.LoginWithAmazon.ProductId,
            "productInstanceAttributes" : ["deviceSerialNumber": Config.LoginWithAmazon.DeviceSerialNumber]
        ]
        let scope = AMZNScopeFactory.scope(withName: "alexa:all", data: scopeData)
        authRequest.scopes = [scope]
        authRequest.grantType = AMZNAuthorizationGrantType.token
        authRequest.interactiveStrategy = .auto;

        AMZNAuthorizationManager.shared().authorize(authRequest) { (result, userDidCancel, error) in
            if let failure = error {
                print("Failed to login with error = ", failure.localizedDescription)
                return
            }

            if userDidCancel {
                return;
            }
            // Auth success.

            print("Access token", result?.token)
            self.accessToken = result?.token  as! NSString
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loginIfRequired();
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTapDuck))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        rubberDuck.addGestureRecognizer(tap)

        setSessionPlayback()
        askForNotifications()
        checkHeadphones()
    }

    @objc func didTapDuck() {
        if recorder == nil {
            print("recording. recorder nil")
            //            recordButton.setTitle("Pause", for: .normal)
            //            playButton.isEnabled = false
            //            stopButton.isEnabled = true
            recordWithPermission(true)
            return
        }

        if recorder != nil && recorder.isRecording {
            print("pausing")
            recorder.pause()
            recorder?.stop()
            recordWithPermission(false);

            // Play recorded file.
            play()

            upload()
        }
    }

    @objc func updateAudioMeter(_ timer: Timer) {

        if let recorder = self.recorder {
            if recorder.isRecording {
                let min = Int(recorder.currentTime / 60)
                let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
                let s = String(format: "%02d:%02d", min, sec)
//                statusLabel.text = s
                recorder.updateMeters()
                // if you want to draw some graphics...
                //var apc0 = recorder.averagePowerForChannel(0)
                //var peak0 = recorder.peakPowerForChannel(0)
            }
        }
    }


    @IBAction func record(_ sender: UIButton) {

        if player != nil && player.isPlaying {
            print("stopping")
            player.stop()
        }

        if recorder == nil {
            print("recording. recorder nil")
//            recordButton.setTitle("Pause", for: .normal)
//            playButton.isEnabled = false
//            stopButton.isEnabled = true
            recordWithPermission(true)
            return
        }

        if recorder != nil && recorder.isRecording {
            print("pausing")
            recorder.pause()
//            recordButton.setTitle("Continue", for: .normal)

        } else {
            print("recording")
//            recordButton.setTitle("Pause", for: .normal)
//            playButton.isEnabled = false
//            stopButton.isEnabled = true
            //            recorder.record()
            recordWithPermission(false)
        }
    }

    @IBAction func stop(_ sender: UIButton) {

//        print("\(#function)")
//
//        recorder?.stop()
//        player?.stop()
//
//        meterTimer.invalidate()
//
//        recordButton.setTitle("Record", for: .normal)
//        let session = AVAudioSession.sharedInstance()
//        do {
//            try session.setActive(false)
//            playButton.isEnabled = true
//            stopButton.isEnabled = false
//            recordButton.isEnabled = true
//        } catch {
//            print("could not make session inactive")
//            print(error.localizedDescription)
//        }

        //recorder = nil
    }

//    @IBAction func play(_ sender: UIButton) {
//        print("\(#function)")
//
//        play()
//    }

    private func createMeatadata() -> String? {
        var rootElement = [String:Any]()

        let deviceContextPayload = ["streamId":"", "offsetInMilliseconds":"0", "playerActivity":"IDLE"]
        let deviceContext:[String:Any] = ["name":"playbackState", "namespace":"AudioPlayer", "payload":deviceContextPayload]
        rootElement["messageHeader"] = ["deviceContext":[deviceContext]]

        let deviceProfile = ["profile":"doppler-scone", "locale":"en-us", "format":"audio/L16; rate=16000; channels=1"]
        rootElement["messageBody"] = deviceProfile as AnyObject

        let data = try! JSONSerialization.data(withJSONObject: rootElement, options: JSONSerialization.WritingOptions(rawValue: 0))

        return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
    }

    private func upload() {
        let uploader = AVSUploader()

        uploader.authToken = self.accessToken as! String

        uploader.jsonData = self.createMeatadata()

        var url: URL?
        if self.recorder != nil {
            url = self.recorder.url
        } else {
            url = self.soundFileURL!
        }
        uploader.audioData = NSData(contentsOf: url!)

        uploader.errorHandler = { (error:NSError) in
            if Config.Debug.Errors {
                print("Upload error: \(error)")
            }

//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self.statusLabel.text = "Upload error: \(error.localizedDescription)"
//                self.recordButton.enabled = true
//            })
        }

//        uploader.progressHandler = { (progress:Double) in
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                if progress < 100.0 {
//                    self.statusLabel.text = String(format: "Uploading recording")
//                } else {
//                    self.statusLabel.text = "Waiting for response"
//                }
//            })
//        }

        uploader.successHandler = { (data:NSData, parts:[PartData]) -> Void in

            for part in parts {
                if part.headers["Content-Type"] == "application/json" {
                    if Config.Debug.General {
//                        print(NSString(data: part.data, encoding: NSUTF8StringEncoding))
                    }
                } else if part.headers["Content-Type"] == "audio/mpeg" {
//                    do {
//                        self.player = try AVAudioPlayer(data: part.data)
//                        self.player?.delegate = self
//                        self.player?.play()
//
//                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                            self.statusLabel.text = "Playing response"
//                        })
//                    } catch let error {
//                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                            self.statusLabel.text = "Playing error: \(error)"
//                            self.recordButton.enabled = true
//                        })
//                    }
                }
            }

        }

        try! uploader.start()
    }

    func play() {
        print("\(#function)")


        var url: URL?
        if self.recorder != nil {
            url = self.recorder.url
        } else {
            url = self.soundFileURL!
        }
        print("playing \(String(describing: url))")

        do {
            self.player = try AVAudioPlayer(contentsOf: url!)
//            stopButton.isEnabled = true
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
        } catch {
            self.player = nil
            print(error.localizedDescription)
        }
    }

    func setupRecorder() {
        print("\(#function)")

        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.string(from: Date())).m4a"
        print(currentFileName)

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.soundFileURL = documentsDirectory.appendingPathComponent(currentFileName)
        print("writing to soundfile url: '\(soundFileURL!)'")

        if FileManager.default.fileExists(atPath: soundFileURL.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFileURL.absoluteString) exists")
        }

        let recordSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey: 32000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0
        ]


        do {
            recorder = try AVAudioRecorder(url: soundFileURL, settings: recordSettings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        } catch {
            recorder = nil
            print(error.localizedDescription)
        }

    }

    func recordWithPermission(_ setup: Bool) {
        print("\(#function)")

        AVAudioSession.sharedInstance().requestRecordPermission {
            [unowned self] granted in
            if granted {

                DispatchQueue.main.async {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()

//                    self.meterTimer = Timer.scheduledTimer(timeInterval: 0.1,
//                                                           target: self,
//                                                           selector: #selector(self.updateAudioMeter(_:)),
//                                                           userInfo: nil,
//                                                           repeats: true)
                }
            } else {
                print("Permission to record not granted")
            }
        }

        if AVAudioSession.sharedInstance().recordPermission() == .denied {
            print("permission denied")
        }
    }

    func setSessionPlayback() {
        print("\(#function)")

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: .defaultToSpeaker)

        } catch {
            print("could not set session category")
            print(error.localizedDescription)
        }

        do {
            try session.setActive(true)
        } catch {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }

    func setSessionPlayAndRecord() {
        print("\(#function)")

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
        } catch {
            print("could not set session category")
            print(error.localizedDescription)
        }

        do {
            try session.setActive(true)
        } catch {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }

    func askForNotifications() {
        print("\(#function)")
//
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(RecorderViewController.background(_:)),
//                                               name: NSNotification.Name.UIApplicationWillResignActive,
//                                               object: nil)
//
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(RecorderViewController.foreground(_:)),
//                                               name: NSNotification.Name.UIApplicationWillEnterForeground,
//                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.routeChange(_:)),
                                               name: NSNotification.Name.AVAudioSessionRouteChange,
                                               object: nil)
    }


    @objc func routeChange(_ notification: Notification) {
        print("\(#function)")

        if let userInfo = (notification as NSNotification).userInfo {
            print("routeChange \(userInfo)")

            //print("userInfo \(userInfo)")
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt {
                //print("reason \(reason)")
                switch AVAudioSessionRouteChangeReason(rawValue: reason)! {
                case AVAudioSessionRouteChangeReason.newDeviceAvailable:
                    print("NewDeviceAvailable")
                    print("did you plug in headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.oldDeviceUnavailable:
                    print("OldDeviceUnavailable")
                    print("did you unplug headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.categoryChange:
                    print("CategoryChange")
                case AVAudioSessionRouteChangeReason.override:
                    print("Override")
                case AVAudioSessionRouteChangeReason.wakeFromSleep:
                    print("WakeFromSleep")
                case AVAudioSessionRouteChangeReason.unknown:
                    print("Unknown")
                case AVAudioSessionRouteChangeReason.noSuitableRouteForCategory:
                    print("NoSuitableRouteForCategory")
                case AVAudioSessionRouteChangeReason.routeConfigurationChange:
                    print("RouteConfigurationChange")

                }
            }
        }

        // this cast fails. that's why I do that goofy thing above.
        //        if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSessionRouteChangeReason {
        //        }

        /*
         AVAudioSessionRouteChangeReasonUnknown = 0,
         AVAudioSessionRouteChangeReasonNewDeviceAvailable = 1,
         AVAudioSessionRouteChangeReasonOldDeviceUnavailable = 2,
         AVAudioSessionRouteChangeReasonCategoryChange = 3,
         AVAudioSessionRouteChangeReasonOverride = 4,
         AVAudioSessionRouteChangeReasonWakeFromSleep = 6,
         AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory = 7,
         AVAudioSessionRouteChangeReasonRouteConfigurationChange NS_ENUM_AVAILABLE_IOS(7_0) = 8

         routeChange Optional([AVAudioSessionRouteChangeReasonKey: 1, AVAudioSessionRouteChangePreviousRouteKey: <AVAudioSessionRouteDescription: 0x17557350,
         inputs = (
         "<AVAudioSessionPortDescription: 0x17557760, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
         );
         outputs = (
         "<AVAudioSessionPortDescription: 0x17557f20, type = Speaker; name = Speaker; UID = Built-In Speaker; selectedDataSource = (null)>"
         )>])
         routeChange Optional([AVAudioSessionRouteChangeReasonKey: 2, AVAudioSessionRouteChangePreviousRouteKey: <AVAudioSessionRouteDescription: 0x175562f0,
         inputs = (
         "<AVAudioSessionPortDescription: 0x1750c560, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
         );
         outputs = (
         "<AVAudioSessionPortDescription: 0x17557de0, type = Headphones; name = Headphones; UID = Wired Headphones; selectedDataSource = (null)>"
         )>])
         */
    }

    func checkHeadphones() {
        print("\(#function)")

        // check NewDeviceAvailable and OldDeviceUnavailable for them being plugged in/unplugged
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        if !currentRoute.outputs.isEmpty {
            for description in currentRoute.outputs {
                if description.portType == AVAudioSessionPortHeadphones {
                    print("headphones are plugged in")
                    break
                } else {
                    print("headphones are unplugged")
                }
            }
        } else {
            print("checking headphones requires a connection to a device")
        }
    }

    @IBAction
    func trim() {
        print("\(#function)")

        if self.soundFileURL == nil {
            print("no sound file")
            return
        }

        print("trimming \(soundFileURL!.absoluteString)")
        print("trimming path \(soundFileURL!.lastPathComponent)")
        let asset = AVAsset(url: self.soundFileURL!)
        exportAsset(asset, fileName: "trimmed.m4a")
    }

    func exportAsset(_ asset: AVAsset, fileName: String) {
        print("\(#function)")

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let trimmedSoundFileURL = documentsDirectory.appendingPathComponent(fileName)
        print("saving to \(trimmedSoundFileURL.absoluteString)")



        if FileManager.default.fileExists(atPath: trimmedSoundFileURL.absoluteString) {
            print("sound exists, removing \(trimmedSoundFileURL.absoluteString)")
            do {
                if try trimmedSoundFileURL.checkResourceIsReachable() {
                    print("is reachable")
                }

                try FileManager.default.removeItem(atPath: trimmedSoundFileURL.absoluteString)
            } catch {
                print("could not remove \(trimmedSoundFileURL)")
                print(error.localizedDescription)
            }

        }

        print("creating export session for \(asset)")

        if let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) {
            exporter.outputFileType = AVFileType.m4a
            exporter.outputURL = trimmedSoundFileURL

            let duration = CMTimeGetSeconds(asset.duration)
            if duration < 5.0 {
                print("sound is not long enough")
                return
            }
            // e.g. the first 5 seconds
            let startTime = CMTimeMake(0, 1)
            let stopTime = CMTimeMake(5, 1)
            exporter.timeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)

            //            // set up the audio mix
            //            let tracks = asset.tracksWithMediaType(AVMediaTypeAudio)
            //            if tracks.count == 0 {
            //                return
            //            }
            //            let track = tracks[0]
            //            let exportAudioMix = AVMutableAudioMix()
            //            let exportAudioMixInputParameters =
            //            AVMutableAudioMixInputParameters(track: track)
            //            exportAudioMixInputParameters.setVolume(1.0, atTime: CMTimeMake(0, 1))
            //            exportAudioMix.inputParameters = [exportAudioMixInputParameters]
            //            // exporter.audioMix = exportAudioMix

            // do it
            exporter.exportAsynchronously(completionHandler: {
                print("export complete \(exporter.status)")

                switch exporter.status {
                case  AVAssetExportSessionStatus.failed:

                    if let e = exporter.error {
                        print("export failed \(e)")
                    }

                case AVAssetExportSessionStatus.cancelled:
                    print("export cancelled \(String(describing: exporter.error))")
                default:
                    print("export complete")
                }
            })
        } else {
            print("cannot create AVAssetExportSession for asset \(asset)")
        }

    }

    @IBAction
    func speed() {
        let asset = AVAsset(url: self.soundFileURL!)
        exportSpeedAsset(asset, fileName: "trimmed.m4a")
    }

    func exportSpeedAsset(_ asset: AVAsset, fileName: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let trimmedSoundFileURL = documentsDirectory.appendingPathComponent(fileName)

        let filemanager = FileManager.default
        if filemanager.fileExists(atPath: trimmedSoundFileURL.absoluteString) {
            print("sound exists")
        }

        print("creating export session for \(asset)")

        if let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) {
            exporter.outputFileType = AVFileType.m4a
            exporter.outputURL = trimmedSoundFileURL


            //             AVAudioTimePitchAlgorithmVarispeed
            //             AVAudioTimePitchAlgorithmSpectral
            //             AVAudioTimePitchAlgorithmTimeDomain
            exporter.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.varispeed




            let duration = CMTimeGetSeconds(asset.duration)
            if duration < 5.0 {
                print("sound is not long enough")
                return
            }
            // e.g. the first 5 seconds
            //            let startTime = CMTimeMake(0, 1)
            //            let stopTime = CMTimeMake(5, 1)
            //            let exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
            //            exporter.timeRange = exportTimeRange

            // do it
            exporter.exportAsynchronously(completionHandler: {
                switch exporter.status {
                case  AVAssetExportSessionStatus.failed:
                    print("export failed \(String(describing: exporter.error))")
                case AVAssetExportSessionStatus.cancelled:
                    print("export cancelled \(String(describing: exporter.error))")
                default:
                    print("export complete")
                }
            })
        }
    }


}

// MARK: AVAudioRecorderDelegate
extension ViewController: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {

        print("\(#function)")

        print("finished recording \(flag)")
//        stopButton.isEnabled = false
//        playButton.isEnabled = true
//        recordButton.setTitle("Record", for: UIControlState())

        // iOS8 and later
        let alert = UIAlertController(title: "Recorder",
                                      message: "Finished Recording",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep", style: .default) {[unowned self] _ in
            print("keep was tapped")
            self.recorder = nil
        })
        alert.addAction(UIAlertAction(title: "Delete", style: .default) {[unowned self] _ in
            print("delete was tapped")
            self.recorder.deleteRecording()
        })

        self.present(alert, animated: true, completion: nil)
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                          error: Error?) {
        print("\(#function)")

        if let e = error {
            print("\(e.localizedDescription)")
        }
    }

}

// MARK: AVAudioPlayerDelegate
extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        recordButton.isEnabled = true
//        stopButton.isEnabled = false
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("\(#function)")

        if let e = error {
            print("\(e.localizedDescription)")
        }

    }
}
