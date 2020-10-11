//
//  CameraManager.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

import Foundation
import AVFoundation

protocol CameraManagerDelegate: class {
    func cameraManager(_ videoOutput: AVCaptureOutput, _ capturedFrame: UIImage)
}

extension CameraManagerDelegate {
    func cameraManager(_ videoOutput: AVCaptureOutput, _ capturedFrame: UIImage) {
        // Optional
        _ = videoOutput
        _ = capturedFrame
    }
}

class CameraManager: NSObject {

    // MARK: - Attributes
    private var asset: AVAsset?
    private var player: AVPlayer?
    private var session: AVCaptureSession?
    private var playerItem: AVPlayerItem?
    private var playerLayer: AVPlayerLayer?

    private var captureSession = AVCaptureSession()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var audioOutput = AVCaptureAudioDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoConnection: AVCaptureConnection?
    private var audioConnection: AVCaptureConnection?
//    private var videoQueue = DispatchQueue(label: "VideoQueue")

    private var captureTimeInterval: TimeInterval?
    private var captureTimer: Timer?
    private var captureActive = false

    weak var delegate: CameraManagerDelegate?
    var statusBarOrientation: UIInterfaceOrientation? {
        get {
            guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
                #if DEBUG
                fatalError("Could not obtain UIInterfaceOrientation from a valid windowScene")
                #else
                return nil
                #endif
            }
            return orientation
        }
    }

    // MARK: - Methods
    override init() {
        super.init()
    }

    func prepareRecordLayer(inView: UIView) {
        self.setSession()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer?.frame = inView.bounds
        self.previewLayer?.videoGravity = .resizeAspect
        self.previewLayer?.needsDisplayOnBoundsChange = true
        if let safeLayer = self.previewLayer {
            inView.layer.insertSublayer(safeLayer, at: 0)
        }
    }

    private func setSession() {
        var isVideoAdded = false
        self.captureSession = AVCaptureSession()
        self.captureSession.sessionPreset = .hd1920x1080
        self.movieOutput = AVCaptureMovieFileOutput()
        if let camera = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }
                self.videoOutput = AVCaptureVideoDataOutput()
                self.videoOutput.setSampleBufferDelegate(self, queue: .global())
                self.videoOutput.alwaysDiscardsLateVideoFrames = false
                self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]
                if self.captureSession.canAddOutput(self.videoOutput) {
                    self.captureSession.addOutput(self.videoOutput)
                    self.videoConnection = self.videoOutput.connection(with: .video)
                    isVideoAdded = true
                }
            } catch {
                NSLog("\(String(describing: self)):::::\(#function)> Video Device Input create error, \(error.localizedDescription)")
            }
            if isVideoAdded, let audioDevice = AVCaptureDevice.default(for: .audio) {
                do {
                    let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                    if captureSession.canAddInput(audioInput) {
                        captureSession.addInput(audioInput)
                    }
                } catch {
                    NSLog("\(String(describing: self)):::::\(#function)> Audio Device Input create error, \(error.localizedDescription)")
                }
            }
        }
    }

    private func tempVideoURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return directory[0].appendingPathComponent("TempVideo" + ".mp4")
    }

    private func removeTempVideo() {
        if FileManager.default.fileExists(atPath: tempVideoURL().path) {
            do {
                try FileManager.default.removeItem(at: tempVideoURL())
            } catch {
                NSLog("\(String(describing: self)):::::\(#function)> Temp Video remove error, ", error.localizedDescription)
            }
        }
    }

    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        return orientation
    }

    private func lockOrientation(forMask: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = forMask
        }
    }

    private func rotateOrientation(forMask: UIInterfaceOrientationMask) {
        UIDevice.current.setValue(forMask.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

    func checkPermissions() {
        switch (AVCaptureDevice.authorizationStatus(for: .audio), AVCaptureDevice.authorizationStatus(for: .video)) {
        case (.authorized, .authorized):
            NSLog("\(String(describing: self)):::::\(#function)> Authorized All.")
        default:
            break
        }
    }

    func rotateCamera() {
        if let orientation = self.statusBarOrientation {
            switch orientation {
            case .portrait, .portraitUpsideDown:
                self.videoConnection?.videoOrientation = .portrait
            case .landscapeLeft:
                self.videoConnection?.videoOrientation = .landscapeLeft
            case .landscapeRight:
                self.videoConnection?.videoOrientation = .landscapeRight
            case .unknown:
                break
            @unknown default:
                NSLog("\(String(describing: self)):::::\(#function)> Unknown orientation")
            }
        }
    }

    func setCaptureTimer() {
        self.captureTimeInterval = TimeInterval(1)
        if let safeTime = self.captureTimeInterval {
            self.captureTimer = Timer.scheduledTimer(withTimeInterval: safeTime, repeats: true) { _ in
                self.captureActive = true
            }
        }
    }

    func stopCapturing() {
        self.captureTimer?.invalidate()
        self.captureTimeInterval = nil
        self.captureActive = false
    }

    func startRunning() {
        removeTempVideo()
        if !movieOutput.isRecording {
            self.lockOrientation(forMask: .portrait)
            self.rotateCamera()
            if (self.videoConnection?.isVideoOrientationSupported ?? false) {
                self.videoConnection?.videoOrientation = self.currentVideoOrientation()
            }
            if ((self.videoConnection?.isVideoStabilizationSupported) != nil) {
                self.videoConnection?.preferredVideoStabilizationMode = .auto
            }
            self.captureSession.addOutput(self.movieOutput)
            self.captureSession.startRunning()
            self.movieOutput.startRecording(to: self.tempVideoURL(), recordingDelegate: self)
            NSLog("\(String(describing: self)):::::\(#function)> Camera start recording")
        }
    }

    func stopRecording() {
        if movieOutput.isRecording {
            self.movieOutput.stopRecording()
            self.captureSession.stopRunning()
            self.captureSession.removeOutput(self.movieOutput)
            self.lockOrientation(forMask: [.portrait, .landscapeLeft])
            NSLog("\(String(describing: self)):::::\(#function)> Camera stop recording")
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if captureActive {
            captureActive = false
            let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let ciimage = CIImage(cvPixelBuffer: imageBuffer)
            let context:CIContext = CIContext.init(options: nil)
            let cgImage: CGImage = context.createCGImage(ciimage, from: ciimage.extent)!
            let image = UIImage(cgImage: cgImage)
            self.delegate?.cameraManager(output, image)
        }
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let err = error {
            NSLog("\(String(describing: self)):::::\(#function)> \(err.localizedDescription)")
        } else {
            NSLog("\(String(describing: self)):::::\(#function)> Record exported to %@", outputFileURL.path)
        }
    }
}
