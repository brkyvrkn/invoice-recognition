//
//  CameraManager.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

import Foundation
import AVFoundation

public enum CameraMode {
    case record
    case realTime
}

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
    private var captureSession: AVCaptureSession
    private var movieOutput: AVCaptureMovieFileOutput
    private var videoOutput: AVCaptureVideoDataOutput
    private var audioOutput: AVCaptureAudioDataOutput
    private var imageOutput: AVCapturePhotoOutput
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var recordQueue = DispatchQueue(label: "VideoRecordQueue")

    // Parameters
    var mode: CameraMode = .record
    private var captureTimeInterval: TimeInterval?
    private var captureTimer: Timer?
    private let videoExtension = "mp4"
    private let imageExtension = "png"
    private var frameRate: Double = 1.0
    private var jpegCompressionQuality: CGFloat = 1.0

    private var captureRealTimeFlag = false

    // Accessors
    private var videosPath: URL {
        get {
            let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let videosPath = docsPath.appendingPathComponent("Videos", isDirectory: true)
            var isDir: ObjCBool = true
            if !FileManager.default.fileExists(atPath: videosPath.relativePath, isDirectory:&isDir) {
                // dir does not exist
                do {
                    try FileManager.default.createDirectory(atPath: videosPath.relativePath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("\(String(describing: type(of: self))):::::\(#function)> \(error.localizedDescription)")
                }
            }
            return videosPath
        }
    }
    private var imagesPath: URL {
        get {
            let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imagesPath = docsPath.appendingPathComponent("Images", isDirectory: true)
            var isDir: ObjCBool = true
            if !FileManager.default.fileExists(atPath: imagesPath.relativePath, isDirectory:&isDir) {
                // dir does not exist
                do {
                    try FileManager.default.createDirectory(atPath: imagesPath.relativePath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("\(String(describing: type(of: self))):::::\(#function)> \(error.localizedDescription)")
                }
            }
            return imagesPath
        }
    }

    // Util
    weak var delegate: CameraManagerDelegate?

    // MARK: - Methods
    override init() {
        self.captureSession = AVCaptureSession()
        self.movieOutput = AVCaptureMovieFileOutput()
        self.videoOutput = AVCaptureVideoDataOutput()
        self.audioOutput = AVCaptureAudioDataOutput()
        self.imageOutput = AVCapturePhotoOutput()

        super.init()
        NSLog("CAMERA_MANAGER:::::> Initialized")
    }

    deinit {
        self.stopRecording()
        self.stopCapturing()
        self.stopSession()
        self.clearSessionConnections()
        self.clearTempFiles()
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

    private func clearSessionConnections() {
        self.captureSession.connections.forEach {
            self.captureSession.removeConnection($0)
        }
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
                try camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.isSmoothAutoFocusEnabled = true
                camera.exposureMode = .continuousAutoExposure
                camera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
                camera.unlockForConfiguration()

                let input = try AVCaptureDeviceInput(device: camera)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.beginConfiguration()
                    self.captureSession.addInput(input)
                    self.captureSession.commitConfiguration()
                }

                if self.mode == .realTime {
                    self.videoOutput.alwaysDiscardsLateVideoFrames = true
                    self.videoOutput.videoSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]

                    if self.captureSession.canAddOutput(self.videoOutput) {
                        self.captureSession.beginConfiguration()
                        self.videoOutput.setSampleBufferDelegate(self, queue: self.recordQueue)
                        self.captureSession.addOutput(self.videoOutput)
                        self.captureSession.commitConfiguration()
                    }

                } else if self.mode == .record {
                    if self.captureSession.canAddOutput(self.movieOutput) {
                        self.captureSession.beginConfiguration()
                        self.captureSession.addOutput(self.movieOutput)
                        self.captureSession.commitConfiguration()
                    }
                    if self.captureSession.canAddOutput(self.imageOutput) {
                        self.captureSession.beginConfiguration()
                        self.captureSession.addOutput(self.imageOutput)
                        self.captureSession.commitConfiguration()
                    }
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
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            orientation = .landscapeRight
        case .landscapeRight:
            orientation = .landscapeLeft
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        default:
            // by default
            orientation = .portrait
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

    private func lockOrientation(basedVideo: AVCaptureVideoOrientation) {
        DispatchQueue.main.async {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                var lockedOrientation = UIInterfaceOrientationMask.portrait
                if basedVideo == .landscapeRight {
                    lockedOrientation = .landscapeRight
                } else if basedVideo == .landscapeLeft {
                    lockedOrientation = .landscapeLeft
                }
                delegate.orientationLock = lockedOrientation
            }
        }
    }

    private func rotateOrientation(forMask: UIInterfaceOrientationMask) {
        DispatchQueue.main.async {
            UIDevice.current.setValue(forMask.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }

    func getActualVideoSize() -> CGSize {
        // Portrait by default
        var actualSize = CGSize(width: 1080, height: 1920)
        if self.currentVideoOrientation() == .landscapeLeft || self.currentVideoOrientation() == .landscapeRight {
            actualSize = CGSize(width: 1920, height: 1080)
        }
        guard self.videoOutput.videoSettings != nil else { return actualSize }
        let tempHeight = self.videoOutput.videoSettings["Height"] as? CGFloat
        let tempWidth = self.videoOutput.videoSettings["Width"] as? CGFloat
        if let outputHeight = tempHeight {
            actualSize.height = outputHeight
        }
        if let outputWidth = tempWidth {
            actualSize.width = outputWidth
        }
        return actualSize
    }

    func convertCoordSpace(frame: CGRect, inView: UIView) -> CGRect {
        let actualSize = getActualVideoSize()
        let sX = inView.frame.width / actualSize.width
        let sY = inView.frame.height / actualSize.height
        let x1 = sX * frame.origin.x
        let y1 = sY * frame.origin.y
        let w1 = sX * frame.width
        let h1 = sY * frame.height
        return .init(x: x1, y: y1, width: w1, height: h1)
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
        let cameraOrientation = currentVideoOrientation()
        self.previewLayer?.frame = inView.bounds
        self.previewLayer?.connection?.videoOrientation = cameraOrientation
        if let videoConnection = self.videoOutput.connections.first {
            if videoConnection.isVideoOrientationSupported {
                videoConnection.videoOrientation = cameraOrientation
            }
        }
        if let movieConnection = self.movieOutput.connections.first {
            if movieConnection.isVideoOrientationSupported {
                movieConnection.videoOrientation = cameraOrientation
            }
        }
        if let imgConnection = self.imageOutput.connection(with: .video) {
            imgConnection.videoOrientation = cameraOrientation
        }
    }

    // MARK: - Documents
    public func clearTempFiles() {
        removeTempImage()
        removeTempVideo()
    }

    private func tempVideoURL() -> URL {
        let videoName = "TempVideo"
        let subPath = String(format: "%@.%@", videoName, videoExtension)
        return self.videosPath.appendingPathComponent(subPath)
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

    private func tempImageURL() -> URL {
        let imageName = "TempImage"
        let subPath = String(format: "%@.%@", imageName, imageExtension)
        return self.imagesPath.appendingPathComponent(subPath)
    }

    private func removeTempImage() {
        if FileManager.default.fileExists(atPath: tempImageURL().path) {
            do {
                try FileManager.default.removeItem(at: tempImageURL())
            } catch {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Temp Video remove error, ", error.localizedDescription)
            }
        }
    }

    /// Exporting last captured frame by AVCaptureOutput
    /// - Parameter frameImage: UIImage respresentation getting from Buffer
    private func exportFrame(frameImage: UIImage) {
        if FileManager.default.fileExists(atPath: tempImageURL().path) {
            do {
                try FileManager.default.removeItem(at: tempImageURL())
            } catch {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Temp Frame remove error, ", error.localizedDescription)
                return
            }
        }
        if let imgData = self.imageToData(frameImage) {
            do {
                try imgData.write(to: tempImageURL())
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Temp Frame exported to %@", tempImageURL().relativePath)
            } catch {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Temp Frame export error, ", error.localizedDescription)
            }
        } else {
            NSLog("\(String(describing: type(of: self))):::::\(#function)> Image could not convert to Data format")
        }
    }

    private func imageToData(_ img: UIImage?) -> Data? {
        guard let image = img else { return nil }
        var imgData: Data?
        if imageExtension.lowercased() == "png", let data = image.pngData() {
            imgData = data
        } else if ["jpeg", "jpg"].contains(imageExtension.lowercased()), let data = image.jpegData(compressionQuality: self.jpegCompressionQuality) {
            imgData = data
        }
        return imgData
    }

    /// Images will be exported, names are timestamp
    /// - Parameter list: UIImage container
    func saveImageListToDocuments(_ list: [UIImage], completion: () -> Void = { }) {
        guard !list.isEmpty else { return }
        let dateFolderName = DateFormatter.imageDateNameFormat.string(from: Date())
        let currentDatePath = imagesPath.appendingPathComponent(dateFolderName)
        var isDir: ObjCBool = true
        if !FileManager.default.fileExists(atPath: currentDatePath.relativePath, isDirectory:&isDir) {
            // dir does not exist
            do {
                try FileManager.default.createDirectory(atPath: currentDatePath.relativePath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> \(error.localizedDescription)")
            }
        }
        self.writeToDocuments(currentDatePath, list, completion: completion)
    }

    private func writeToDocuments(_ toUrl: URL, _ list: [UIImage], completion: () -> Void = { }) {
        for frameImage in list {
            if let data = imageToData(frameImage) {
                let imgName = String(format: "%.0f.%@", Date().timeIntervalSince1970, imageExtension)
                let filename = toUrl.appendingPathComponent(imgName)
                do {
                    try data.write(to: filename)
                } catch {
                    NSLog("\(String(describing: type(of: self))):::::\(#function)> Image data write error, message=\(error.localizedDescription)")
                }
            }
        }
        completion()
    }

    // MARK: - Events
    func setCaptureTimer() {
        self.captureTimeInterval = TimeInterval(1) * frameRate
        if let safeTime = self.captureTimeInterval {
            self.captureTimer = Timer.scheduledTimer(withTimeInterval: safeTime, repeats: true) { _ in
//                NSLog("\(String(describing: type(of: self))):::::\(#function)> Buffer capture activated")
                if self.mode == .record {
                    self.imageOutput.capturePhoto(
                        with: AVCapturePhotoSettings(format: [
                            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
                        ]),
                        delegate: self
                    )
                } else if self.mode == .realTime {
                    self.captureRealTimeFlag = true
                }
            }
        }
    }

    func stopCapturing() {
        if self.captureTimer != nil {
            self.captureTimer?.invalidate()
            self.captureTimer = nil
            self.captureTimeInterval = nil
        }
    }

    func startRecording() {
        guard self.mode == .record else { return }
        removeTempVideo()
        if !movieOutput.isRecording {
            self.lockOrientation(basedVideo: self.currentVideoOrientation())
            self.setCaptureTimer()
            recordQueue.async {
                self.movieOutput.startRecording(to: self.tempVideoURL(), recordingDelegate: self)
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Camera start recording")
            }
        }
    }

    func stopRecording() {
        if movieOutput.isRecording {
            self.lockOrientation(forMask: [.portrait, .landscapeLeft, .landscapeRight])
            self.stopCapturing()
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

// MARK: - Video Buffer
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard mode == .realTime else { return }
        if captureRealTimeFlag, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let cgCopy = imageBuffer.convertPixelBufferToCGImage() {
            let image = UIImage(cgImage: cgCopy)
            self.delegate?.cameraManager(output, image)
            captureRealTimeFlag = false
        } else {
            // too much console log due to late frames
//            NSLog("\(String(describing: type(of: self))):::::\(#function)> Image buffer did not recognized")
        }
    }
}

// MARK: - Photo Output
extension CameraManager: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard mode == .record else { return }
        if let imgData = photo.fileDataRepresentation(), let image = UIImage(data: imgData) {
            self.delegate?.cameraManager(output, image)
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
