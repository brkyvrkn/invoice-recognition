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

    private var captureSession: AVCaptureSession
    private var movieOutput: AVCaptureMovieFileOutput
    private var videoOutput: AVCaptureVideoDataOutput
    private var audioOutput: AVCaptureAudioDataOutput
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var recordQueue = DispatchQueue(label: "VideoRecordQueue")

    // Parameters
    private var captureTimeInterval: TimeInterval?
    private var captureTimer: Timer?
    private var captureActive = false
    private let videoExtension = "mp4"
    private var imageExportingActive = false
    private var frameRate: Double = 1.0

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
        self.captureSession = AVCaptureSession()
        self.movieOutput = AVCaptureMovieFileOutput()
        self.videoOutput = AVCaptureVideoDataOutput()
        self.audioOutput = AVCaptureAudioDataOutput()
        super.init()
        NSLog("CAMERA_MANAGER:::::> Initialized")
    }

    deinit {
        self.stopRecording()
        self.stopSession()
        self.stopCapturing()
        self.removeTempVideo()
    }

    func prepareRecordLayer(inView: UIView) {
        self.setSession()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer?.frame = inView.bounds
        self.previewLayer?.videoGravity = .resizeAspectFill
        self.previewLayer?.contentsGravity = .center
        self.previewLayer?.position = inView.center
        self.previewLayer?.needsDisplayOnBoundsChange = true
        if let safeLayer = self.previewLayer {
            inView.layer.insertSublayer(safeLayer, at: 0)
        }
        self.rotateCamera(inView: inView)
        startSession()
    }

    private func setSession() {
        self.captureSession.sessionPreset = .hd1920x1080

        setCamera()
        setAudio()
    }

    // MARK: - Camera
    private func setCamera() {
        if let camera = cameraDevice() {
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.beginConfiguration()
                    self.captureSession.addInput(input)
                    self.captureSession.commitConfiguration()
                }
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]

                try camera.lockForConfiguration()
                camera.focusMode = .autoFocus
                camera.isSmoothAutoFocusEnabled = true
                camera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
                camera.unlockForConfiguration()

                if self.captureSession.canAddOutput(self.videoOutput) {
                    self.captureSession.beginConfiguration()
                    self.videoOutput.setSampleBufferDelegate(self, queue: self.recordQueue)
                    self.captureSession.addOutput(self.videoOutput)
                    self.captureSession.commitConfiguration()
                }
                if self.captureSession.canAddOutput(self.movieOutput) {
                    self.captureSession.beginConfiguration()
                    // Should add without connection
                    // Due to protocol collision
                    self.captureSession.addOutputWithNoConnections(self.movieOutput)
                    self.captureSession.commitConfiguration()
                }
            } catch {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Video Device Input create error, \(error.localizedDescription)")
            }
        }
    }

    private func cameraDevice() -> AVCaptureDevice? {
        for dev in AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices {
            if dev.hasMediaType(.video), dev.position == .back {
                return dev
            }
        }
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    // MARK: - Audio
    private func setAudio() {
        if let audioDevice = audioDevice() {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if captureSession.canAddInput(audioInput) {
                    captureSession.beginConfiguration()
                    captureSession.addInput(audioInput)
                    captureSession.commitConfiguration()
                }
                if self.captureSession.canAddOutput(self.audioOutput) {
                    captureSession.beginConfiguration()
                    self.audioOutput.setSampleBufferDelegate(self, queue: self.recordQueue)
                    self.captureSession.addOutput(self.audioOutput)
                    captureSession.commitConfiguration()
                }
            } catch {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Audio Device Input create error, \(error.localizedDescription)")
            }
        }
    }

    private func audioDevice() -> AVCaptureDevice? {
        for dev in AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified).devices {
            if let safeDevice = dev as AVCaptureDevice?, safeDevice.hasMediaType(.audio) {
                return safeDevice
            }
        }
        return AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
    }

    // MARK: - Helpers
    private func tempVideoURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return directory[0].appendingPathComponent("TempVideo" + ".\(videoExtension)")
    }

    private func removeTempVideo() {
        if FileManager.default.fileExists(atPath: tempVideoURL().path) {
            do {
                try FileManager.default.removeItem(at: tempVideoURL())
            } catch {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Temp Video remove error, ", error.localizedDescription)
            }
        }
    }

    private func exportFrame(frameImage: UIImage) {
        guard imageExportingActive else { return }
        let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if FileManager.default.fileExists(atPath: docsPath.appendingPathComponent("Temp.png").path) {
            try? FileManager.default.removeItem(at: docsPath.appendingPathComponent("Temp.png"))
        }
        if let data = frameImage.pngData() {
            let filename = docsPath.appendingPathComponent("Temp.png")
            try? data.write(to: filename)
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
        DispatchQueue.main.async {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = forMask
            }
        }
    }

    private func rotateOrientation(forMask: UIInterfaceOrientationMask) {
        DispatchQueue.main.async {
            UIDevice.current.setValue(forMask.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }

    func checkPermissions() {
        switch (AVCaptureDevice.authorizationStatus(for: .audio), AVCaptureDevice.authorizationStatus(for: .video)) {
        case (.authorized, .authorized):
            NSLog("\(String(describing: type(of: self))):::::\(#function)> Authorized All.")
        default:
            break
        }
    }

    func rotateCamera(inView: UIView) {
        DispatchQueue.main.async {
            self.previewLayer?.frame = inView.bounds
            if let orientation = self.statusBarOrientation {
                switch orientation {
                case .portrait:
                    self.previewLayer?.connection?.videoOrientation = .portrait
                case .landscapeLeft:
                    self.previewLayer?.connection?.videoOrientation = .landscapeLeft
                case .landscapeRight:
                    self.previewLayer?.connection?.videoOrientation = .landscapeRight
                case .portraitUpsideDown:
                    self.previewLayer?.connection?.videoOrientation = .portraitUpsideDown
                case .unknown:
                    break
                @unknown default:
                    NSLog("\(String(describing: type(of: self))):::::\(#function)> Unknown orientation")
                }
            }
        }
    }

    // MARK: - Events
    func setCaptureTimer() {
        self.captureTimeInterval = TimeInterval(1) * frameRate
        if let safeTime = self.captureTimeInterval {
            self.captureTimer = Timer.scheduledTimer(withTimeInterval: safeTime, repeats: true) { _ in
//                NSLog("\(String(describing: type(of: self))):::::\(#function)> Buffer capture activated")
                self.captureActive = true
            }
        }
    }

    func stopCapturing() {
        if self.captureTimer != nil {
            self.captureTimer?.invalidate()
            self.captureTimer = nil
            self.captureTimeInterval = nil
        }
        self.captureActive = false
    }

    func startRecording() {
        removeTempVideo()
        if !movieOutput.isRecording {
            recordQueue.async {
                self.movieOutput.startRecording(to: self.tempVideoURL(), recordingDelegate: self)
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Camera start recording")
            }
        }
    }

    func stopRecording() {
        if movieOutput.isRecording {
            recordQueue.async {
                self.movieOutput.stopRecording()
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Camera stop recording")
            }
        }
    }

    func startSession() {
        if !captureSession.isRunning {
            recordQueue.async {
                self.captureSession.startRunning()
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Camera session started")
            }
        }
    }

    func stopSession() {
        if captureSession.isRunning {
            recordQueue.async {
                self.captureSession.stopRunning()
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Camera session stopped")
            }
        }
    }
}

// MARK: - Buffer
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard captureActive else { return }
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let cgCopy = imageBuffer.convertPixelBufferToCGImage() {
            captureActive = false
            let image = UIImage(cgImage: cgCopy)
            self.exportFrame(frameImage: image)
            self.delegate?.cameraManager(output, image)
        } else {
            NSLog("\(String(describing: type(of: self))):::::\(#function)> Image buffer did not recognized")
        }
    }
}

// MARK: - File Output
extension CameraManager: AVCaptureFileOutputRecordingDelegate {

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let err = error {
            NSLog("\(String(describing: type(of: self))):::::\(#function)> \(err.localizedDescription)")
        } else {
            NSLog("\(String(describing: type(of: self))):::::\(#function)> Record exported to %@", outputFileURL.path)
        }
    }
}
