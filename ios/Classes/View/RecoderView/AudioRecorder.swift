//
//  AudioRecorder.swift
//  duet
//
//  Created by HauTran on 04/05/2023.
//

import Foundation
import AVFAudio

class AudioRecorder: NSObject, AVAudioRecorderDelegate{
    
    
    let recordingSession = AVAudioSession.sharedInstance()
    var audioRecorder : AVAudioRecorder?
    var audioFilename : URL?
    
    override init(){
        super.init()
        do{
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        }catch let error {
            print("<< recordingSession \(error)")
        }
        self.audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
    }
    
    
    
    
    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            print("AUDIO RECORDER <<<<< \(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func finishRecording(_ completion: @escaping((URL) -> Void)) {
        audioRecorder?.stop()
        audioRecorder = nil
        completion(audioFilename!)
    }
    
    
}
