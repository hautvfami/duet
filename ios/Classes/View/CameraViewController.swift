//
//  ViewController.swift
//  CustomCamera
//
//  Created by Taras Chernyshenko on 6/27/17.
//  Copyright © 2017 Taras Chernyshenko. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Photos

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet private weak var topView: UIView?
    @IBOutlet private weak var middleView: UIView?
    @IBOutlet private weak var innerView: UIView?
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var heightContraintVideo: NSLayoutConstraint!
    private var cameraManager: TCCoreCamera?
    private var fileUrls = [URL]()
    private var writer: AVAssetWriter?
    private var player: AVPlayer?

    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        if #available(iOS 13.0, *), directory != "" {
            let path = directory.appendingPathComponent("\(NSDate.now).mp4")
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    @IBAction private func recordingButton(_ sender: UIButton) {
        guard let cameraManager = self.cameraManager else { return }
        if cameraManager.isRecording {
            cameraManager.stopRecording()
            self.setupStartButton()
            player?.pause()
        } else {
            cameraManager.startRecording()
            self.setupStopButton()
            self.player?.play()
        }
    }

    private func initVideo() {
        guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
            debugPrint("video.m4v not found")
            return
        }
        //2. Create AVPlayer object
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        let size = asset.videoSize()
        let playerItem = AVPlayerItem(asset: asset)
        let ratio =  size.height/size.width
        self.player = AVPlayer(playerItem: playerItem)
        //3. Create AVPlayerLayer object
        let playerLayer = AVPlayerLayer(player: player)
        
        let withScreen = UIScreen.main.bounds.width
        heightContraintVideo.constant = withScreen * ratio

        playerLayer.frame = CGRect(x: 0, y: 0,
                                   width: withScreen,
                                   height: withScreen * ratio)
        //4. Add playerLayer to view's layer
        self.videoView.layer.addSublayer(playerLayer)
        
        let audioSession = AVAudioSession.sharedInstance()

        //Executed right before playing avqueueplayer media
        do {
            try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try audioSession.setActive(true)
        } catch {
            fatalError("Error Setting Up Audio Session")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        self.topView?.layer.borderWidth = 1.0
        self.topView?.layer.borderColor = UIColor.darkGray.cgColor
        self.topView?.layer.cornerRadius = 32
        self.middleView?.layer.borderWidth = 4.0
        self.middleView?.layer.borderColor = UIColor.white.cgColor
        self.middleView?.layer.cornerRadius = 32
        self.innerView?.layer.borderWidth = 32.0
        self.innerView?.layer.cornerRadius = 32
        self.setupStartButton()
        initVideo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cameraManager = TCCoreCamera(view: self.cameraView)
        self.cameraManager?.videoCompletion = { (fileURL) in
            print("finished writing to \(fileURL.absoluteString)")
            guard let path = Bundle.main.path(forResource: "manhdz", ofType:"mp4") else {
                debugPrint("video.m4v not found")
                return
            }
            let url = URL(fileURLWithPath: path)
            
            DispatchQueue.main.async {
                DPVideoMerger().gridMergeVideos(
                    withFileURLs: [url,fileURL],
                    videoResolution: CGSize(
                        width: self.view.frame.width,
                        height: self.view.frame.height - UIApplication.shared.statusBarFrame.height
                    ),
                    completion: {
                        (_ mergedVideoFile: URL?, _ error: Error?) -> Void in
                        if error != nil {
                            let errorMessage = "Could not merge videos: \(error?.localizedDescription ?? "error")"
                            let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
                            alert.addAction( UIAlertAction( title: "OK", style: .default, handler: { (a) in } ) )
                            
                            self.present(alert, animated: true) {() -> Void in }
                            return
                        }
                        
                        self.saveInPhotoLibrary(with: mergedVideoFile!)
                    }
                )
            }
        }
        
        self.cameraManager?.camereType = .video
    }

    private func setupStartButton() {
        self.topView?.backgroundColor = UIColor.clear
        self.middleView?.backgroundColor = UIColor.clear
        
        self.innerView?.layer.borderWidth = 32.0
        self.innerView?.layer.borderColor = UIColor.white.cgColor
        self.innerView?.layer.cornerRadius = 32
        self.innerView?.backgroundColor = UIColor.lightGray
        self.innerView?.alpha = 0.2
    }
    
    private func setupStopButton() {
        self.topView?.backgroundColor = UIColor.white
        self.middleView?.backgroundColor = UIColor.white
        
        self.innerView?.layer.borderColor = UIColor.red.cgColor
        self.innerView?.backgroundColor = UIColor.red
        self.innerView?.alpha = 1.0
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func saveInPhotoLibrary(with fileURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { saved, error in
            if saved {
                let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                print(error.debugDescription)
            }
        }
    }
}

extension AVAsset {
    func videoSize() -> CGSize {
        let tracks = self.tracks(withMediaType: AVMediaType.video)
        if (tracks.count > 0){
            let videoTrack = tracks[0]
            let size = videoTrack.naturalSize
            let txf = videoTrack.preferredTransform
            let realVidSize = size.applying(txf)
            print(videoTrack)
            print(txf)
            print(size)
            print(realVidSize)
            return realVidSize
        }
        return CGSize(width: 0, height: 0)
    }

}
extension URL {
    static var documents: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
